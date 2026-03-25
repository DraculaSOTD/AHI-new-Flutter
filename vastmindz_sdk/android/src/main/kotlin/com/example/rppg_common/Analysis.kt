@file:OptIn(InternalCoroutinesApi::class)

package com.example.rppg_common


import android.app.Activity
import android.graphics.Color
import android.util.Log
import android.widget.Toast
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import androidx.lifecycle.Observer
import androidx.lifecycle.asLiveData
import androidx.lifecycle.lifecycleScope
import com.example.rppg_common.utils.PermissionManager
import com.example.rppg_common.utils.PermissionResult
import com.example.rppg_common.utils.SDKManager
import com.example.rppg_common.utils.StatusMessages
import com.rppg.library.common.BuildConfig
import com.rppg.library.common.RppgCoreManager
import com.rppg.library.common.camera.CameraConfig
import com.rppg.library.common.camera.FaceData
import com.rppg.library.common.camera.FpsCallback
import com.rppg.library.common.camera.RppgCameraManager
import com.rppg.library.common.camera.RppgCameraView
import com.rppg.library.common.camera.overlay.OverlayConfig
import com.rppg.library.common.socket.RppgTypedSocketManager
import com.rppg.library.common.socket.model.MeasurementStatus
import com.rppg.library.common.socket.model.SocketMessage
import com.rppg.library.common.socket.model.UnknownType
import com.rppg.library.core.RppgCore
import com.rppg.net.models.sendReport.AnalysisData
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.InternalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlin.coroutines.CoroutineContext


class Analysis {

    companion object {
        @Volatile
        private var instance: Analysis? = null

        fun getInstance(): Analysis {
            if (instance == null) {
                synchronized(this) {
                    if (instance == null) {
                        instance = Analysis()
                    }
                }
            }
            return instance!!
        }
    }

    private lateinit var activity: Activity
    private lateinit var lifecycle: Any

    private var eventSink: EventChannel.EventSink? = null
    private var diagnosticSocket: okhttp3.WebSocket? = null

    // Scan-specific coroutine scope for proper lifecycle management
    // This scope is created per scan and cancelled between scans
    // Prevents coroutine conflicts when running multiple consecutive scans
    private var scanScope: CoroutineScope? = null

    val sdkManagerInstance = SDKManager.getInstance()
    lateinit var analysisData: AnalysisData

    private lateinit var permissionManager: PermissionManager
    private lateinit var cameraManager: RppgCameraManager
    lateinit var rppgCameraView: RppgCameraView
    private lateinit var cameraConfig: CameraConfig

    private lateinit var socketManager: RppgTypedSocketManager
    private lateinit var coreManager: RppgCoreManager
    private lateinit var socketOpened: MutableStateFlow<Flow<SocketMessage>?>
    private lateinit var messagesFlow: Flow<SocketMessage>
    private lateinit var bpmEventMessage: LiveData<Pair<String, String>>
    private var pointer = 0L


    /// Initialize Analysis class
    fun initialization(activity: Activity, lifecycle: Any) {
        this.activity = activity
        this.lifecycle = lifecycle
        analysisData = AnalysisData()
        permissionManager = PermissionManager()
        rppgCameraView = RppgCameraView(activity, null)

        /// Initialize the Socket
        initializeSocket()

        /// Setup Observers
        setupObservers()

        /// Set initial state of SDKManager
        sdkManagerInstance.setSDKState(SDKManager.SDKState.INITIAL)
    }

