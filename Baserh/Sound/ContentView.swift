import SwiftUI
import FirebaseDatabase
import Combine
import FirebaseAuth
import FirebaseFirestore

class VoiceManager: ObservableObject {
    @Published var voices: [(String, String, Float, Float, Float)] = [] // قائمة الأصوات
    @Published var defaultVoice: (name: String, volume: Float, rate: Float, pitch: Float) = ("Default", 0.5, 0.5, 1.0)

    private var db = Firestore.firestore()

    init() {
        fetchUserVoices()  // ✅ تحميل الأصوات عند بدء التطبيق
    }

    /// ✅ **جلب الأصوات الخاصة بالمستخدم الحالي فقط**
    func fetchUserVoices() {
        guard let user = Auth.auth().currentUser else { return }

        db.collection("voices")
            .whereField("userID", isEqualTo: user.uid) // 👈 اجلب فقط أصوات المستخدم الحالي
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ خطأ في جلب الأصوات: \(error.localizedDescription)")
                    return
                }

                self.voices = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return (
                        data["name"] as? String ?? "",
                        data["language"] as? String ?? "",
                        data["volume"] as? Float ?? 0.5,
                        data["rate"] as? Float ?? 0.5,
                        data["pitch"] as? Float ?? 1.0
                    )
                } ?? []
            }
    }

    /// ✅ **إضافة صوت جديد إلى Firestore وربطه بالمستخدم الحالي**
    func addVoice(name: String, language: String, volume: Float, rate: Float, pitch: Float) {
        guard let user = Auth.auth().currentUser else { return }

        let voiceData: [String: Any] = [
            "name": name,
            "language": language,
            "volume": volume,
            "rate": rate,
            "pitch": pitch,
            "userID": user.uid
        ]

        // ✅ **إضافة الصوت إلى Firestore**
        db.collection("voices").addDocument(data: voiceData) { error in
            if let error = error {
                print("❌ خطأ في إضافة الصوت إلى Firestore: \(error.localizedDescription)")
            } else {
                print("✅ تم حفظ الصوت في Firestore!")
                self.fetchUserVoices() // ⬅️ تحديث القائمة بعد الإضافة
            }
        }

        // ✅ **إضافة الصوت إلى Realtime Database أيضًا**
        let realtimeRef = Database.database().reference()
            .child("users")
            .child(user.uid)
            .child("voices") // ⬅️ سيتم حفظ كل الأصوات داخل `voices` لكل مستخدم
        
        let newVoiceRef = realtimeRef.childByAutoId() // 🔥 إنشاء ID تلقائي لكل صوت جديد
        newVoiceRef.setValue(voiceData) { error, _ in
            if let error = error {
                print("❌ خطأ في إضافة الصوت إلى Realtime Database: \(error.localizedDescription)")
            } else {
                print("✅ تم حفظ الصوت في Realtime Database!")
            }
        }
    }

    func updateDefaultVoice(name: String, volume: Float, rate: Float, pitch: Float) {
        guard let user = Auth.auth().currentUser else { return }

        let newVoice = [
            "name": name,
            "volume": volume,
            "rate": rate,
            "pitch": pitch
        ] as [String: Any]

        // ✅ **تحديث الصوت الافتراضي في Firestore لكل مستخدم على حدة**
        let firestoreRef = db.collection("users").document(user.uid)
        firestoreRef.setData(["defaultVoice": newVoice], merge: true) { error in
            if let error = error {
                print("❌ خطأ في تحديث الصوت الافتراضي في Firestore: \(error.localizedDescription)")
            } else {
                print("✅ تم تعيين \(name) كصوت افتراضي للمستخدم في Firestore")
            }
        }

        // ✅ **تحديث الصوت الافتراضي للجميع في Realtime Database**
        let realtimeRef = Database.database().reference().child("defaultVoice")
        realtimeRef.setValue(newVoice) { error, _ in
            if let error = error {
                print("❌ خطأ في تحديث الصوت الافتراضي في Realtime Database: \(error.localizedDescription)")
            } else {
                print("✅ تم تحديث الصوت الافتراضي للجميع في Realtime Database!")
            }
        }
    }


    /// ✅ **تحديث إعدادات صوت معين**
    func updateVoice(name: String, volume: Float, rate: Float, pitch: Float) {
        guard let user = Auth.auth().currentUser else { return }

        db.collection("voices")
            .whereField("userID", isEqualTo: user.uid)
            .whereField("name", isEqualTo: name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ خطأ في تحديث الصوت: \(error.localizedDescription)")
                    return
                }

                for document in snapshot?.documents ?? [] {
                    self.db.collection("voices").document(document.documentID).updateData([
                        "volume": volume,
                        "rate": rate,
                        "pitch": pitch
                    ]) { error in
                        if let error = error {
                            print("❌ خطأ في تحديث الصوت: \(error.localizedDescription)")
                        } else {
                            print("✅ تم تحديث الصوت بنجاح!")
                            self.fetchUserVoices()
                        }
                    }
                }
            }
    }

    func observeDefaultVoice() {
        let realtimeRef = Database.database().reference().child("defaultVoice")
        
        realtimeRef.observe(.value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                DispatchQueue.main.async {
                    self.defaultVoice = (
                        name: value["name"] as? String ?? "Default",
                        volume: value["volume"] as? Float ?? 0.5,
                        rate: value["rate"] as? Float ?? 0.5,
                        pitch: value["pitch"] as? Float ?? 1.0
                    )
                    print("✅ تم تحديث الصوت الافتراضي إلى: \(self.defaultVoice.name)")
                }
            }
        }
    }

    /// ✅ **حذف صوت معين**
    func deleteVoice(name: String) {
        guard let user = Auth.auth().currentUser else { return }

        db.collection("voices")
            .whereField("userID", isEqualTo: user.uid)
            .whereField("name", isEqualTo: name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ خطأ في حذف الصوت: \(error.localizedDescription)")
                    return
                }

                for document in snapshot?.documents ?? [] {
                    self.db.collection("voices").document(document.documentID).delete { error in
                        if let error = error {
                            print("❌ خطأ في حذف الصوت: \(error.localizedDescription)")
                        } else {
                            print("✅ تم حذف الصوت بنجاح!")
                            self.fetchUserVoices()
                        }
                    }
                }
            }
    }
}


