package tech.ahi.sdk.ahi_bodyscan_flutter

enum class AHIMultiScanMethod(val methodName: String) {
    /** Requires a token String to be provided as an argument. */
    SETUP_MULTISCAN_SDK("setupMultiScanSDK"),

    /** Requires a Map object to be passed in containing 3 arguments. */
    AUTHORIZE_USER("authorizeUser"),

    /** Will return a boolean */
    ARE_AHI_RESOURCES_AVAILABLE("areAHIResourcesAvailable"),

    /** A void function that will invoke the download of remote resources. */
    DOWNLOAD_AHI_RESOURCES("downloadAHIResources"),

    /** Will return an integer for the bytes size. */
    CHECK_AHI_RESOURCES_DOWNLOAD_SIZE("checkAHIResourcesDownloadSize"),

    /** Returns bool with camera permissions granted status */
    REQUEST_CAMERA_PERMISSIONS("requestCameraPermissions"),

    /** Requires a map object for the required user inputs */
    START_FACESCAN("startFaceScan"),

    /** Requires a map object for the required user inputs */
    START_FINGERSCAN("startFingerScan"),

    /** Requires a map object for the required user inputs */
    START_BODYSCAN("startBodyScan"),

    /** Requires a map object of the body scan results and returns a Map object. */
    GET_BODYSCAN_EXTRAS("getBodyScanExtras"),

    /** Returns the SDK status */
    GET_MULTISCAN_STATUS("getMultiScanStatus"),

    /** Requires a map object to override features */
    OVERRIDE_FINGER_FEATURES("overrideFingerFeatures"),

    /** Requires a map object to override features */
    OVERRIDE_FACE_FEATURES("overrideFaceFeatures"),

    /** Requires a map object to override features */
    OVERRIDE_BODY_FEATURES("overrideBodyFeatures"),

    /** Requireds a map object to override features */
    OVERRIDE_MULTI_FEATURES("overrideMultiFeatures"),

    /** Returns a Map containing the SDK details. */
    GET_MULTISCAN_DETAILS("getMultiScanDetails"),

    /** Returns the user authorization status of the SDK. */
    GET_USER_AUTHORIZED_STATE("getUserAuthorizedState"),

    /** Will deauthorize the user from the SDK. */
    DEAUTHORIZE_USER("deauthorizeUser"),

    /** Released the actively registered SDK session. */
    RELEASE_MULTISCAN_SDK("releaseMultiScanSDK"),

    /** Set Multiscan Persistence Delegate */
    SET_MULTISCAN_PERSISTENCE_DELEGATE("setMultiScanPersistenceDelegate")

}