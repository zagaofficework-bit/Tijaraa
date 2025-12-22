// import UIKit
// import Flutter
// import FirebaseCore
// import GoogleMaps
// import FirebaseAuth
// import awesome_notifications
// import FirebaseMessaging
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GMSServices.provideAPIKey("PLACE_YOUR_API_KEY_HERE")
//     GeneratedPluginRegistrant.register(with: self)
//
//       SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
//                SwiftAwesomeNotificationsPlugin.register(
//                  with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
//            }
//         if FirebaseApp.app() == nil {
//             FirebaseApp.configure()
//         }
//
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
//  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//     Messaging.messaging().apnsToken = deviceToken
//   }
//
// }
//



import UIKit
import Flutter
import FirebaseCore
import GoogleMaps
import FirebaseAuth
import FirebaseMessaging
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var blurView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GMSServices.provideAPIKey("PLACE_YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)

    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      SwiftAwesomeNotificationsPlugin.register(
        with: registry.registrar(
          forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin"
        )!
      )
    }

    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // 🔐 Observe screen capture (recording / mirroring)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenCapture),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔐 Secure UI handler
  @objc private func handleScreenCapture() {
    DispatchQueue.main.async {
      if UIScreen.main.isCaptured {
        self.addBlurOverlay()
      } else {
        self.removeBlurOverlay()
      }
    }
  }

  // 🔒 Add blur overlay (safe)
  private func addBlurOverlay() {
    guard blurView == nil,
          let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    let blur = UIVisualEffectView(effect: blurEffect)
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blur.tag = 999

    window.addSubview(blur)
    blurView = blur
  }

  // 🔓 Remove blur overlay
  private func removeBlurOverlay() {
    blurView?.removeFromSuperview()
    blurView = nil
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }
}

