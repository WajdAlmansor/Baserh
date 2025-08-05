import SwiftUI

struct Splash: View {
    @State private var isVisible = false // ✅ متغير للتحكم في ظهور العناصر تدريجيًا

    var body: some View {
        ZStack {
            Color(red: 222 / 255, green: 235 / 255, blue: 187 / 255)
                .ignoresSafeArea()
            
            VStack {
                Image("eyeImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // ✅ ضبط حجم الصورة
                    .opacity(isVisible ? 1 : 0) // ✅ تطبيق تأثير التلاشي
                    .animation(.easeIn(duration: 1.5).delay(0.5), value: isVisible) // ✅ **إضافة تأخير لتزامنها مع النص**
                
                Text("بصيرة")
                    .font(.custom("Kufi Standard GK", size: 36)) // ✅ تعيين الخط
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0x4F / 255, green: 0x4F / 255, blue: 0x4F / 255))
                    .opacity(isVisible ? 1 : 0) // ✅ تطبيق تأثير التلاشي
                    .animation(.easeIn(duration: 2.0).delay(0.5), value: isVisible) // ✅ تأخير النص بنفس التأخير للصورة
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // ✅ تأخير تفعيل الأنيميشن
                isVisible = true
            }
        }
    }
}

#Preview {
    Splash()
}
