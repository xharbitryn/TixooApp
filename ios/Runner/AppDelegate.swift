import Flutter
import UIKit
import GoogleMaps   // ✅ Add this import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // ✅ Provide your Google Maps API Key here
    GMSServices.provideAPIKey("AIzaSyCHOZDOIMRgtu4KeG3QKCRis-Vl1HQvXf0")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
