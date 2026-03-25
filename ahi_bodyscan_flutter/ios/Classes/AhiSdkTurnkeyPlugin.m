#import "AhiSdkTurnkeyPlugin.h"
#if __has_include(<ahi_bodyscan_flutter/ahi_bodyscan_flutter-Swift.h>)
#import <ahi_bodyscan_flutter/ahi_bodyscan_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ahi_bodyscan_flutter-Swift.h"
#endif

@implementation AhiSdkTurnkeyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAhiSdkTurnkeyPlugin registerWithRegistrar:registrar];
}
@end