package tech.ahi.sdk.ahi_bodyscan_flutter

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.result.ActivityResultRegistry
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityOptionsCompat
import com.advancedhumanimaging.sdk.bodyscan.BodyScan
import com.advancedhumanimaging.sdk.bodyscan.common.BodyScanError
import com.advancedhumanimaging.sdk.common.IAHIPersistence
import com.advancedhumanimaging.sdk.common.IAHIScan
import com.advancedhumanimaging.sdk.common.models.AHIResult
import com.advancedhumanimaging.sdk.facescan.AHIFaceScanError
import com.advancedhumanimaging.sdk.facescan.FaceScan
import com.advancedhumanimaging.sdk.fingerscan.AHIFingerScanError
import com.advancedhumanimaging.sdk.fingerscan.FingerScan
import com.advancedhumanimaging.sdk.multiscan.AHIMultiScan
import com.advancedhumanimaging.sdk.multiscan.MultiScanStatus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/** AhiSdkTurnkeyPlugin */
class AhiSdkTurnkeyPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ahi_sdk_turnkey")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (AHIMultiScanMethod.values().find { it.methodName == call.method }) {
            AHIMultiScanMethod.SETUP_MULTISCAN_SDK -> {
                setupMultiScanSDK(
                    token = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.AUTHORIZE_USER -> {
                authorizeUser(
                    arguments = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.ARE_AHI_RESOURCES_AVAILABLE -> {
                areAHIResourcesAvailable(
                    result = result
                )
            }

            AHIMultiScanMethod.DOWNLOAD_AHI_RESOURCES -> {
                downloadAHIResources(
                    result = result
                )
            }

            AHIMultiScanMethod.CHECK_AHI_RESOURCES_DOWNLOAD_SIZE -> {
                checkAHIResourcesDownloadSize(
                    result = result
                )
            }

            AHIMultiScanMethod.REQUEST_CAMERA_PERMISSIONS -> {
                requestCameraPermissions(result = result)
            }

            AHIMultiScanMethod.START_FACESCAN -> {
                startFaceScan(
                    arguments = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.START_FINGERSCAN -> {
                startFingerScan(
                    arguments = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.START_BODYSCAN -> {
                startBodyScan(
                    arguments = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.GET_BODYSCAN_EXTRAS -> {
                getBodyScanExtras(
                    arguments = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.GET_MULTISCAN_STATUS -> {
                getMultiScanStatus(result = result)
            }

            AHIMultiScanMethod.OVERRIDE_FINGER_FEATURES -> {
                overrideFeatures(scan = "finger", arguments = call.arguments)
            }

            AHIMultiScanMethod.OVERRIDE_FACE_FEATURES -> {
                overrideFeatures(scan = "face", arguments = call.arguments)
            }

            AHIMultiScanMethod.OVERRIDE_BODY_FEATURES -> {
                overrideFeatures(scan = "body", arguments = call.arguments)
            }

            AHIMultiScanMethod.OVERRIDE_MULTI_FEATURES -> {
                overrideFeatures(scan = "multiscan", arguments = call.arguments)
            }

            AHIMultiScanMethod.GET_MULTISCAN_DETAILS -> {
                getMultiScanDetails(result = result)
            }

            AHIMultiScanMethod.GET_USER_AUTHORIZED_STATE -> {
                getUserAuthorizedState(
                    userId = call.arguments, result = result
                )
            }

            AHIMultiScanMethod.DEAUTHORIZE_USER -> {
                deauthorizeUser(result = result)
            }

            AHIMultiScanMethod.RELEASE_MULTISCAN_SDK -> {
                releaseMultiScanSDK(result = result)
            }

            AHIMultiScanMethod.SET_MULTISCAN_PERSISTENCE_DELEGATE -> {
                setMultiScanPersistenceDelegate(call.arguments, result = result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private val activityResultRegistry = object : ActivityResultRegistry() {
        override fun <I : Any?, O : Any?> onLaunch(
            requestCode: Int,
            contract: ActivityResultContract<I, O>,
            input: I,
            options: ActivityOptionsCompat?,
        ) {
            activity?.let { mActivity ->
                // Immediate result path
                val synchronousResult: ActivityResultContract.SynchronousResult<O>? = contract.getSynchronousResult(mActivity, input)
                if (synchronousResult != null) {
                    Handler(Looper.getMainLooper()).post { dispatchResult<O>(requestCode, synchronousResult.value) }
                    return
                }

                // Start activity path
                val intent = contract.createIntent(mActivity, input)
                var optionsBundle: Bundle? = null
                // If there are any extras, we should defensively set the classLoader
                if (intent.extras != null && intent.extras!!.classLoader == null) {
                    intent.setExtrasClassLoader(mActivity.classLoader)
                }
                if (intent.hasExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)) {
                    optionsBundle = intent.getBundleExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)
                    intent.removeExtra(ActivityResultContracts.StartActivityForResult.EXTRA_ACTIVITY_OPTIONS_BUNDLE)
                } else if (options != null) {
                    optionsBundle = options.toBundle()
                }
                if (ActivityResultContracts.StartIntentSenderForResult.ACTION_INTENT_SENDER_REQUEST == intent.action) {
                    val request = if (VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(
                            ActivityResultContracts.StartIntentSenderForResult.EXTRA_INTENT_SENDER_REQUEST, IntentSenderRequest::class.java
                        )
                    } else {
                        intent.getParcelableExtra(ActivityResultContracts.StartIntentSenderForResult.EXTRA_INTENT_SENDER_REQUEST)
                    }
                    try {
                        // startIntentSenderForResult path
                        ActivityCompat.startIntentSenderForResult(
                            mActivity,
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
                                FlutterActivity.RESULT_CANCELED,
                                Intent().setAction(ActivityResultContracts.StartIntentSenderForResult.ACTION_INTENT_SENDER_REQUEST)
                                    .putExtra(ActivityResultContracts.StartIntentSenderForResult.EXTRA_SEND_INTENT_EXCEPTION, e)
                            )
                        }
                    }
                } else {
                    // startActivityForResult path
                    ActivityCompat.startActivityForResult(mActivity, intent, requestCode, optionsBundle)
                }
            }
        }

    }

    /**
     *  Setup the MultiScan SDK
     *  This must happen before requesting a scan.
     *  We recommend doing this on successful load of your application.
     */
    private fun setupMultiScanSDK(token: Any?, result: Result) {
        activity?.let { mActivity ->
            if (token == null || token !is String) {
                result.error("-1", "Missing multi scan token", null)
                return
            }
            val config: MutableMap<String, String> = HashMap()
            config["TOKEN"] = token
            val scans: Array<IAHIScan> = arrayOf(FaceScan(), FingerScan(), BodyScan())
            AHIMultiScan.setup(mActivity.application, config, scans, completionBlock = {
                it.fold({
                    result.success(null)
                }, { error ->
                    result.error(error.error.code().toString(), error.message, null)
                })
            })
        }
    }

    /**
     * Check if MultiScan is on or offline.
     * */
    private fun getMultiScanStatus(result: MethodChannel.Result) {
        AHIMultiScan.getStatus {
            when (it) {
                MultiScanStatus.DISCONNECTED -> result.success("AHIMultiScanStatusDisconnected")
                MultiScanStatus.NOT_SETUP -> result.success("AHIMultiScanStatusNotSetup")
                MultiScanStatus.READY -> result.success("AHIMultiScanStatusReady")
            }
        }
    }

    private fun overrideFeatures(scan: String, arguments: Any?) {
        if (arguments == null || arguments !is Map<*, *>) {
            return
        }
        val args = arguments as Map<String, Any>
        if (scan.isNotEmpty() && listOf("finger", "body", "face", "multiscan").contains(scan)) {
            val features = mutableMapOf<String, Any>()
            if (!args.contains("multiscan") && (scan != "multiscan")) {
                features[scan] = args
                // default to disable multiscan features for new output schema
                features["multiscan"] = mapOf("23.8_filterPostfix" to mapOf("enabled" to false))
            } else {
                features[scan] = args
            }
            AHIMultiScan.setFeatureOverrides(features)
        }
    }

    /**
     * Check your AHI MultiScan organisation details.
     * */
    private fun getMultiScanDetails(result: MethodChannel.Result) {
        AHIMultiScan.getDetails {
            it.fold({ details ->
                result.success(details)
            }, { error ->
                result.error(error.error.code().toString(), error.error.toString(), it)
            })
        }
    }

    /**
     * Release the MultiScan SDK session.
     *
     * If you  use this, you will need to call setupSDK again.
     * */
    private fun releaseMultiScanSDK(result: MethodChannel.Result) {
        AHIMultiScan.releaseSdk {
            it.fold({
                result.success(null)
            }, { error ->
                result.error(error.error.code().toString(), error.message, null)
            })
        }
    }

    /**
     *  Once successfully setup, you should authorize your user with our service.
     *  With your signed in user, you can authorize them to use the AHI service.
     * */
    private fun authorizeUser(
        arguments: Any?,
        result: Result,
    ) {
        if (arguments == null || arguments !is Map<*, *>) {
            result.error("-2", "Missing user authorization details.", null)
            return
        }
        if (!arguments.contains("user_id") || !arguments.contains("salt") || !arguments.contains("claims")) {
            result.error("-2", "Missing user authorization details.", null)
            return
        }
        val userID = arguments["user_id"] as? String ?: run {
            result.error("-2", "Missing user authorization details.", null)
            return
        }
        val salt = arguments["salt"] as? String ?: run {
            result.error("-2", "Missing user authorization details.", null)
            return
        }
        val claims = arguments["claims"] as? ArrayList<String> ?: run {
            val claimsArgs = arguments["claims"]!!
            val typeOfClaimsArgs = claimsArgs.javaClass
            result.error(
                "-2", "Missing user authorization details.", "Claims is not correct format: $claimsArgs and $typeOfClaimsArgs"
            )
            return
        }
        val claimsArray: Array<String> = claims.toTypedArray()

        AHIMultiScan.userAuthorize(userID, salt, claimsArray, completionBlock = {
            it.fold({ result.success(null) }, { result.error(it.error.code().toString(), it.message, null) })
        })
    }

    /** Check if the user is authorized to use the MuiltScan service. */
    private fun getUserAuthorizedState(userId: Any?, result: MethodChannel.Result) {
        val userID = userId as? String
        if (userID.isNullOrEmpty()) {
            result.error("-9", "Missing user ID", null)
            return
        }
        AHIMultiScan.userIsAuthorized {
            it.fold({
                result.success(null)
            }, { error ->
                result.error(error.error.code().toString(), error.error.toString(), it)
            })
        }
    }

    /**
     * Deuauthorize the user.
     * */
    private fun deauthorizeUser(result: MethodChannel.Result) {
        AHIMultiScan.userDeauthorize {
            it.fold({
                result.success(null)
            }, { error ->
                result.error(error.error.code().toString(), error.error.toString(), it)
            })
        }
    }

    /** Check if the AHI resources are downloaded.
     *
     * We have remote resources that exceed 100MB that enable our scans to work.
     * You are required to download them in order to obtain a body scan.
     *
     * This function checks if they are already downloaded and available for use.
     * */
    private fun areAHIResourcesAvailable(result: Result) {
        AHIMultiScan.areResourcesDownloaded {
            it.fold({ areAvailable ->
                result.success(areAvailable)
            }, { error ->
                Log.e("AhiSdkTurnkeyPlugin", "AHI INFO: Resources are not downloaded, error: ${error.error}")
                result.success(false)
            })
        }
    }

    /**
     *  Download scan resources.
     *  We recommend only calling this function once per session to prevent duplicate background resource calls.
     */
    private fun downloadAHIResources(result: Result) {
        AHIMultiScan.downloadResourcesInForeground(3)
        result.success(true)
    }

    /** Check the size of the AHI resources that require downloading. */
    private fun checkAHIResourcesDownloadSize(result: Result) {
        AHIMultiScan.totalEstimatedDownloadSizeInBytes {
            it.fold({ size ->
                result.success(listOf(size.progressBytes, size.totalBytes))
            }, { error ->
                result.error(error.error.toString(), error.message, null)
            })
        }
    }

    private fun requestCameraPermissions(result: Result) {
        throw Error("Code not yet implemented")
    }

    private fun getFingerScanUserInput(arguments: Any?): HashMap<String, Any>? {
        if (arguments == null || arguments !is Map<*, *>) {
            return null
        }
        val scanLength = arguments["sec_ent_scanLength"] as? Int ?: return null
        val instruction1 = arguments["str_ent_instruction1"] as? String ?: return null
        val instruction2 = arguments["str_ent_instruction2"] as? String ?: return null
        val miscData = arguments["miscData"] as? HashMap<String, Any> ?: mapOf()
        return hashMapOf(
            "sec_ent_scanLength" to scanLength, "str_ent_instruction1" to instruction1, "str_ent_instruction2" to instruction2, "miscData" to miscData
        )
    }

    private fun startFingerScan(
        arguments: Any?,
        result: Result,
    ) {
        val userInput = getFingerScanUserInput(arguments)
        if (userInput == null) {
            result.error("-3", "Missing user finger scan input details", null)
            return
        }
        AHIMultiScan.initiateScan("finger", userInput, activityResultRegistry, completionBlock = {
            GlobalScope.launch(Dispatchers.Main) {
                if (!it.isDone) {
                    // TODO: Waiting of results.
                }
                val response = withContext(Dispatchers.IO) { it.get() }
                when (response) {
                    is AHIResult.Success -> {
                        val value = response.value.toMutableMap()
                        value["listPPGData"] = getPpgData(value)
                        value.remove("str_raw_ppgFilePath")
                        result.success(value)
                    }

                    else -> {
                        if (response.error() == AHIFingerScanError.FINGER_SCAN_CANCELLED) {
                            result.error("USER_CANCELLED", "User cancelled", null)
                        } else {
                            result.error(response?.error()?.code().toString(), response.error().toString(), null)
                        }
                    }
                }
            }
        })
    }

    private fun getPpgData(results: Map<String, Any>): List<Double> {
        return try {
            val ppgFilePath = results["string_raw_ppgFilePath"] as String
            val ppgFile = File(ppgFilePath)
            if (ppgFile.exists()) {
                val ppgData = ppgFile.readText()
                ppgData.replace("[", "").replace("]", "").split(",").map { it.toDouble() }
            } else {
                listOf()
            }
        } catch (e: Exception) {
            listOf()
        }
    }

    private fun startFaceScan(
        arguments: Any?,
        result: Result,
    ) {
        val userInput = getFaceScanUserInput(arguments)
        if (userInput == null) {
            result.error("-3", "Missing user face scan input details", null)
            return
        }
        AHIMultiScan.initiateScan("face", userInput, activityResultRegistry, completionBlock = {
            GlobalScope.launch(Dispatchers.Main) {
                if (!it.isDone) {
                    // TODO: Waiting of results.
                }
                val response = withContext(Dispatchers.IO) { it.get() }
                when (response) {
                    is AHIResult.Success -> {
                        result.success(response.value)
                    }

                    else -> {
                        if (response.error() == AHIFaceScanError.FACE_SCAN_CANCELLED) {
                            result.error("USER_CANCELLED", "User cancelled", null)
                        } else {
                            result.error(response?.error()?.code().toString(), response.error().toString(), null)
                        }
                    }
                }
            }
        })
    }

    private fun getFaceScanUserInput(arguments: Any?): HashMap<String, Any>? {
        if (arguments == null || arguments !is Map<*, *>) {
            return null
        }
        // FaceScan required inputs
        val enumEntSex = arguments["enum_ent_sex"] as? String ?: return null
        val cmEntHeight = arguments["cm_ent_height"].toString().toDoubleOrNull() ?: return null
        val kgEntWeight = arguments["kg_ent_weight"].toString().toDoubleOrNull() ?: return null
        val yrEntAge = arguments["yr_ent_age"] as? Int ?: return null
        val boolEntSmoker = arguments["bool_ent_smoker"] as? Boolean ?: return null
        val boolEntHypertension = arguments["bool_ent_hypertension"] as? Boolean ?: return null
        val boolEntBloodpressuremedication = arguments["bool_ent_bloodPressureMedication"] as? Boolean ?: return null
        val enumEntDiabetic = arguments["enum_ent_diabetic"] as? String ?: return null

        // FaceScan optional inputs
        val sec_ent_scanLength = arguments["sec_ent_scanLength"].toString().toIntOrNull()
        val bool_ent_default_constraints = arguments["bool_ent_default_constraints"].toString().toBooleanStrictOrNull()
        val bool_ent_lighting_quality_constraints = arguments["bool_ent_lighting_quality_constraints"].toString().toBooleanStrictOrNull()
        val map = mutableMapOf(
            "enum_ent_sex" to enumEntSex,
            "cm_ent_height" to cmEntHeight,
            "kg_ent_weight" to kgEntWeight,
            "yr_ent_age" to yrEntAge,
            "bool_ent_smoker" to boolEntSmoker,
            "bool_ent_hypertension" to boolEntHypertension,
            "bool_ent_bloodPressureMedication" to boolEntBloodpressuremedication,
            "enum_ent_diabetic" to enumEntDiabetic,
        )
        sec_ent_scanLength?.let {
            map["sec_ent_scanLength"] = it
        }
        bool_ent_default_constraints?.let {
            map["bool_ent_default_constraints"] = it
        }
        bool_ent_lighting_quality_constraints?.let {
            map["bool_ent_lighting_quality_constraints"] = it
        }
        return HashMap(map)
    }

    private fun setMultiScanPersistenceDelegate(arguments: Any?, result: Result) {
        if (arguments != null) {
            val args = arguments as List<*>
            args.map { it as Map<*, *> }
            // set persistence delegate history results
            AHIPersistenceDelegate.bodyScanResults = (args as List<Map<String, Any>>).toMutableList()
            // set multiscan persistence delegate
            AHIMultiScan.delegatePersistence = AHIPersistenceDelegate
        }
    }

    private fun startBodyScan(
        arguments: Any?,
        result: Result,
    ) {
        val userInput = getBodyScanUserInput(arguments)
        if (userInput == null) {
            result.error("-5", "Missing user body scan input details", null)
            return
        }
        AHIMultiScan.initiateScan("body", userInput, activityResultRegistry) {
            GlobalScope.launch(Dispatchers.Main) {
                if (!it.isDone) {
                    // TODO: Waiting of results.
                }
                val response = withContext(Dispatchers.IO) { it.get() }
                when (response) {
                    is AHIResult.Success -> {
                        val bodyScanResult = response.value.toMutableMap()
                        result.success(bodyScanResult)
                    }

                    else -> {
                        if (response.error() == BodyScanError.BODY_SCAN_CANCELED) {
                            result.error("USER_CANCELLED", "User cancelled", null)
                        } else {
                            result.error(response?.error()?.code().toString(), response.toString(), null)
                        }
                    }
                }
            }
        }
    }

    private fun getBodyScanUserInput(arguments: Any?): HashMap<String, Any>? {
        if (arguments == null || arguments !is Map<*, *>) {
            return null
        }
        val enumEntSex = arguments["enum_ent_sex"] as? String ?: return null
        val cmEntHeight = arguments["cm_ent_height"].toString().toDoubleOrNull() ?: return null
        val kgEntWeight = arguments["kg_ent_weight"].toString().toDoubleOrNull() ?: return null
        return hashMapOf(
            "enum_ent_sex" to enumEntSex, "cm_ent_height" to cmEntHeight, "kg_ent_weight" to kgEntWeight
        )
    }

    /**
     *  Use this function to fetch the 3D avatar mesh.
     *  The 3D mesh can be created and returned at any time.
     *  We recommend doing this on successful completion of a body scan with the results.
     * */
    private fun getBodyScanExtras(arguments: Any?, result: MethodChannel.Result) {
        if (arguments == null || arguments !is HashMap<*, *>) {
            result.error("-8", "Missing valid body scan result.", null)
            return
        }
        val options = mapOf("extrapolate" to listOf("mesh"))
        AHIMultiScan.getScanExtra(arguments as Map<String, Any>, options) {
            it.fold({ extras ->
                val uri = (extras["extrapolate"] as? List<Map<*, *>>)?.firstOrNull()?.get("mesh") as? Uri
                result.success(mapOf("meshPath" to uri?.path.toString()))
            }, { error ->
                result.error(error.error.code().toString(), error.message, null)
            })
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return activityResultRegistry.dispatchResult(requestCode, resultCode, data)
    }

    object AHIPersistenceDelegate : IAHIPersistence {
        var bodyScanResults = mutableListOf<Map<String, Any>>()
        override fun request(scanType: String, options: Map<String, Any>, completionBlock: (result: AHIResult<Array<Map<String, Any>>>) -> Unit) {
            val data: MutableList<Map<String, Any>> = when (scanType) {
                "body" -> {
                    bodyScanResults
                }

                else -> mutableListOf()
            }
            completionBlock(AHIResult.success(data.toTypedArray()))
        }
    }
}