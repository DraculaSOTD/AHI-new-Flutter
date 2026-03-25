import Flutter
import UIKit
import AVFoundation
import AHIMultiScan
import AHIFaceScan
import AHIFingerScan
import AHIBodyScan

public class SwiftAhiSdkTurnkeyPlugin: NSObject, FlutterPlugin {
    
    fileprivate let multiScan = AHIMultiScanModule()
    private enum AHIMultiScanMethod: String {
        /// Default.
        case unknown = ""
        /// Requires a token String to be provided as an argument.
        case setupMultiScanSDK = "setupMultiScanSDK"
        /// Requires a Map object to be passed in containing 3 arguments.
        case authorizeUser = "authorizeUser"
        /// Requires a map object for the required user inputs
        case startFaceScan = "startFaceScan"
        /// Requires a map object for the required user inputs
        case startFingerScan = "startFingerScan"
        /// Returns the SDK status
        case getMultiScanStatus = "getMultiScanStatus"
        /// Requires a map object to override features
        case overrideFingerFeatures = "overrideFingerFeatures"
        /// Requires a map object to override features
        case overrideBodyFeatures = "overrideBodyFeatures"
        /// Requires a map object to override features
        case overrideFaceFeatures = "overrideFaceFeatures"
        /// Requires a map object to override features
        case overrideMultiFeatures = "overrideMultiFeatures"
        /// Returns a Map containing the SDK details.
        case getMultiScanDetails = "getMultiScanDetails"
        /// Returns the user authorization status of the SDK.
        case getUserAuthorizedState = "getUserAuthorizedState"
        /// Will deuathorize the user from the SDK.
        case deauthorizeUser = "deauthorizeUser"
        /// Released the actively registered SDK session.
        case releaseMultiScanSDK = "releaseMultiScanSDK"
        /// Requires a map object for the required user inputs
        case startBodyScan = "startBodyScan"
        /// Requires bodyscan results to get 3D mesh
        case getBodyScanExtras = "getBodyScanExtras"
        /// Check if camera permissions are granted
        case requestCameraPermissions = "requestCameraPermissions"
        /// Check if the AHI resources are downloaded.
        case areAHIResourcesAvailable = "areAHIResourcesAvailable"
        /// Download scan resources.
        case downloadAHIResources = "downloadAHIResources"
        /// Check the size of the AHI resources that require downloading.
        case checkAHIResourcesDownloadSize = "checkAHIResourcesDownloadSize"
        /// Set MultiScan Persistence Delegate.
        case setMultiScanPersistenceDelegate = "setMultiScanPersistenceDelegate"
        /// Dismiss current ViewController.
        case dismissView = "dismissView"
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ahi_sdk_turnkey", binaryMessenger: registrar.messenger())
        let instance = SwiftAhiSdkTurnkeyPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch AHIMultiScanMethod(rawValue: call.method) {
        case .setupMultiScanSDK:
            multiScan.setupMultiScanSDK(token: call.arguments,resultHandler: result)
            break
        case .authorizeUser:
            multiScan.authorizeUser(arguments: call.arguments, resultHandler:result)
            break
        case .startFaceScan:
            multiScan.startFaceScan(arguments: call.arguments, resultHandler:result)
            break
        case .startFingerScan:
            multiScan.startFingerScan(arguments: call.arguments, resultHandler: result)
            break
        case .startBodyScan:
            multiScan.startBodyScan(arguments: call.arguments, resultHandler:result)
            break
        case .getBodyScanExtras:
            multiScan.getBodyScanExtras(arguments: call.arguments, resultHandler:result)
            break
        case .getMultiScanStatus:
            multiScan.getMultiScanStatus(resultHandler:result)
            break
        case .overrideFingerFeatures:
            multiScan.overrideFeatures(scan: "finger", arguments: call.arguments)
            break
        case .overrideFaceFeatures:
            multiScan.overrideFeatures(scan: "face", arguments: call.arguments)
            break
        case .overrideBodyFeatures:
            multiScan.overrideFeatures(scan: "body", arguments: call.arguments)
            break
        case .overrideMultiFeatures:
            multiScan.overrideFeatures(scan: "multiscan", arguments: call.arguments)
            break
        case .getMultiScanDetails:
            multiScan.getMultiScanDetails(resultHandler:result)
            break
        case .getUserAuthorizedState:
            multiScan.getUserAuthorizedState(resultHandler:result)
            break
        case .deauthorizeUser:
            multiScan.deauthorizeUser(resultHandler:result)
            break
        case .releaseMultiScanSDK:
            multiScan.releaseMultiScanSDK(resultHandler:result)
            break
        case .requestCameraPermissions:
            multiScan.requestCameraPermissions(resultHandler:result)
            break

        case .areAHIResourcesAvailable:
            multiScan.areAHIResourcesAvailable(resultHandler:result)
            break
        case .downloadAHIResources:
            multiScan.downloadAHIResources(resultHandler:result)
            break
        case .checkAHIResourcesDownloadSize:
            multiScan.checkAHIResourcesDownloadSize(resultHandler:result)
            break
        case .setMultiScanPersistenceDelegate:
            multiScan.setMultiScanPersistenceDelegate(arguments: call.arguments, resultHandler:result)
            break
        case .dismissView:
            if let vc = topMostVC() {
                vc.dismiss(animated: true, completion: nil)
            }
            result(nil)
            break
        default:
            print("AHI: Invalid method name.")
        }
    }
}