struct ContentView: View {
    @StateObject var voiceManager = VoiceManager()
    @State private var selectedVoiceIndex: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                HeaderView()
                VStack {
                    Spacer()
                    VoiceListView(voiceManager: voiceManager, selectedVoiceIndex: $selectedVoiceIndex)
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                voiceManager.fetchUserVoices() // ✅ تحميل الأصوات الخاصة بالمستخدم عند فتح الصفحة
            }
        }
    }
}

// ✅ **هيدر التطبيق (العنوان والأيقونة)**
struct HeaderView: View {
    var body: some View {
        ZStack {
            Color(red: 222 / 255, green: 235 / 255, blue: 187 / 255)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    
                    Text("اختر صوت مناسب")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .offset(x:36,y: -300)

                    Spacer()

                    // ✅ زر تسجيل الخروج
                    Button(action: {
                        logoutUser()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.01)) // ✅ جعل الزر قابلًا للضغط
                            .contentShape(Rectangle()) // ✅ توسيع نطاق الضغط
                    }
                    .padding(.trailing, 20)
                    .offset(y: -300)
                }
                .frame(height: 50)
            }
        }
    }
}


    /// ✅ **دالة تسجيل الخروج**
    func logoutUser() {
        do {
            try Auth.auth().signOut() // ✅ تسجيل خروج المستخدم من Firebase
            print("✅ تم تسجيل الخروج بنجاح!")

            // ✅ إعادة المستخدم إلى شاشة تسجيل الدخول
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: CameraPage())
                window.makeKeyAndVisible()
            }

        } catch let error {
            print("❌ خطأ في تسجيل الخروج: \(error.localizedDescription)")
        }
    }



