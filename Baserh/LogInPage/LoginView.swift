
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var username: String = "" // لحفظ اسم المستخدم بعد تسجيل الدخول
    @State private var isLoggedIn: Bool = false // ⬅️ متغير لحالة تسجيل الدخول
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(red: 222 / 255, green: 235 / 255, blue: 187 / 255)
                      .ignoresSafeArea() // ✅ تمتد إلى كل الشاشة
                    
                VStack(spacing: 25) {
                    Image("eyeImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 210, height: 230)
                        .offset(y:300)

                    ZStack {
                        RoundedRectangle(cornerRadius: 60)
                            .fill(Color.white)
                            .frame(height: UIScreen.main.bounds.height * 0.9)
                            .padding(.top, 300)
                        
                            //.offset(y: 120)
                        
                        VStack(spacing: 35)
                           {
                            Text("تسجيل الدخول")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                               // .padding(.top, -80)

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 30)
                            }

                            HStack {
                                TextField("البريد الإلكتروني", text: $email)
                                    .padding(.vertical, 12)
                                    .padding(.leading, 10)
                                    .foregroundColor(.gray)
                                    .autocapitalization(.none)
                                Spacer()
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .frame(height: 55)
                            .background(RoundedRectangle(cornerRadius: 25).stroke(Color.orange, lineWidth: 1.5))
                            .padding(.horizontal, 30)
                            //.padding(.top, -70)
                            
                            HStack {
                                SecureField("كلمة المرور", text: $password)
                                    .padding(.vertical, 12)
                                    .padding(.leading, 10)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .frame(height: 55)
                            .background(RoundedRectangle(cornerRadius: 25).stroke(Color.orange, lineWidth: 1.5))
                            .padding(.horizontal, 30)
                           // .padding(.top, 10)

                            Button(action: loginUser) {
                                Text("تسجيل الدخول")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(25)
                            }
                            .frame(height: 55)
                            .padding(.horizontal, 30)
                           // .padding(.top, 80)
                        }
                           .padding(.top,10)
                    }
                    
                }
                
            }
            .navigationDestination(isPresented: $isLoggedIn) { // ⬅️ إذا كان المستخدم مسجلًا، انتقل إلى `ContentView`
                ContentView()
            }
        }
    }
    
    
    /// التحقق من تسجيل الدخول
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = "خطأ: \(error.localizedDescription)"
                return
            }

            fetchUsername(for: email) { fetchedUsername in
                if let fetchedUsername = fetchedUsername {
                    self.username = fetchedUsername
                    print("تم تسجيل الدخول بنجاح! اسم المستخدم: \(fetchedUsername)")
                } else {
                    print("تم تسجيل الدخول، لكن لم يتم العثور على اسم المستخدم.")
                }

                // ✅ تحديث الواجهة إلى `AppEntryView` لضمان بقاء تسجيل الدخول
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: AppEntryView())
                        window.makeKeyAndVisible()
                    }
                }
            }
        }
    }

    /// جلب اسم المستخدم من Firestore بعد تسجيل الدخول
    private func fetchUsername(for email: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("admins")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("خطأ في جلب اسم المستخدم: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                let username = snapshot?.documents.first?.data()["name"] as? String
                completion(username)
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
