import SwiftUI
import Firebase
import FirebaseFirestore

struct Sound: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var pitch: Float
    var rate: Float
    var volume: Float
    var isDefault: Bool
}

class SoundViewModel: ObservableObject {
    @Published var sounds: [Sound] = []
    @Published var selectedSound: Sound?
    private var db = Firestore.firestore()
    
    // 🟢 جلب جميع الأصوات من Firestore
    func fetchSounds() {
        db.collection("sounds").getDocuments { querySnapshot, error in
            if let error = error {
                print("❌ Error fetching sounds: \(error)")
                return
            }
            
            self.sounds = querySnapshot?.documents.compactMap { doc -> Sound? in
                try? doc.data(as: Sound.self)
            } ?? []
        }
    }
    
    // 🟢 تعيين صوت كافتراضي
    func setAsDefault(adminID: String) {
        guard let selectedSound = selectedSound, let soundID = selectedSound.id else {
            print("⚠️ No sound selected or missing sound ID")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        // 🟢 1️⃣ تحديث كل الأصوات إلى `isDefault = false`
        db.collection("sounds").getDocuments { querySnapshot, error in
            if let error = error {
                print("❌ Error fetching sounds: \(error)")
                return
            }
            
            for document in querySnapshot?.documents ?? [] {
                dispatchGroup.enter()
                document.reference.updateData(["isDefault": false]) { error in
                    if let error = error {
                        print("❌ Error updating sound: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 🟢 2️⃣ بعد التأكد من تحديث كل الأصوات، يتم تعيين الصوت المختار كافتراضي
            dispatchGroup.notify(queue: .main) {
                self.db.collection("sounds").document(soundID).updateData([
                    "isDefault": true
                ]) { error in
                    if let error = error {
                        print("❌ Error setting default sound: \(error)")
                    } else {
                        print("✅ تم تعيين الصوت الافتراضي بنجاح: \(selectedSound.name)")
                        
                        // 🟢 3️⃣ تسجيل التحديث في `adminSounds`
                        let adminSoundData: [String: Any] = [
                            "adminID": adminID,
                            "soundID": soundID,
                            "modifiedDate": Timestamp(date: Date())
                        ]
                        
                        self.db.collection("adminSounds").addDocument(data: adminSoundData) { error in
                            if let error = error {
                                print("❌ Error saving adminSound record: \(error)")
                            } else {
                                print("✅ تم حفظ العلاقة بين الأدمن والصوت المختار.")
                            }
                        }
                    }
                }
            }
        }
    }
}
