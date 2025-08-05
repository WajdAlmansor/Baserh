import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth

struct CameraPreview: UIViewRepresentable {
    class CameraView: UIView {
        
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }

        var session: AVCaptureSession? {
            get {
                (layer as! AVCaptureVideoPreviewLayer).session
            }
            set {
                let previewLayer = layer as! AVCaptureVideoPreviewLayer
                previewLayer.session = newValue
                previewLayer.videoGravity = .resizeAspectFill
            }
        }
    }

    var session: AVCaptureSession

    func makeUIView(context: Context) -> CameraView {
        let cameraView = CameraView()
        cameraView.session = session
        return cameraView
    }

    func updateUIView(_ uiView: CameraView, context: Context) {
        uiView.session = session
    }
}

import AVFoundation
import Vision
import Combine
import FirebaseDatabase

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session: AVCaptureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var detectionRequest: VNCoreMLRequest?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var realtimeDatabaseRef = Database.database().reference().child("defaultVoice") // 🔥 ربط الريل تايم
    private var lastDetectionTime: Date = Date(timeIntervalSince1970: 0)

    @Published var detectedObject: String = "Detecting..." {
        didSet {
            speak(detectedObject)
        }
    }
    
    private let arabicTranslations: [String: String] = [
        "wall clock" : "ساعة حائط",
        "traffic light, traffic signal, stoplight" : "إشارة مرور",
        "sandal" : "جزمه",
        "abaya" : "عبايه",
        "backpack, back pack, knapsack, packsack, rucksack, haversack" : "حقيبة",
        "mailbag, postbag" : "حقيبة",
        "carton" : "كرتون",
        "analog clock" : "ساعة حائط",
        "straweberry" : "فراوله",
        "car" : "سياره",
        "orange" : "برتقال",
        "remote control, remote" : "جهاز تحكم",
        "pineapple" : "اناناس",
        "running shoe" : "جزمة رياضية",
        "plastic bag" : "كيس بلاستيك",
        "toilet tissue, toilet paper, bathroom tissue" : "مناديل",
        "computer keyboard, keypad" : "لوحة مفاتيح",
        "mouse, computer mouse" : "فأر حاسوب",
        "desktop computer" : "كمبيوتر",
        "spotlight, spot" : "ضوء",
        "Abaya" : "عبايه",
        "cellphone" : "جوال",
        "banana" : "موز",
        "apple" : "تفاح",
        "desktop" : "مكتب",
        "website" : "موقع",
        "monitor" : "شاشة",
        "notebook, notebook computer" : "جهاز لوحي",
        "keyboard": "لوحة مفاتيح",
        "mouse": "فأرة",
        "bottle": "زجاجة",
        "chair": "كرسي",
        "table": "طاولة",
        "phone": "هاتف",
        "pen": "قلم",
        "book": "كتاب",
        "laptop, laptop computer": "حاسوب محمول",
        "tv": "تلفاز",
        "cup": "كوب",
        "lamp": "مصباح",
        "shoe": "حذاء",
        "bag": "حقيبة",
        "glasses": "نظارات",
        "watch": "ساعة",
        "fan": "مروحة",
        "door": "باب",
        "window": "نافذة",
        "plant": "نبتة",
        "remote": "جهاز تحكم",
        "pillow": "وسادة",
        "bed": "سرير",
        "mirror": "مرآة",
        "clock": "ساعة حائط",
        "towel": "منشفة",
        "toothbrush": "فرشاة أسنان",
        "soap": "صابون",
        "sink": "مغسلة",
        "barber chair" : "كرسي",
        "water bottle" : "قارورة مياه",
        "paper towel" : "مناديل",
        "rubber eraser, rubber, pencil eraser" : "قلم حبر"
    ]

    @Published var defaultVoice: (name: String, volume: Float, rate: Float, pitch: Float) = ("Default", 0.5, 0.5, 1.0)
    private var cancellable: AnyCancellable?
    private var isLocked: Bool = false

    override init() {
        super.init()
        setupSession()
        setupObjectDetection()
        loadUserDefaultVoice()
        observeDefaultVoice()
        NotificationCenter.default.addObserver(self, selector: #selector(loadUserDefaultVoice), name: .defaultVoiceChanged, object: nil)
        print("📂 جميع القيم في UserDefaults: \(UserDefaults.standard.dictionaryRepresentation())")
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Error: Unable to access the camera.")
            return
        }

        guard session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        session.commitConfiguration()
    }
    
