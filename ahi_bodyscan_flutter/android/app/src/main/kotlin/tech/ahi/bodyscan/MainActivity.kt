package tech.ahi.bodyscan

import android.Manifest
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.activity.result.ActivityResultRegistry
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityOptionsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.CompletableFuture
import com.advancedhumanimaging.sdk.bodyscan.BodyScan
import com.advancedhumanimaging.sdk.bodyscan.common.BodyScanError
import com.advancedhumanimaging.sdk.common.IAHIDownloadProgress
import com.advancedhumanimaging.sdk.common.IAHIScan
import com.advancedhumanimaging.sdk.common.models.AHIResult
import com.advancedhumanimaging.sdk.multiscan.AHIMultiScan
import com.advancedhumanimaging.sdk.multiscan.MultiScanStatus

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ahi_sdk_turnkey"
    private var methodChannel: MethodChannel? = null

    // AHI SDK API Token
    private val AHI_API_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJoUDI1NmoxQW1rY0dVbXpuNStSaFc0cEJyOHNiN004bnRUQU5VSmk3UDF0RmJ4UUFMVVhvNEcxRWVnN20zQUd3NXJnVm5MdFV1M1VUaGV5UW5WbFpuOThpZWlmblFSR05kUHVpMFM5OUpmYjIva0NodHFGRTFSUjh4TEF6ZDBKaVBpUEQ1TEtDblNNZEVHUWhBUGZTbXBETHNBZWd3Q1JkQVVGR1lNRENFZlhIRGlqcVpWSUwzUmlnbGtTQk82Ty9xV1oyOUFyNUlTUVA0d3Y5MW9rKzU5eFFDV08wWVVQMEVQMnJXNFhicVg2dzBDSjNNMTFiQnN1V1daSDFMcGh1dmgyS2cwVjYycW5lUGIzZjQ3WDhzZ1NoWmNyU1hWTUFsVGQ0SC9HZjczZDRUbyt2b0huOThCbmFmOW55RmtiN29oWlVjb3hreGNhR0ExcmFVdEtES1hVRDdOYTlnSzR2dmpNVUk5N25JYXNyZmZ1MWVGdmpUZ1ZvTWNtWTVuN2tzN0E5c09reGhpNGlJMnpqN2JhVjhMS0ZiMitvdFFqa2F3a1VkTDRla3l0eGNCeGdPTmJ1d1d1Ukc5aVdCYWZHNm9KcDM4V2t4SFRhUDdFbmpxWFRSS0t3Nmo4bnloUVZ4c2E2R0ZGQlUzeHM2V3Q1UVQyNmhnOVFHb0dXakVreVBaa2NqczJUSEY3eDdCckhjMzg2Z1ZpZk5tOUpLM3FFV0pnOGIrdXJzSzdpczJaUmhPcG1WN1NBaCs2eHBaVjJiUHBVRzc5WXN6SkZpSzk1V0ozdWNlb21SNUZyMXZRbWR3dFIyWEphMlFPVk8vajlFeERPK3NEeHBxOGtnM2FMT0lxNmQ0Q3p5ZTZLZ2VwZFUvb1p2QjRtMHRSWmpZY3dJWXhta0Y2Qk1iOD0iLCJleHAiOjE4ODI2NzMzNTYsInZlciI6MywiYWlkIjoiYmUzNThlODIifQ.K_DywwafwPO2g4QxOlVz17NO_E1GklCw8X1woeiiKUnEdRYBtubSUSjT2nKh7RBna6RQEGSyS6ny4jAs7mYOElUc0Q4Qh61zj5_C3eaKwRC2mhkb6anMW69QslvCy_HbNec9tpCWHfWsR5DPBLyXfiLF96qHvwfgnAZoCO-sP0gkzbyRWBts-KBuGDmDobVIAHn4XUkj6ibLkDRCY069LpPVyFXIu6s-TF6kZ_349cwIHMUxuNUsB-D_qW6L01jrjUmDzDgfgPfny1fzB7qi4I0cl69nwGCZkusbk49quEegGmeK3TIJrQEFNvBTXukyP8AGUmUWHCijrdl8QM8Cjl2t0PBKbjqEP32V_2di3s73RtdigRftQ8gOv1JjwDAt0NQxMyWw2kiYxUyv8khJBJQ5RJILt9Vn_1G71PAa888CmpjCWO0DIwCq6oKCoDPks1Ucyb3mtd1aedl9oRwBs123swZZmeBQQGB3QY3-LhvV97ZzS3RTobeD-1oZljJIQefOJ6nlzcPuKR2aLnSp7HweqC4BmoaYlFLG_QY9VzZzKWVtZkYYajCR07DbLi0bAKcjAPe2Be8nGqTUyHn8yrYvf3LeUcXukCafW8qMHaetPIvsv1C0aumeXtmK7gdN_G35H6Jg8R27zcVZpkQmUCW5z2p41FvXlsA2QN3yUkA"

    // User authorization constants
    private val AHI_USER_ID = "test_user_${System.currentTimeMillis()}"
    private val AHI_USER_SALT = "AHI_BODYSCAN_APP_SALT"
    private val AHI_USER_CLAIMS = arrayOf("2024", "12", "01", "ahi")

    private var sdkInitialized = false
    private var userAuthorized = false
    private var resourcesDownloaded = false

    // Custom ActivityResultRegistry for handling AHI SDK scan results
    private val activityResultRegistry = object : ActivityResultRegistry() {
        override fun <I : Any?, O : Any?> onLaunch(
            requestCode: Int,
            contract: ActivityResultContract<I, O>,
            input: I,
            options: ActivityOptionsCompat?,
        ) {
            // Immediate result path
            val synchronousResult: ActivityResultContract.SynchronousResult<O>? = contract.getSynchronousResult(this@MainActivity, input)
            if (synchronousResult != null) {
                Handler(Looper.getMainLooper()).post { dispatchResult<O>(requestCode, synchronousResult.value) }
                return
            }

            // Start activity path
            val intent = contract.createIntent(this@MainActivity, input)
            var optionsBundle: Bundle? = null
            // If there are any extras, we should defensively set the classLoader
            if (intent.extras != null && intent.extras!!.classLoader == null) {
                intent.setExtrasClassLoader(this@MainActivity.classLoader)
            }
            if (intent.hasExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)) {
                optionsBundle = intent.getBundleExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)
                intent.removeExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)
            } else if (options != null) {
                optionsBundle = options.toBundle()
            }
            if (ActivityResultContracts.StartIntentSenderForResult.ACTION_INTENT_SENDER_REQUEST == intent.action) {
                val request = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        ActivityResultContracts.StartIntentSenderForResult.EXTRA_INTENT_SENDER_REQUEST,
                        androidx.activity.result.IntentSenderRequest::class.java
                    )
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<androidx.activity.result.IntentSenderRequest>(
                        ActivityResultContracts.StartIntentSenderForResult.EXTRA_INTENT_SENDER_REQUEST
                    )
                }
                try {
                    // startIntentSenderForResult path
                    ActivityCompat.startIntentSenderForResult(
                        this@MainActivity,
                        request!!.intentSender,
                        requestCode,
                        request.fillInIntent,
                        request.flagsMask,
                        request.flagsValues,
                        0,
                        optionsBundle
                    )
                } catch (e: IntentSender.SendIntentException) {
                    Handler(Looper.getMainLooper()).post {
                        dispatchResult(
                            requestCode,
                            RESULT_CANCELED,
                            Intent().setAction(ActivityResultContracts.StartIntentSenderForResult.ACTION_INTENT_SENDER_REQUEST)
                                .putExtra(ActivityResultContracts.StartIntentSenderForResult.EXTRA_SEND_INTENT_EXCEPTION, e)
                        )
                    }
                }
            } else {
                // startActivityForResult path
                ActivityCompat.startActivityForResult(this@MainActivity, intent, requestCode, optionsBundle)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // CRITICAL: Load OpenCV library before AHI SDK to resolve symbol conflicts
        // AHI SDK requires OpenCV 4.5.5, must load it explicitly
        try {
            System.loadLibrary("opencv_java4")
            android.util.Log.d("AHI_SDK", "OpenCV library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("AHI_SDK", "Failed to load OpenCV library", e)
        }

        // Initialize AHI SDK when activity is created
        initializeAHISDK()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startBodyScan" -> {
                    val options = call.arguments as? Map<String, Any>
                    startBodyScan(options, result)
                }
                // Face scan now handled by Vastmindz Flutter SDK (not native AHI SDK)
                "setupMultiScanSDK" -> {
                    // SDK is already initialized in onCreate
                    result.success(null)
                }
                "areAHIResourcesAvailable" -> {
                    // Return actual resource download state
                    result.success(resourcesDownloaded)
                }
                "getMultiScanStatus" -> {
                    checkSDKStatus(result)
                }
                "getUserAuthorizedState" -> {
                    result.success(userAuthorized)
                }
                "authorizeUser" -> {
                    // User authorization is already handled automatically in onCreate flow
                    // Return current authorization state
                    result.success(userAuthorized)
                }
                "checkAHIResourcesDownloadSize" -> {
                    // Check and return download size as List<Int> [progressBytes, totalBytes]
                    checkResourceDownloadSize(result)
                }
                "downloadAHIResources" -> {
                    // Trigger resource download if not already downloaded
                    // Return success status
                    if (resourcesDownloaded) {
                        result.success(true)
                    } else {
                        checkAndDownloadResources()
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializeAHISDK() {
        if (sdkInitialized) return

        try {
            val config: MutableMap<String, String> = HashMap()
            config["TOKEN"] = AHI_API_TOKEN

            // Initialize with BodyScan only (FaceScan uses Vastmindz SDK)
            val scans: Array<IAHIScan> = arrayOf(BodyScan())

            AHIMultiScan.setup(application, config, scans) { result ->
                when (result) {
                    is AHIResult.Success -> {
                        sdkInitialized = true
                        android.util.Log.d("AHI_SDK", "AHI MultiScan SDK initialized successfully")
                        // Authorize user after successful setup
                        authorizeUser()
                    }
                    else -> {
                        val error = result.error()
                        android.util.Log.e("AHI_SDK", "Failed to initialize AHI SDK")
                        android.util.Log.e("AHI_SDK", "Error details: $error")
                        error?.let { err ->
                            android.util.Log.e("AHI_SDK", "Error type: ${err::class.java.simpleName}")
                            android.util.Log.e("AHI_SDK", "Error toString: ${err.toString()}")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AHI_SDK", "Exception initializing AHI SDK", e)
        }
    }

    private fun authorizeUser() {
        if (userAuthorized) return

        // Launch authorization in background and wait for completion
        GlobalScope.launch(Dispatchers.IO) {
            try {
                val authSuccess = CompletableFuture<Boolean>().also { future ->
                    AHIMultiScan.userAuthorize(AHI_USER_ID, AHI_USER_SALT, AHI_USER_CLAIMS) { result ->
                        result.fold({
                            userAuthorized = true
                            android.util.Log.d("AHI_SDK", "User authorized successfully")
                            future.complete(true)
                        }, { error ->
                            android.util.Log.e("AHI_SDK", "User authorization failed: ${error.message}")
                            future.complete(false)
                        })
                    }
                }.get() // Wait for authorization to complete

                if (!authSuccess) {
                    android.util.Log.e("AHI_SDK", "User authorization returned false")
                } else {
                    // After successful authorization, check and download resources
                    android.util.Log.d("AHI_SDK", "Authorization complete, checking resources...")
                    checkAndDownloadResources()
                }
            } catch (e: Exception) {
                android.util.Log.e("AHI_SDK", "Exception during user authorization", e)
            }
        }
    }

    private fun checkDownloadSize() {
        AHIMultiScan.totalEstimatedDownloadSizeInBytes {
            it.fold({ downloadState ->
                val mB = 1024.0 * 1024.0
                val progress = downloadState.progressBytes / mB
                val total = downloadState.totalBytes / mB
                android.util.Log.d("AHI_SDK", "Download progress: %.2f MB / %.2f MB".format(progress, total))

                if (progress == total) {
                    resourcesDownloaded = true
                    android.util.Log.d("AHI_SDK", "Resource download completed")
                }
            }, { error ->
                android.util.Log.e("AHI_SDK", "Failed to get download size: ${error.message}")
            })
        }
    }

    private fun checkResourceDownloadSize(result: MethodChannel.Result) {
        AHIMultiScan.totalEstimatedDownloadSizeInBytes {
            it.fold({ downloadState ->
                // Return as List<Long> with [progressBytes, totalBytes]
                val sizeList = listOf(downloadState.progressBytes, downloadState.totalBytes)
                result.success(sizeList)
            }, { error ->
                android.util.Log.e("AHI_SDK", "Failed to get download size: ${error.message}")
                // Return empty list on error
                result.success(listOf(0L, 0L))
            })
        }
    }

    private fun checkAndDownloadResources() {
        GlobalScope.launch(Dispatchers.IO) {
            try {
                AHIMultiScan.areResourcesDownloaded { ahiResult ->
                    ahiResult.fold({ isDownloaded ->
                        if (isDownloaded) {
                            resourcesDownloaded = true
                            android.util.Log.d("AHI_SDK", "Resources already downloaded")
                        } else {
                            android.util.Log.d("AHI_SDK", "Resources not downloaded, starting download...")

                            // Set up download progress delegate
                            AHIMultiScan.delegateDownloadProgress = object : IAHIDownloadProgress {
                                override fun downloadProgressReport(status: AHIResult<Unit>) {
                                    if (status.isFailure) {
                                        android.util.Log.e("AHI_SDK", "Download progress error: ${status.error()}")
                                    } else {
                                        checkDownloadSize()
                                    }
                                }
                            }

                            // Start download
                            android.util.Log.d("AHI_SDK", "Starting resource download (priority 3)...")
                            AHIMultiScan.downloadResourcesInForeground(3)
                        }
                    }, { error ->
                        android.util.Log.e("AHI_SDK", "Failed to check resources: ${error.message}")
                    })
                }
            } catch (e: Exception) {
                android.util.Log.e("AHI_SDK", "Exception checking/downloading resources", e)
            }
        }
    }

    private fun checkSDKStatus(result: MethodChannel.Result) {
        AHIMultiScan.getStatus { status ->
            when (status) {
                MultiScanStatus.DISCONNECTED -> result.success("AHIMultiScanStatusDisconnected")
                MultiScanStatus.NOT_SETUP -> result.success("AHIMultiScanStatusNotSetup")
                MultiScanStatus.READY -> result.success("AHIMultiScanStatusReady")
            }
        }
    }

    private fun startBodyScan(options: Map<String, Any>?, result: MethodChannel.Result) {
        if (options == null) {
            result.error("INVALID_ARGS", "Options cannot be null", null)
            return
        }

        if (!sdkInitialized) {
            result.error("SDK_NOT_INITIALIZED", "AHI SDK is not initialized", null)
            return
        }

        // Critical check: Ensure user is authorized before attempting scan
        if (!userAuthorized) {
            result.error("USER_NOT_AUTHORIZED", "User authorization is pending or failed. Please wait and try again.", null)
            android.util.Log.e("AHI_SDK", "Scan attempted before user authorization completed")
            return
        }

        // Critical check: Ensure resources are downloaded before attempting scan
        if (!resourcesDownloaded) {
            result.error("RESOURCES_NOT_DOWNLOADED", "ML model resources are still downloading. Please wait and try again.", null)
            android.util.Log.e("AHI_SDK", "Scan attempted before resources download completed")
            return
        }

        // Note: Camera permission is handled by the AHI SDK and Flutter permission_handler
        // The SDK will show its own permission dialog if needed

        try {
            // Extract and validate user data from options
            val userInput = getBodyScanUserInput(options)
            if (userInput == null) {
                result.error("INVALID_INPUT", "Missing required body scan input (gender, height, weight)", null)
                return
            }

            // Launch AHI Body Scan using the SDK
            AHIMultiScan.initiateScan("body", userInput, activityResultRegistry) { future ->
                GlobalScope.launch(Dispatchers.Main) {
                    try {
                        // Wait for scan to complete
                        val response = withContext(Dispatchers.IO) { future.get() }

                        when (response) {
                            is AHIResult.Success -> {
                                // Convert result to mutable map for Flutter
                                val bodyScanResult = response.value as? Map<String, Any> ?: mapOf()
                                android.util.Log.d("AHI_SDK", "Body scan successful: $bodyScanResult")
                                result.success(bodyScanResult)
                            }
                            else -> {
                                // Handle errors
                                if (response.error() == BodyScanError.BODY_SCAN_CANCELED) {
                                    result.error("USER_CANCELLED", "User cancelled the body scan", null)
                                } else {
                                    val errorMessage = response.error().toString()
                                    android.util.Log.e("AHI_SDK", "Body scan error: $errorMessage")
                                    result.error("SCAN_ERROR", errorMessage, null)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("AHI_SDK", "Exception during body scan", e)
                        result.error("SCAN_EXCEPTION", e.message ?: "Unknown error", e.stackTraceToString())
                    }
                }
            }

        } catch (e: Exception) {
            android.util.Log.e("AHI_SDK", "Exception starting body scan", e)
            result.error("BODY_SCAN_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun getBodyScanUserInput(arguments: Map<String, Any>): HashMap<String, Any>? {
        try {
            val enumEntSex = arguments["enum_ent_sex"] as? String ?: return null
            val cmEntHeight = arguments["cm_ent_height"].toString().toDoubleOrNull() ?: return null
            val kgEntWeight = arguments["kg_ent_weight"].toString().toDoubleOrNull() ?: return null

            return hashMapOf(
                "enum_ent_sex" to enumEntSex,
                "cm_ent_height" to cmEntHeight,
                "kg_ent_weight" to kgEntWeight
            )
        } catch (e: Exception) {
            android.util.Log.e("AHI_SDK", "Error parsing body scan input", e)
            return null
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!activityResultRegistry.dispatchResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
