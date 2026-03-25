import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register AHI SDK Turnkey plugin
    SwiftAhiSdkTurnkeyPlugin.register(with: registrar(forPlugin: "AhiSdkTurnkey"))
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