// ✅ **قائمة الأصوات المخزنة**
struct VoiceListView: View {
    @ObservedObject var voiceManager: VoiceManager
    @Binding var selectedVoiceIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RoundedRectangle(cornerRadius: 90)
                .fill(Color.white)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.8)
                .offset(y: 80)
                .overlay(
                    VStack(spacing: 10) {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(voiceManager.voices.indices, id: \.self) { index in
                                    let voice = voiceManager.voices[index]
                                    VoiceRow(voiceManager: voiceManager, voice: voice, selectedVoiceIndex: $selectedVoiceIndex, index: index)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.45)

                        // ✅ **إضافة `VoiceActionsView` هنا**
                        VoiceActionsView(voiceManager: voiceManager, selectedVoiceIndex: $selectedVoiceIndex)
                            .animation(.easeInOut, value: selectedVoiceIndex)
                            .transition(.move(edge: .bottom))
                    }
                    .padding(.bottom, -90)
                )
        }
    }
}

// ✅ **عنصر فردي في قائمة الأصوات**
struct VoiceRow: View {
    @ObservedObject var voiceManager: VoiceManager
    var voice: (String, String, Float, Float, Float)
    @Binding var selectedVoiceIndex: Int?
    var index: Int

    var body: some View {
        Button(action: {
            withAnimation {
                selectedVoiceIndex = (selectedVoiceIndex == index ? nil : index)
            }
        }) {
            HStack {
                Text(voice.0)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 222 / 255, green: 235 / 255, blue: 187 / 255))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    )
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(selectedVoiceIndex == index ? Color.orange : Color.white)
            .cornerRadius(15)
            .shadow(radius: 0.5)
            .scaleEffect(selectedVoiceIndex == index ? 1.05 : 1.0)
            .animation(.spring(), value: selectedVoiceIndex)
        }
    }
}


// ✅ **عرض الأزرار: حذف، تعديل، واستخدام الصوت**

struct VoiceActionsView: View {
    @ObservedObject var voiceManager: VoiceManager
    @Binding var selectedVoiceIndex: Int?

    var body: some View {
        VStack(spacing: 10) {
            if let index = selectedVoiceIndex, index < voiceManager.voices.count {
                // ✅ **إظهار الأزرار الثلاثة عند تحديد صوت**
                Button(action: {
                    withAnimation {
                        if index < voiceManager.voices.count {
                            let voiceToDelete = voiceManager.voices[index].0
                            selectedVoiceIndex = nil
                            voiceManager.deleteVoice(name: voiceToDelete)
                        }
                    }
                }) {
                    Text("حذف الصوت")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }

                NavigationLink(
                    destination: VoiceControlView(
                        voiceManager: voiceManager,
                        selectedVoiceName: voiceManager.voices[index].0,
                        volume: Double(voiceManager.voices[index].2),
                        speechRate: Double(voiceManager.voices[index].3),
                        pitch: Double(voiceManager.voices[index].4)
                    )
                ) {
                    Text("تعديل الصوت")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }

                Button(action: {
                    if let index = selectedVoiceIndex, index < voiceManager.voices.count {
                        let selectedVoice = voiceManager.voices[index]
                        voiceManager.updateDefaultVoice(
                            name: selectedVoice.0,
                            volume: selectedVoice.2,
                            rate: selectedVoice.3,
                            pitch: selectedVoice.4
                        )
                    }
                }) {
                    Text("استخدم هذا الصوت")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            } else {
                // ✅ **إظهار زر "إضافة صوت جديد" فقط عند عدم تحديد أي صوت**
                NavigationLink(destination: VoiceControlView(voiceManager: voiceManager)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 25))
                        Text("إضافة صوت جديد")
                            .font(.headline)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
            }
        }
        .opacity(1) // ✅ لا نجعلها تختفي بالكامل، بل تتبدل فقط بين الأزرار المختلفة
        .animation(.easeInOut(duration: 0.3), value: selectedVoiceIndex)
    }
}



#Preview {
    ContentView()
}
