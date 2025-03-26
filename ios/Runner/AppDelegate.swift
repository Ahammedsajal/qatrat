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
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Set the presenting view controller for Google Sign-In
    if let controller = window?.rootViewController as? FlutterViewController {
      GIDSignIn.sharedInstance.presentingViewController = controller
    } else {
      print("Error: Could not set presenting view controller for Google Sign-In")
    }
    
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
