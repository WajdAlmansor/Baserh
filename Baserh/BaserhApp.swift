import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct BaserhApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    init() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = .light
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            AppEntryView()
            
        }
    }
}