// MARK: - AHI MultiScan Module

private class AHIMultiScanModule: NSObject {
    var isFinishedDownloadingResources = false
    
    // MARK: Scan Instances
    
    /// Instance of AHI MultiScan
    let ahi = MultiScan.shared()
    /// Instance of AHI FaceScan
    let faceScan = FaceScan()
    /// Instance of AHI FingerScan
    let fingerScan = FingerScan()
    /// Instance of AHI BodyScan
    let bodyScan = BodyScan()
    
    var bodyScanResults = [[String:Any]]()

    public override init() {
        super.init()
    }
}

// MARK: - MultiScan SDK Setup Functions

extension AHIMultiScanModule {
    /// Setup the MultiScan SDK
    ///
    /// This must happen before requesting a scan.
    /// We recommend doing this on successful load of your application.
    fileprivate func setupMultiScanSDK(token: Any?, resultHandler: @escaping FlutterResult) {
        guard let token = token as? String else {
            resultHandler(FlutterError(code: "-1", message: "Missing multi scan token", details: nil))
            return
        }
        ahi.setup(withConfig: ["TOKEN": token], scans: [bodyScan, faceScan, fingerScan]) { [weak self] error in
            if let err = error as? NSError, err.code != AHIMultiScanErrorCode.codeSetupAlreadyCompleted.rawValue {
                resultHandler(self?.createFlutterError(fromError: err))
                return
            }
            resultHandler(nil)
        }
    }
    
    /// Once successfully setup, you should authorize your user with our service.
    ///
    /// With your signed in user, you can authorize them to use the AHI service,  provided that they have agreed to a payment method.
    fileprivate func authorizeUser(arguments: Any?, resultHandler: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
            let userID = args["user_id"] as? String,
            let salt = args["salt"] as? String,
            let claims = args["claims"] as? [String]
        else {
            resultHandler(FlutterError(code: "-2", message: "Missing user authorization details.", details: nil))
            return
        }
        ahi.userAuthorize(forId: userID, withSalt: salt, withClaims: claims) { [weak self] authError in
            if let err = authError {
                resultHandler(self?.createFlutterError(fromError: err))
                return
            }
            resultHandler(nil)
        }
    }
}

// MARK: - AHI Multi Scan Remote Resources
extension AHIMultiScanModule {
    /// Check if the AHI resources are downloaded.
    ///
    /// We have remote resources that exceed 100MB that enable our scans to work.
    /// You are required to download them inorder to obtain a body scan.
    fileprivate func areAHIResourcesAvailable(resultHandler: @escaping FlutterResult) {
        ahi.areResourcesDownloaded { [weak self] success, error in
            if !success {
                print("AHI INFO: Resources are not downloaded, error: \\(error?.localizedDescription ?? "<unknown>")")
                resultHandler(success);
                return
            }
            self?.isFinishedDownloadingResources = success
            print("AHI: Resources ready")
            resultHandler(success);
        }
    }

    /// Download scan resources.
    ///
    /// We recommend only calling this function once per session to prevent duplicate background resource calls.
    fileprivate func downloadAHIResources(resultHandler: @escaping FlutterResult) {
        ahi.downloadResourcesInBackground()
        resultHandler(true);
    }

