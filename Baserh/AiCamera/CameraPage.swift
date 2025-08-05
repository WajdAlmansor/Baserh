import SwiftUI

struct CameraPage: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        NavigationView {
            ZStack {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea(.all)

                VStack {
                    Spacer().frame(height: 50)

                    HStack {
                        Spacer()

                        VStack(spacing: 20) {
                            // زر التنقل إلى LoginView
                            NavigationLink(destination: LoginView()) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "person.crop.circle.badge.minus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                }
                            }

                            // زر التنقل إلى blindControl
                            NavigationLink(destination: blindControl()) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.trailing, 20)
                    }

                    Spacer()
                    
                    Text(cameraManager.detectedObject)
                         .font(.title)
                         .bold()
                         .padding()
                         .background(Color.white.opacity(0.7))
                         .cornerRadius(12)
                         .foregroundColor(.black)

                    Button(action: {
                        cameraManager.resetDetection()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)

                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                print("📱 CameraPage ظهرت على الشاشة")
                cameraManager.startSession()
            }
            .onDisappear {
                print("📱 CameraPage اختفت من الشاشة")
                cameraManager.stopSession()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // ✅ مهم جداً لتفادي مشاكل التنقل في iPhone
    }
}