    /// Initialize the Socket
    private fun initializeSocket() {
        socketManager = RppgTypedSocketManager()

        // Try to initialize native core manager, but continue if libraries are missing
        // Native libraries (librppg_core.so, librppg_bridge.so) are excluded to prevent
        // OpenCV version conflicts with AHI SDK. Face scanning will use server-side processing.
        try {
            coreManager = RppgCoreManager().apply {
                pointer = init(fps = 30, mode = RppgCore.CalculationMode.BGR.mode)
            }
            android.util.Log.d("AnalysisDebug", "Native RppgCore initialized successfully, pointer=$pointer")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("AnalysisDebug", "UnsatisfiedLinkError during RppgCore init: ${e.javaClass.simpleName} - ${e.message}", e)
        } catch (e: NoClassDefFoundError) {
            android.util.Log.e("AnalysisDebug", "NoClassDefFoundError during RppgCore init: ${e.javaClass.simpleName} - ${e.message}", e)
        } catch (e: Exception) {
            android.util.Log.e("AnalysisDebug", "Unexpected error during RppgCore init: ${e.javaClass.simpleName} - ${e.message}", e)
        }

        socketOpened = MutableStateFlow<Flow<SocketMessage>?>(null)
        messagesFlow = socketOpened.flatMapLatest { flow ->
            android.util.Log.d("AnalysisDebug", "flatMapLatest: received flow=${if (flow != null) "ACTIVE" else "NULL"}")
            (flow ?: emptyFlow())
                .onEach { msg ->
                    android.util.Log.d("AnalysisDebug", "Socket message received: ${msg.javaClass.simpleName}")
                }
                .onCompletion { cause ->
                    android.util.Log.d("AnalysisDebug", "Inner socket flow COMPLETED, cause=${cause?.message ?: "normal"}")
                }
        }
            .onEach { data ->
                analysisData.handleSocketResponse(data)
                activity.runOnUiThread(
                    Runnable {

                        try {
                            android.util.Log.d("AnalysisDebug", "Socket onEach: eventSink=${if (eventSink != null) "SET" else "NULL"}")
                            if (eventSink != null) {
                                val analysisJson = analysisData.getAnalysisData()
                                android.util.Log.d("AnalysisDebug", "eventSink.success() called, data length: ${analysisJson?.length ?: 0}")
                                val sink = eventSink  // capture local reference to avoid race condition
                                sink?.success(analysisJson)
                            } else {
                                android.util.Log.w("AnalysisDebug", "eventSink is NULL — data lost! Socket data arrived but no Flutter listener.")
                            }

                        } catch (ex: Exception) {
                            Log.d("Exception Socket" , "initializeSocket: " + ex.message)
                            /// if eventSink == null
                            ///  new lines add for testing...
                            val duration = Toast.LENGTH_SHORT

                            Toast.makeText(activity.applicationContext, ex.message, duration).show()
                            ///
                        }

                    }
                )

            }
            .flowOn(Dispatchers.Main)
            .catch { ex ->
                android.util.Log.e("AnalysisDebug", "Socket flow CRASHED: ${ex.javaClass.simpleName} - ${ex.message}", ex)
                /// tokenExpired
            }

        bpmEventMessage = messagesFlow
            .filter { it is UnknownType || it is MeasurementStatus }
            .map { data ->
                when (data) {

                    is MeasurementStatus -> StatusMessages.getMessage(data.statusCode)

                    else -> null
                }
            }
            .onEach {
            }
            .filterNotNull()
            .asLiveData(Dispatchers.IO)


    }

    /// Set event sink
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    /// Get current SDK state
    public fun getState(): String {
        when (sdkManagerInstance.getSDKState()) {
            SDKManager.SDKState.INITIAL -> {
                return "initial"
            }

            SDKManager.SDKState.PREPARED -> {
                return "prepared"
            }

            SDKManager.SDKState.VIDEO_STARTED -> {
                return "videoStarted"
            }

            SDKManager.SDKState.ANALYSIS_RUNNING -> {
                return "analysisRunning"
            }

            else ->
                return "default"
        }
    }

    /// Ask permission
    public fun setupPermission(activity: Activity, listner: PermissionResult) {
        permissionManager.checkVideoPermission(activity, callback = { isGranted ->
            listner.onPermissionCheck(isGranted)
        })
        sdkManagerInstance.setSDKState(SDKManager.SDKState.INITIAL)
    }

    /// Configure camera
    public fun configure(fps: Int, isFrontCamera: Boolean) {
        cameraConfig =
            CameraConfig(isDebug = BuildConfig.DEBUG, isFrontCamera = isFrontCamera, fps = fps)
        sdkManagerInstance.setSDKState(SDKManager.SDKState.PREPARED)
    }