    /// Check the size of the AHI resources that require downloading. 
    fileprivate func checkAHIResourcesDownloadSize(resultHandler: @escaping FlutterResult) {
        ahi.totalEstimatedDownloadSizeInBytes { [weak self] bytes, totalBytes, error in
            print("AHI INFO: Size of download is \\(self?.convertBytesToMBString(Int(bytes)) ?? "0") / \\(self?.convertBytesToMBString(Int(totalBytes)) ?? "0")")
            resultHandler([bytes, totalBytes]);
        }
    }
}

// MARK: - AHI MultiScan Optional Functions

extension AHIMultiScanModule {
    fileprivate func overrideFeatures(scan: String, arguments: Any?) {
        guard let args = arguments as? [String: Any], !scan.isEmpty,
                ["finger", "body", "face", "multiscan"].contains(scan) else {
            return
        }
        var features: [String: Any]
        if !args.keys.contains("multiscan") && (scan != "multiscan") {
            features = [scan: args,
                            "multiscan":["23.8_filterPostfix": ["enabled": false],],
            ];
        } else {
            features = [scan: args]
        }
        ahi.setFeatureOverrides(features);
    }

    /// Check if MultiScan is on or offline.
    fileprivate func getMultiScanStatus(resultHandler: @escaping FlutterResult) {
        ahi.status { multiScanStatus in
            switch (multiScanStatus) {
            case AHIMultiScanStatus.disconnected:
                resultHandler("AHIMultiScanStatusDisconnected")
            case AHIMultiScanStatus.notSetup:
                resultHandler("AHIMultiScanStatusNotSetup")
            case AHIMultiScanStatus.ready:
                resultHandler("AHIMultiScanStatusReady")
            default:
                resultHandler("\\(multiScanStatus)")
            }
        }
    }
    
    /// Check your AHI MultiScan organisation  details.
    fileprivate func getMultiScanDetails(resultHandler: @escaping FlutterResult) {
        if let details = ahi.getDetails() {
            let config = ["vid":details["vid"], "aid":details["aid"], "setup":details["setup"]]
            resultHandler(config)
        } else {
            resultHandler(nil)
        }
    }
    
    /// Check if the user is authorized to use the MuiltScan service.
    fileprivate func getUserAuthorizedState(resultHandler: @escaping FlutterResult) {
        ahi.userIsAuthorized { isAuthorized, partnerUserId, error in
            resultHandler(isAuthorized)
        }
    }
    
    /// Deuauthorize the user.
    fileprivate func deauthorizeUser(resultHandler: @escaping FlutterResult) {
        // TODO: Issue with MultiScan iOS where deauthorizeUser is not returning.
        ahi.userDeauthorize()
        resultHandler(nil)
    }
    
    /// Release the MultiScan SDK session.
    ///
    /// If you  use this, you will need to call setupSDK again.
    fileprivate func releaseMultiScanSDK(resultHandler: @escaping FlutterResult) {
        ahi.releaseSDK { [weak self] error in
            resultHandler(self?.createFlutterError(fromError: error))
        }
    }

}

// Persistence Delegate
extension AHIMultiScanModule: AHIDelegatePersistence {
    public func setMultiScanPersistenceDelegate(arguments: Any?, resultHandler: @escaping FlutterResult) {
        guard let bsResults = arguments as? [[String: Any]] else {
            return
        }
        ahi.delegatePersistence = self
        bodyScanResults = bsResults
    }

    func requestScanType(_ scan: String, options: [String : Any] = [:], completion completionBlock: @escaping (Error?, [[String : Any]]?) -> Void) {
        // Call the completion block to return the results to the SDK.
        completionBlock(nil, bodyScanResults)
    }
}

// MARK: - AHI Face Scan Initialiser

