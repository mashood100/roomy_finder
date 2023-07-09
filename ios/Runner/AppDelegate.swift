import UIKit
import Flutter
import GoogleMaps
import Firebase
import FirebaseAuth
import FirebaseMessaging
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }


    GMSServices.provideAPIKey("AIzaSyC47GU5pZodzRzVZHC6Q1iw9LwFDQpixQ8")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let extHelper = FirebaseMessaging.FIRMessagingExtensionHelper.init()
        extHelper.exportDeliveryMetricsToBigQuery(withMessageInfo: response.notification.request.content.userInfo)
    }
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
              Messaging.messaging().apnsToken = deviceToken
              super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
           let firebaseAuth = Auth.auth()
           firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)

       }
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            let firebaseAuth = Auth.auth()
            if (firebaseAuth.canHandleNotification(userInfo)){
                print(userInfo)
                return
            }

        }
   override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("application didRegisterForRemoteNotificationsWithDeviceToken")
}

}