    /// Start Camera
    public fun startVideo(activity: Activity) {
        android.util.Log.e("AnalysisDebug", "===== startVideo() CALLED =====")

        // CRITICAL FIX: Destroy old camera manager if it exists
        // This prevents lifecycle conflicts when restarting video for subsequent scans
        if (this::cameraManager.isInitialized) {
            try {
                cameraManager.destroy()
                android.util.Log.d("Analysis", "✅ Destroyed old camera manager before creating new one")
            } catch (e: Exception) {
                android.util.Log.e("Analysis", "⚠️ Error destroying old camera manager: ${e.message}", e)
            }
        }

        rppgCameraView.addFpsCallback(object : FpsCallback {
            override fun onMeasured(fps: Float) {
            }
        })
        // CRITICAL FIX: Create scan-specific coroutine scope instead of using Activity lifecycle scope
        // Cancel any previous scan scope to prevent coroutine conflicts
        scanScope?.cancel()
        android.util.Log.d("Analysis", "🔄 Creating fresh scan scope for new scan")
        scanScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
        android.util.Log.d("Analysis", "✅ Scan scope created successfully")

        cameraManager = RppgCameraManager.Builder(
            lifecycleOwner = activity as LifecycleOwner,
            camera = rppgCameraView,
            cameraConfig = cameraConfig
        ).buildFlow { dataFlow ->
            // Use scan-specific scope instead of activity lifecycle scope
            // This allows proper cancellation between consecutive scans
            scanScope!!.launch {
                android.util.Log.d("Analysis", "✅ Started dataFlow collection in scan scope")
                dataFlow.collect { data ->
                    val succeed = data.floatArray.isNotEmpty()
                    handleGaps(succeed)
                    if (succeed) sendFaceData(data)
                }
            }
        }

        sdkManagerInstance.setSDKState(SDKManager.SDKState.VIDEO_STARTED)

        cameraManager.setCameraStateListener {

        }
        cleanMesh()

    }