extension AHIMultiScanModule {
    fileprivate func startFaceScan(arguments: Any?, resultHandler: @escaping FlutterResult) {
        // Guard input arguments
        guard let args = arguments as? [String: Any],
            let enum_ent_sex = args["enum_ent_sex"] as? String,
            let cm_ent_height = (args["cm_ent_height"] as? NSNumber)?.intValue,
            let kg_ent_weight = (args["kg_ent_weight"] as? NSNumber)?.intValue,
            let yr_ent_age = (args["yr_ent_age"] as? NSNumber)?.intValue,
            let bool_ent_smoker = args["bool_ent_smoker"] as? Bool,
            let bool_ent_hypertension = args["bool_ent_hypertension"] as? Bool,
            let bool_ent_bloodPressureMedication = args["bool_ent_bloodPressureMedication"] as? Bool,
            let enum_ent_diabetic = args["enum_ent_diabetic"] as? String
        else {
            resultHandler(FlutterError(code: "-3", message: "Missing user face scan input details.", details: nil))
            return
        }
        var userInputs: [String : Any] = [
            "enum_ent_sex": enum_ent_sex,
            "cm_ent_height": cm_ent_height,
            "kg_ent_weight": kg_ent_weight,
            "yr_ent_age": yr_ent_age,
            "bool_ent_smoker": bool_ent_smoker,
            "bool_ent_hypertension": bool_ent_hypertension,
            "bool_ent_bloodPressureMedication": bool_ent_bloodPressureMedication,
            "enum_ent_diabetic": enum_ent_diabetic,
            "bool_ent_debugMode": args["debug_isDebug"] as? Bool ?? false,
        ]
        
        if let args = arguments as? [String: Any] {
            if let sec_ent_scanLength = (args["sec_ent_scanLength"] as? NSNumber)?.intValue {
                userInputs["sec_ent_scanLength"] = sec_ent_scanLength
            }
            if let bool_ent_default_constraints = args["bool_ent_default_constraints"] as? Bool{
                userInputs["bool_ent_default_constraints"] = bool_ent_default_constraints
            }
            if let bool_ent_default_constraints = args["bool_ent_lighting_quality_constraints"] as? Bool{
                userInputs["bool_ent_lighting_quality_constraints"] = bool_ent_default_constraints
            }
        }
        
        // Ensure the view controller being used is the top one.
        // If you are not attempting to get a scan simultaneous with dismissing your calling view controller, or attempting to present from a view controller lower in the stack
        // you may have issues.
        guard let vc = topMostVC() else { return }
        ahi.initiateScan("face", withOptions: userInputs, from: vc) { [weak self] scanTask, error in
            guard let task = scanTask, error == nil else {
                resultHandler(self?.createFlutterError(fromError: error))
                print("error 1")
                return
            }
            task.continueWith(block: { resultsTask in
                if let errorRT = resultsTask.error {
                    resultHandler(FlutterError(code: "-10", message: "FaceScan Failed. \\(errorRT.localizedDescription)", details: nil))
                    print("error 2")
                } else if let results = resultsTask.result as? [String : Any] {
                    resultHandler(results)
                } else {
                    resultHandler(FlutterError(code: "-10", message: "FaceScan Failed.", details: nil))
                    print("error 3")
                }
                return nil
            })
        }
    }
}

// MARK: - AHI Finger Scan Initialiser

extension AHIMultiScanModule {
    fileprivate func startFingerScan(arguments: Any?, resultHandler: @escaping FlutterResult) {
        // Guard input arguments
        guard let args = arguments as? [String: Any],
            let sec_ent_scanLength = args["sec_ent_scanLength"] as? Int,
            let str_ent_instruction1 = args["str_ent_instruction1"] as? String,
            let str_ent_instruction2 = args["str_ent_instruction2"] as? String
        else {
            resultHandler(FlutterError(code: "-3", message: "Missing user finger scan input details.", details: nil))
            return
        }
        var userInputs: [String : Any] = [:]
        for (key, value) in args {
            userInputs[key] = value
        }
        
        // Ensure the view controller being used is the top one.
        // If you are not attempting to get a scan simultaneous with dismissing your calling view controller, or attempting to present from a view controller lower in the stack
        // you may have issues.
        guard let vc = topMostVC() else { return }
        ahi.initiateScan("finger", withOptions: userInputs, from: vc) { [weak self] scanTask, error in
            guard let task = scanTask, error == nil else {
                resultHandler(self?.createFlutterError(fromError: error))
                return
            }
            task.continueWith(block: { resultsTask in
                if let errorRT = resultsTask.error {
                    resultHandler(FlutterError(code: "-10", message: "FingerScan Failed. \\(errorRT.localizedDescription)", details: nil))
                } else if var results = resultsTask.result as? [String : Any] {
                    if let ppgPath = results["str_raw_ppgFilePath"] as? String, FileManager.default.fileExists(atPath: ppgPath) {
                        results["listPPGData"] = NSArray(contentsOfFile: ppgPath)
                        results.removeValue(forKey: "str_raw_ppgFilePath")
                        resultHandler(results)
                    }
                    else {
                        resultHandler(FlutterError(code: "-9", message: "FingerScan Failed. No PPG data returned.", details: nil))
                    }
                } else {
                    resultHandler(FlutterError(code: "-9", message: "FingerScan Failed.", details: nil))
                }
                return nil
            })
        }
    }
}


