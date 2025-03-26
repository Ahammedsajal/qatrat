import Flutter
import UIKit
import FirebaseCore
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase with error handling
    do {
      try FirebaseApp.configure()
      print("Firebase configured successfully")
    } catch {
      print("Failed to configure Firebase: \(error.localizedDescription)")
      // Optionally, you can decide whether to proceed or terminate the app
      // For now, we'll proceed to avoid crashing
    }
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Handle Google Sign-In redirect URL
    return GIDSignIn.sharedInstance.handle(url)
  }
}