//Ai
    private func setupObjectDetection() {
        do {
            let coreMLModel = try MobileNetV2(configuration: MLModelConfiguration()).model
            let visionModel = try VNCoreMLModel(for: coreMLModel)

            detectionRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleDetection)
            print("MobileNetV2 object detection setup complete.")
        } catch {
            print("Error loading MobileNetV2 Core ML model: \(error.localizedDescription)")
        }
    }

    private func handleDetection(request: VNRequest, error: Error?) {
        guard !isLocked,
              let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            return
        }

        DispatchQueue.main.async {
            let identifier = topResult.identifier
            
            let arabicWord = self.arabicTranslations[identifier] ?? identifier
        
            self.detectedObject = arabicWord
            self.isLocked = true
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                print("📷 تشغيل الكاميرا")
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                print("🛑 إيقاف الكاميرا")
                self.session.stopRunning()
            }
        }
    }

    func resetDetection() {
        DispatchQueue.main.async {
            self.isLocked = false
            self.detectedObject = "Detecting..."
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // ✅ معالجة فقط كل 1 ثانية
        let now = Date()
        guard now.timeIntervalSince(self.lastDetectionTime) > 1.0 else { return }
        self.lastDetectionTime = now

        guard !isLocked else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let detectionRequest = detectionRequest else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([detectionRequest])
        } catch {
            print("Error performing Vision request: \(error.localizedDescription)")
        }
    }



    /// ✅ **مراقبة الصوت الافتراضي سواء من Realtime Database أو من UserDefaults**
    func observeDefaultVoice() {
        // 🔥 المراقبة من Firebase Realtime Database
        realtimeDatabaseRef.observe(.value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                DispatchQueue.main.async {
                    let globalVoice = (
                        name: value["name"] as? String ?? "Default",
                        volume: value["volume"] as? Float ?? 0.5,
                        rate: value["rate"] as? Float ?? 0.5,
                        pitch: value["pitch"] as? Float ?? 1.0
                    )
                    
                    // ✅ إذا لم يكن لدى المستخدم صوت محلي، استخدم الصوت العام
                    if UserDefaults.standard.dictionary(forKey: "userDefaultVoice") == nil {
                        self.defaultVoice = globalVoice
                        print("✅ تم تحميل الصوت الافتراضي من Realtime Database: \(self.defaultVoice.name)")
                    }
                }
            }
        }
        
        // ✅ المراقبة من `UserDefaults` باستخدام `NotificationCenter`
        NotificationCenter.default.addObserver(self, selector: #selector(loadUserDefaultVoice), name: .defaultVoiceChanged, object: nil)

        // تحميل الصوت من UserDefaults عند بدء التطبيق
        loadUserDefaultVoice()
    }

    /// ✅ **تحميل الصوت الافتراضي المحلي إذا كان موجودًا**
    @objc private func loadUserDefaultVoice() {
        DispatchQueue.main.async {
            let name = UserDefaults.standard.string(forKey: "defaultVoiceName") ?? "Default"
            let volume = UserDefaults.standard.float(forKey: "defaultVoiceVolume")
            let rate = UserDefaults.standard.float(forKey: "defaultVoiceRate")
            let pitch = UserDefaults.standard.float(forKey: "defaultVoicePitch")
            let language = UserDefaults.standard.string(forKey: "defaultVoiceLanguage") ?? "ar-SA"

            self.defaultVoice = (name: name, volume: volume, rate: rate, pitch: pitch)

            print("✅ تم تحميل الصوت الافتراضي من UserDefaults: \(self.defaultVoice)")
        }
    }


    /// ✅ **تحديث الصوت الافتراضي محليًا فقط**
    func updateDefaultVoice(name: String, volume: Float, rate: Float, pitch: Float, language: String) {
        UserDefaults.standard.set(name, forKey: "defaultVoiceName")
        UserDefaults.standard.set(volume, forKey: "defaultVoiceVolume")
        UserDefaults.standard.set(rate, forKey: "defaultVoiceRate")
        UserDefaults.standard.set(pitch, forKey: "defaultVoicePitch")
        UserDefaults.standard.set(language, forKey: "defaultVoiceLanguage")

        NotificationCenter.default.post(name: .defaultVoiceChanged, object: nil)

        DispatchQueue.main.async {
            self.defaultVoice = (name: name, volume: volume, rate: rate, pitch: pitch)
            print("✅ تم تحديث الصوت الافتراضي محليًا إلى: \(self.defaultVoice)")
        }
    }


    /// ✅ **التحدث باستخدام الصوت الافتراضي**
//    private func speak(_ text: String) {
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
//        utterance.volume = defaultVoice.volume
//        utterance.rate = defaultVoice.rate
//        utterance.pitchMultiplier = defaultVoice.pitch
//
//        speechSynthesizer.speak(utterance)
//    }
    
    private func speak(_ text: String) {
        let language = arabicTranslations.values.contains(text) ? "ar-SA" : "en-US"

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.volume = defaultVoice.volume
        utterance.rate = defaultVoice.rate
        utterance.pitchMultiplier = defaultVoice.pitch

        speechSynthesizer.speak(utterance)
    }

}

/// ✅ **تعريف NotificationCenter Key**
extension Notification.Name {
    static let defaultVoiceChanged = Notification.Name("defaultVoiceChanged")
}

