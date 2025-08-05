# 👁️‍🗨️ Baserh

**Baserh** (Arabic for "insight") is designed to empower visually impaired users by helping them recognize surrounding objects through real-time camera analysis and spoken feedback.  
Built with SwiftUI and Apple's CoreML framework, the app combines AI and accessibility into one meaningful tool.

---

## 🧠 What It Does

- Uses the iPhone camera to detect everyday objects
- Recognizes objects using **ResNet50**, a pre-trained CoreML model from Apple
- Speaks the detected object name using **AVSpeechSynthesizer**
- Provides a clean, voice-controlled interface
- Includes a screen for customizing the voice:
  - Change speech rate, pitch, and volume
  - Add and preview different voice styles
- Designed for simplicity, clarity, and real-time responsiveness

---

## 🛠️ Technologies Used

- `SwiftUI` for the user interface
- `AVFoundation` for camera access and speech synthesis
- `CoreML` + `Vision` for object detection (ResNet50 model)
- `Firebase` (for future features / data tracking)
- `@StateObject`, `@AppStorage`, and Combine for app state management

---

## 🔁 How It Works

1. The camera feed is displayed using `AVCaptureSession`.
2. Each frame is passed to Vision for classification using the `VNCoreMLRequest`.
3. If an object is detected, the name is spoken aloud.
4. The user can reset the detection or adjust voice settings.

---

## 📱 Screens

| Camera View | Voice Settings |
|-------------|----------------|
| Displays live camera with detection button | Allows user to change voice pitch, rate, and volume |
| Speaks the detected object aloud | Includes option to add new voice presets |

---

## 📦 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/WajdAlmansor/Baserh.git
   cd Baserh
   open Baserh.xcodeproj
2. Open the project in Xcode.
3. Run the app on a real device (camera access is required).
4. Ensure microphone and camera permissions are enabled.
