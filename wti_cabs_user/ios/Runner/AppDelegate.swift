import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import flutter_downloader
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ Firebase setup
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    // ✅ flutter_downloader background isolate setup
    FlutterDownloaderPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // ✅ Register for push notifications (safe setup, no crash)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let options: UNAuthorizationOptions = [.alert, .sound, .badge]
      UNUserNotificationCenter.current().requestAuthorization(
        options: options,
        completionHandler: { _, _ in }
      )
    } else {
      let settings = UIUserNotificationSettings(
        types: [.alert, .badge, .sound],
        categories: nil
      )
      application.registerUserNotificationSettings(settings)
    }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Forward APNs device token to FCM safely
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
