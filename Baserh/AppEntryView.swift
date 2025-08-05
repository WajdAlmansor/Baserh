import SwiftUI
import FirebaseAuth

struct AppEntryView: View {
    @State private var isLoggedIn: Bool = false
    @State private var isSplashActive: Bool = true // ✅ إظهار Splash أولًا

    var body: some View {
        Group {
            if isSplashActive {
                Splash()
            } else {
                if isLoggedIn {
                    ContentView() // ✅ إذا كان المستخدم مسجلًا، انتقل إلى `ContentView`
                } else {
                    CameraPage()
                }
            }
        }
        .onAppear {
            showSplash()
        }
    }

    /// ✅ **إظهار Splash ثم التحقق من تسجيل الدخول**
    private func showSplash() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // ⏳ تأخير 2.5 ثانية
            self.isSplashActive = false
            checkUserLoginStatus()
        }
    }

    /// ✅ **التحقق مما إذا كان هناك مستخدم مسجل دخول**
    private func checkUserLoginStatus() {
        if Auth.auth().currentUser != nil {
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }
}
