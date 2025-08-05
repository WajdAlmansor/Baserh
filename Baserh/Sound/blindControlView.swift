import SwiftUI
import AVFoundation
import Firebase
import FirebaseFirestore

struct blindControl: View {
    @StateObject var blindControlManager = blindControlView()
    @State private var selectedVoice: (String, String, Float, Float, Float)? = nil
    let speechSynthesizer = AVSpeechSynthesizer()
    @State private var selectedLanguage: String = "ar-SA"

    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(red: 0xDE / 255, green: 0xEB / 255, blue: 0xBB / 255)
                    .ignoresSafeArea()

                VStack {
                    Text("اختر صوت مناسب")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .offset(y: 160)

                    Spacer()

                    RoundedRectangle(cornerRadius: 90)
                        .fill(Color.white)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.9)
                        .padding(.top, 150)
                        .overlay(
                            
                            ScrollView {
                                
                                VStack(spacing: 15) {
                                    ForEach(blindControlManager.voices.indices, id: \.self) { index in
                                        let voice = blindControlManager.voices[index]

                                        VStack {
                                            HStack {
                                                
                                                Button(action: {
                                                    speak(voiceData: voice)
                                                }) {
                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 21))
                                                        .foregroundColor(.gray)
                                                }

                                                Spacer()

                                                Text(voice.0)
                                                    .font(.headline)
                                                    .foregroundColor(.black)

                                                Spacer()

                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(red: 0xDE / 255, green: 0xEB / 255, blue: 0xBB / 255))
                                                    .frame(width: 50, height: 50)
                                                    .overlay(
                                                        Image(systemName: "music.note")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(Color(red: 0x5A / 255, green: 0x6E / 255, blue: 0x25 / 255))
                                                    )
                                            }
                                            .padding()

                                            
                                            Button(action: {
                                                blindControlManager.setDefaultVoice(voice: voice)
                                                selectedVoice = voice
                                            }) {
                                                Text(selectedVoice?.0 == voice.0 ? "✅ الصوت الافتراضي" : "اختيار هذا الصوت")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity, minHeight: 40)
                                                    .background(selectedVoice?.0 == voice.0 ? Color.green : Color.orange)
                                                    .cornerRadius(10)
                                                    .padding(.horizontal, 10)
                                                    .padding(.bottom, 10)
                                            }
                                        }
                                        .background(Color.white)
                                        .cornerRadius(15)
                                        .shadow(radius: 0.5)
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 30)
                            }
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
                            .clipShape(RoundedRectangle(cornerRadius: 90))
                        )
                        .padding(.top, 50)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                selectedVoice = blindControlManager.getDefaultVoice()
            }
        }
    }

    /// ✅ **تشغيل الصوت المحدد**==
    func speak(voiceData: (String, String, Float, Float, Float)) {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: "مرحباً! هذا هو الصوت المختار.")

        utterance.voice = AVSpeechSynthesisVoice(language: voiceData.1)
        utterance.volume = voiceData.2
        utterance.rate = voiceData.3
        utterance.pitchMultiplier = voiceData.4

        speechSynthesizer.speak(utterance)
    }
}

// ✅ **الكود الخاص بإدارة الأصوات**
class blindControlView: ObservableObject {
    @Published var voices: [(String, String, Float, Float, Float)] = []
    private var db = Firestore.firestore()

    init() {
        fetchAdminVoices()  // ✅ تحميل الأصوات من قاعدة البيانات عند بدء التطبيق
    }

    /// ✅ **جلب الأصوات التي أضافها الإداري فقط**
    func fetchAdminVoices() {
        db.collection("voices")
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

    /// ✅ **حفظ الصوت الذي يختاره الكفيف كصوت افتراضي في `UserDefaults`**
    func setDefaultVoice(voice: (String, String, Float, Float, Float)) {
        let userID = UUID().uuidString
        let db = Firestore.firestore()

        // ✅ حفظ الصوت الافتراضي في Firestore
        db.collection("users").document(userID).setData([
            "defaultVoice": [
                "name": voice.0,
                "language": voice.1,
                "volume": voice.2,
                "rate": voice.3,
                "pitch": voice.4
            ]
        ]) { error in
            if let error = error {
                print("❌ فشل في حفظ الصوت في Firestore: \(error.localizedDescription)")
            } else {
                print("✅ تم حفظ الصوت الافتراضي في Firestore بنجاح!")
            }
        }

        // ✅ حفظ الصوت الافتراضي محليًا في `UserDefaults`
        UserDefaults.standard.set(voice.0, forKey: "defaultVoiceName")
        UserDefaults.standard.set(voice.1, forKey: "defaultVoiceLanguage")
        UserDefaults.standard.set(voice.2, forKey: "defaultVoiceVolume")
        UserDefaults.standard.set(voice.3, forKey: "defaultVoiceRate")
        UserDefaults.standard.set(voice.4, forKey: "defaultVoicePitch")

        // ✅ إرسال إشعار بأن الصوت الافتراضي قد تغير
        NotificationCenter.default.post(name: .defaultVoiceChanged, object: nil)

        print("✅ تم حفظ الصوت الافتراضي محليًا: \(voice.0)")
    }

    /// ✅ **جلب الصوت الافتراضي المحفوظ**
    func getDefaultVoice() -> (String, String, Float, Float, Float)? {
        guard let name = UserDefaults.standard.string(forKey: "defaultVoiceName"),
              let language = UserDefaults.standard.string(forKey: "defaultVoiceLanguage") else {
            print("❌ لا يوجد صوت افتراضي محفوظ")
            return nil
        }

        let volume = UserDefaults.standard.float(forKey: "defaultVoiceVolume")
        let rate = UserDefaults.standard.float(forKey: "defaultVoiceRate")
        let pitch = UserDefaults.standard.float(forKey: "defaultVoicePitch")

        let voice = (name, language, volume, rate, pitch)
        print("✅ تم استرجاع الصوت الافتراضي: \(voice)")
        return voice
    }
}

#Preview {
    blindControl()
}