// MARK: - AHI Body Scan Initialiser

extension AHIMultiScanModule {
    fileprivate func startBodyScan(arguments: Any?, resultHandler: @escaping FlutterResult) {
        // Need to separate the payment type content from the Map.
        guard let args = arguments as? [String: Any],
            let enum_ent_sex = args["enum_ent_sex"] as? String,
            let cm_ent_height = (args["cm_ent_height"] as? NSNumber)?.floatValue,
            let kg_ent_weight = (args["kg_ent_weight"] as? NSNumber)?.floatValue
        else {
            resultHandler(FlutterError(code: "-5", message: "Missing user body scan input details.", details: nil))
            return
        }
        let debug_on = args["debug_isDebug"] as? Bool ?? false
        let userInputs: [String : Any] = [
            "enum_ent_sex": enum_ent_sex,
            "cm_ent_height": cm_ent_height,
            "kg_ent_weight": kg_ent_weight,
            "debug_isDebug": debug_on,
            "debug_showSkeleton": debug_on,
            "debug_useMockCamera": false

        ]
        guard let vc = topMostVC() else { return }
        ahi.initiateScan("body", withOptions: userInputs, from: vc) { scanTask, error in
            guard let task = scanTask, error == nil else {
                resultHandler(self.createFlutterError(fromError: error))
                return
            }
            task.continueWith(block: { resultsTask in
                if let errorRT = resultsTask.error {
                    resultHandler(FlutterError(code: "-10", message: "BodyScan Failed. \\(errorRT.localizedDescription)", details: nil))
                } else if var results = resultsTask.result as? [String : Any] {
                    results.removeValue(forKey: "miscData")
                        resultHandler(results)
                } else {
                    resultHandler(FlutterError(code: "-8", message: "BodyScan Failed", details: nil))
                }
                return nil
            })
        }
    }

    /**
     *  Use this function to fetch the 3D avatar mesh.
     *  The 3D mesh can be created and returned at any time.
     *  We recommend doing this on successful completion of a body scan with the results.
     * */
    fileprivate func getBodyScanExtras(arguments: Any?, resultHandler: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any] else {
            resultHandler(FlutterError(code: "-6", message: "Missing body scan result data", details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.ahi.getExtra(["body":[args as [String:Any]]],query: ["extrapolate":["mesh"]]) { result, error in
                if let items = result?["extrapolate"]?.first as? Dictionary<String, Any> {
                    if let meshUrl = items["mesh"] as? NSURL {
                        DispatchQueue.main.async {
                            let result = ["meshPath": meshUrl.path]
                            resultHandler(result);
                        }
                    } else {
                        DispatchQueue.main.async {
                            resultHandler(FlutterError(code: "-7", message: "Error in generating 3D mesh - Path Not Found", details: nil))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        resultHandler(FlutterError(code: "-7", message: "Error in generating 3D mesh - Result Not Found", details: nil))
                    }
                }
            }
        }
    }
}

// MARK: - ViewController Helper

extension NSObject {
    /// Recieves the download size in bytes and returns the conversion in MB.
    ///
    /// Use the iOS native ByteFormatter to convert the bytes value to a MB String.
    public func convertBytesToMBString(_ bytes: Int) -> String {
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = .useMB
        byteFormatter.countStyle = .binary
        return byteFormatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Return topmost viewController to initiate face and bodyscan
    public func topMostVC() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}

// MARK: - Error Safety

extension AHIMultiScanModule {
    private func createFlutterError(fromError error: Error?) -> FlutterError? {
        guard let err = error as? NSError else {
            return nil
        }
        let errCode = (err.code == AHIFingerScanErrorCode.codeScanCanceled.rawValue || err.code == AHIFaceScanErrorCode.ScanCanceled.rawValue) ? "USER_CANCELLED" : "\\(err.code)"
        var errMessage = err.localizedDescription
        if errMessage.isEmpty {
            errMessage = "Unknown error occurred. Please contact developer support."
        }
        return FlutterError(code: "\\(errCode)", message: errMessage, details: nil)
    }
}

extension AHIMultiScanModule {
    func requestCameraPermissions(resultHandler: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            resultHandler(granted)
        }
    }
}