    /// Independent WebSocket test to diagnose server connectivity
    fun testWebSocketConnection(urlSocket: String) {
        val client = okhttp3.OkHttpClient.Builder()
            .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
            .build()
        val request = okhttp3.Request.Builder().url(urlSocket).build()

        client.newWebSocket(request, object : okhttp3.WebSocketListener() {
            override fun onOpen(webSocket: okhttp3.WebSocket, response: okhttp3.Response) {
                android.util.Log.d("WS_TEST", "CONNECTED! Response: ${response.code()} ${response.message()}")
                android.util.Log.d("WS_TEST", "Headers: ${response.headers()}")
                diagnosticSocket = webSocket
                // Send a test BGR payload
                val testPayload = """{"bgrSignal":[94.5,73.2,106.1,93.6,64.3,90.6,75.1,77.0,103.7],"timestamp":${System.currentTimeMillis()}}"""
                webSocket.send(testPayload)
                android.util.Log.d("WS_TEST", "Sent test payload: $testPayload")
            }
            override fun onMessage(webSocket: okhttp3.WebSocket, text: String) {
                android.util.Log.d("WS_TEST", "SERVER RESPONDED: $text")
            }
            override fun onClosing(webSocket: okhttp3.WebSocket, code: Int, reason: String) {
                android.util.Log.d("WS_TEST", "Server closing: $code $reason")
            }
            override fun onFailure(webSocket: okhttp3.WebSocket, t: Throwable, response: okhttp3.Response?) {
                android.util.Log.e("WS_TEST", "CONNECTION FAILED: ${t.message}")
                android.util.Log.e("WS_TEST", "Response: ${response?.code()} ${response?.message()}")
                t.printStackTrace()
            }
            override fun onClosed(webSocket: okhttp3.WebSocket, code: Int, reason: String) {
                android.util.Log.d("WS_TEST", "Connection closed: $code $reason")
            }
        })

        // Auto-close after 15 seconds
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            diagnosticSocket?.close(1000, "Diagnostic test complete")
            diagnosticSocket = null
            android.util.Log.d("WS_TEST", "Diagnostic socket auto-closed after 15s")
        }, 15000)
    }

    /// Start analysis
    fun startAnalysis(
        baseUrl: String,
        authToken: String,
        fps: String,
        age: String,
        sex: String,
        height: String,
        weight: String
    ) {
        val webSex = if (sex == "0") "male" else "female"
        var urlSocket =
            baseUrl + "?authToken=" +
                    authToken +
                    "&sex=" + webSex + "&age=" + age + "&weight=" + weight + "&height=" + height

        android.util.Log.d("AnalysisDebug", "startAnalysis() called, WebSocket URL: $urlSocket")

        // Run independent WebSocket diagnostic test in parallel
        testWebSocketConnection(urlSocket)

        this.analysisData.resetData()

        android.util.Log.d("AnalysisDebug", "Opening socket to: $urlSocket")
        var v = socketManager.startSocket(
            token = authToken,
            url = urlSocket
        )
        android.util.Log.d("AnalysisDebug", "startSocket() returned flow: ${v != null}")
        socketOpened.value = v
        android.util.Log.d("AnalysisDebug", "socketOpened.value set, flatMapLatest should fire")

        // CRITICAL FIX: Direct coroutine collector ensures the messagesFlow is actively collected
        // The previous approach relied solely on LiveData-based collection (bpmEventMessage.observe()),
        // which depends on the Activity lifecycle being in STARTED+ state. If the lifecycle
        // observer isn't active or the LiveData chain breaks, no messages would be collected,
        // causing the UI to freeze. This direct collector runs in the scan-specific scope
        // and guarantees socket messages are processed and forwarded to Flutter via eventSink.
        scanScope?.launch(Dispatchers.Main) {
            android.util.Log.d("AnalysisDebug", "Direct messagesFlow collector STARTED")
            try {
                messagesFlow.collect {
                    android.util.Log.d("AnalysisDebug", "Direct collector received: ${it.javaClass.simpleName}")
                    // The onEach operator upstream already handles eventSink.success(),
                    // so this collect just keeps the flow active.
                }
            } catch (e: Exception) {
                android.util.Log.e("AnalysisDebug", "Direct collector exception: ${e.javaClass.simpleName} - ${e.message}", e)
            }
            android.util.Log.d("AnalysisDebug", "Direct messagesFlow collector ENDED")
        }

        cameraManager.startRecording()

        sdkManagerInstance.setSDKState(SDKManager.SDKState.ANALYSIS_RUNNING)
    }

    /// Stop analysis
    public fun stopAnalysis() {
        cameraManager.stopRecording()
        socketManager.stopSocket()
        // Close diagnostic socket if still open
        diagnosticSocket?.close(1000, "Analysis stopped")
        diagnosticSocket = null
        // CRITICAL FIX: Clear socket flow and eventSink to prevent stale state
        socketOpened.value = null
        eventSink = null
        sdkManagerInstance.setSDKState(SDKManager.SDKState.VIDEO_STARTED)
    }

    /// Stop video and release camera resources
    /// CRITICAL: Cancels scan-specific coroutine scope to prevent conflicts on next scan
    public fun stopVideo() {
        android.util.Log.e("AnalysisDebug", "===== stopVideo() CALLED =====")
        android.util.Log.d("Analysis", "🛑 stopVideo() called - cancelling scan scope and destroying camera")

        // 1. Cancel scan-specific coroutine scope to stop dataFlow collection
        scanScope?.cancel()
        scanScope = null
        android.util.Log.d("Analysis", "✅ Scan scope cancelled and cleared")

        // 2. Stop and destroy camera manager
        if (this::cameraManager.isInitialized) {
            try {
                cameraManager.destroy()
                android.util.Log.d("Analysis", "✅ Camera manager destroyed")
            } catch (e: Exception) {
                android.util.Log.e("Analysis", "⚠️ Error destroying camera manager: ${e.message}", e)
            }
        } else {
            android.util.Log.d("Analysis", "ℹ️ Camera manager not initialized, skipping destroy")
        }

        // 3. Update SDK state
        sdkManagerInstance.setSDKState(SDKManager.SDKState.PREPARED)
        android.util.Log.d("Analysis", "✅ stopVideo() complete - SDK state set to PREPARED")
    }

    /// Clean mesh
    public fun cleanMesh() {
        rppgCameraView.setOverlayConfig(
            OverlayConfig(
                visibility = false,
                overlayAnalysingColor = Color.TRANSPARENT,
                overlayProcessingColor = Color.TRANSPARENT,
            )
        )
    }

    /// Add mesh with Color
    public fun meshColor() {
        rppgCameraView.setOverlayConfig(
            OverlayConfig(
                visibility = true,
                overlayAnalysingColor = Color.YELLOW,
                overlayProcessingColor = Color.WHITE,
            )
        )
    }

    /// Destroy camera manager
    public fun onDestroy() {
        cameraManager.destroy()
    }

    /// Reset singleton for new scan session
    /// CRITICAL: Recreates camera view and resets all state to allow consecutive scans
    public fun resetForNewScan(activity: Activity) {
        android.util.Log.e("AnalysisDebug", "===== resetForNewScan() CALLED =====")
        android.util.Log.d("Analysis", "🔄 Resetting Analysis singleton for new scan...")

        // 0. CRITICAL: Cancel active coroutines FIRST to prevent stale operations
        scanScope?.cancel()
        scanScope = null
        android.util.Log.d("Analysis", "✅ Scan scope cancelled and cleared")

        // 1. Stop and destroy camera manager if initialized
        if (this::cameraManager.isInitialized) {
            try {
                cameraManager.destroy()
                android.util.Log.d("Analysis", "✅ Camera manager destroyed")
            } catch (e: Exception) {
                android.util.Log.w("Analysis", "⚠️ Error destroying camera manager: ${e.message}")
            }
        }

        // 2. Remove old camera view from parent and recreate (CRITICAL FIX)
        try {
            val oldView = rppgCameraView
            val parent = oldView.parent as? android.view.ViewGroup
            if (parent != null) {
                parent.removeView(oldView)
                android.util.Log.d("Analysis", "✅ Old camera view removed from parent")
            }

            // Recreate camera view - this is the KEY fix for frozen camera
            rppgCameraView = RppgCameraView(activity, null)
            android.util.Log.d("Analysis", "✅ Camera view recreated")
        } catch (e: Exception) {
            android.util.Log.e("Analysis", "❌ Error recreating camera view: ${e.message}", e)
        }

        // 3. Reset socket/flow state
        socketOpened.value = null
        android.util.Log.d("Analysis", "✅ Socket/flow state cleared")

        // 4. Clear event sink reference
        eventSink = null
        android.util.Log.d("Analysis", "✅ Event sink cleared")

        // 5. Reset analysis data
        analysisData.resetData()
        android.util.Log.d("Analysis", "✅ Analysis data reset")

        // 6. Reset SDK state to INITIAL
        sdkManagerInstance.setSDKState(SDKManager.SDKState.INITIAL)
        android.util.Log.d("Analysis", "✅ SDK state reset to INITIAL")

        android.util.Log.d("Analysis", "✅ Analysis singleton reset complete - ready for new scan")
    }

    /// Setup observers
    private fun setupObservers() {
        bpmEventMessage.observe(activity as LifecycleOwner, Observer {

        })
    }

    /// Coroutine scope initialization
    private val job = SupervisorJob()
    private val coroutineExceptionHandler =
        CoroutineExceptionHandler { _, throwable ->
            throwable.printStackTrace()
            if (throwable !is CancellationException) handleException(throwable)
        }
    val scope: CoroutineScope = object : CoroutineScope {
        override val coroutineContext: CoroutineContext
            get() = Dispatchers.Main + job + coroutineExceptionHandler
    }

    /// Handle exceptions
    fun handleException(throwable: Throwable) {

    }

    /// Handle gaps in data
    private fun handleGaps(isSuccessCase: Boolean) {
        analysisData.isMovingWarning = !isSuccessCase
    }

    /// Send face data to the server
    fun sendFaceData(data: FaceData) {
        scope.launch(Dispatchers.IO) {
            with(data) {
                android.util.Log.d("AnalysisDebug", "sendFaceData called, coreManager initialized: ${this@Analysis::coreManager.isInitialized}, floatArray size: ${floatArray.size}")
                // Check if native core manager is available
                if (this@Analysis::coreManager.isInitialized) {
                    // Local BGR signal processing (requires native libraries)
                    val result = coreManager.track(width, height, byteArray, timestamp, floatArray)
                    socketManager.update(result, timestamp)
                } else {
                    // Native libraries not available - cannot process BGR signals
                    // Face detection works via ML Kit, but vital signs extraction requires
                    // native rPPG processing (librppg_core.so, librppg_bridge.so)
                    // These are excluded due to OpenCV version conflict with AHI SDK
                    android.util.Log.w("Analysis", "Cannot send face data: native rPPG libraries not available (OpenCV conflict with AHI SDK)")
                }
            }
        }
    }


}