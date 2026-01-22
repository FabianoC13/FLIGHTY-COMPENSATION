import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Flighty")
                    .font(.custom("HelveticaNeue-Bold", size: 36))
                    .foregroundStyle(Color(red: 20/255, green: 40/255, blue: 80/255))
                    .padding(.top, 10)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
