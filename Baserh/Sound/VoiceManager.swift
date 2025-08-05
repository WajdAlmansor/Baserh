
import SwiftUI
import AVFoundation

struct VoiceControlView: View {
    @ObservedObject var voiceManager: VoiceManager
    @Environment(\.presentationMode) var presentationMode

    @State var selectedVoiceName: String = ""
    @State var volume: Double = 0.5
    @State var speechRate: Double = 0.5
    @State var pitch: Double = 1.0
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var isEditingExistingVoice: Bool
    
    init(voiceManager: VoiceManager, selectedVoiceName: String = "", volume: Double = 0.5, speechRate: Double = 0.5, pitch: Double = 1.0) {
        self.voiceManager = voiceManager
        self._selectedVoiceName = State(initialValue: selectedVoiceName)
        self._volume = State(initialValue: volume)
        self._speechRate = State(initialValue: speechRate)
        self._pitch = State(initialValue: pitch)
        self.isEditingExistingVoice = !selectedVoiceName.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // الخلفية الخضراء، تمتد حتى Safe Area
            Color(red: 0xDE / 255, green: 0xEB / 255, blue: 0xBB / 255)
                .edgesIgnoringSafeArea(.top)
            
            VStack {
                Spacer(minLength: UIApplication.shared.windows.first?.safeAreaInsets.top)
                
                Text(isEditingExistingVoice ? "تعديل الصوت" : "مرحبا بك إلى شاشة التحكم ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 20) // وضع الجملة في الأعلى على الخلفية الخضراء
                
                RoundedRectangle(cornerRadius: 90)
                    .fill(Color.white)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.75) // تقليل الحجم وإنزاله للأسفل
                    .overlay(
                        VStack {
                            TextField("أدخل اسم الصوت", text: $selectedVoiceName)
                                .padding()
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25) // تعيين الحواف الدائرية
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.orange, lineWidth: 1) // تحديد لون الحدود وسمكها
                                )
                                .padding(.horizontal, 40)
                                .padding(.top, 30)
                                .disabled(isEditingExistingVoice)

                            
                            Spacer().frame(height: 30)

                            SliderView(title: "مستوى الصوت", value: $volume, range: 0...1, onRelease: speak)
                                .padding(.bottom, 40)
                            SliderView(title: "سرعة النطق", value: $speechRate, range: 0.3...1.0, onRelease: speak)
                                .padding(.bottom, 40)
                            SliderView(title: "درجة الصوت", value: $pitch, range: 0.5...2.0, onRelease: speak)
                                .padding(.bottom, 80)
                            
                            Button(action: saveVoice) {
                                Text(isEditingExistingVoice ? "حفظ التعديلات" : "إضافة صوت")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(20)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding()
                    )
                    .offset(y: 40) // إنزال الجزء الأبيض أكثر
            }
        }
    }
    
    func speak() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: "مرحباً! هذا هو الصوت المختار.")

        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.volume = Float(volume)
        utterance.rate = Float(speechRate)
        utterance.pitchMultiplier = Float(pitch)

        speechSynthesizer.speak(utterance)
    }

    func saveVoice() {
        if isEditingExistingVoice {
            // ✅ تحديث الصوت إذا كان موجودًا مسبقًا
            voiceManager.updateVoice(name: selectedVoiceName, volume: Float(volume), rate: Float(speechRate), pitch: Float(pitch))
        } else {
            // ✅ إضافة صوت جديد فقط إذا كان الاسم غير فارغ
            guard !selectedVoiceName.isEmpty else { return }
            voiceManager.addVoice(name: selectedVoiceName, language: "ar-SA", volume: Float(volume), rate: Float(speechRate), pitch: Float(pitch))
        }
        
        speak() // 🔹 تشغيل الصوت بعد الحفظ مباشرة
        presentationMode.wrappedValue.dismiss() // 🔹 إغلاق الشاشة والعودة إلى `ContentView`
    }

}

struct SliderView: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onRelease: () -> Void

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Slider(value: $value, in: range, onEditingChanged: { editing in
                if !editing { onRelease() }
            })
            .accentColor(.orange)
        }
        .padding(.horizontal)
    }
}

#Preview {
    VoiceControlView(voiceManager: VoiceManager())
}
