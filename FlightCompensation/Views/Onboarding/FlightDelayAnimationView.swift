import SwiftUI

struct FlightDelayAnimationView: View {
    @State private var planeOffset: CGFloat = -150
    @State private var cloudOffset: CGFloat = 200
    @State private var clockOpacity: Double = 0
    @State private var isDelayed: Bool = false
    
    var body: some View {
        ZStack {
            // Sky background
            Color.blue.opacity(0.1)
                .edgesIgnoringSafeArea(.all)
            
            // Clouds
            Image(systemName: "cloud.fill")
                .resizable()
                .foregroundStyle(.white)
                .frame(width: 80, height: 50)
                .offset(x: cloudOffset, y: -50)
            
            // Plane
            Image(systemName: "airplane")
                .resizable()
                .foregroundStyle(.blue)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(isDelayed ? -10 : 0))
                .offset(x: planeOffset)
            
            // Delay Indicator (Clock)
            if isDelayed {
                Image(systemName: "clock.fill")
                    .resizable()
                    .foregroundStyle(.orange)
                    .frame(width: 40, height: 40)
                    .offset(x: planeOffset + 40, y: -30)
                    .transition(.scale)
            }
        }
        .frame(height: 200)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Reset states
        planeOffset = -150
        cloudOffset = 200
        isDelayed = false
        
        // Move clouds
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            cloudOffset = -200
        }
        
        // Move plane to center
        withAnimation(.easeInOut(duration: 2)) {
            planeOffset = 0
        }
        
        // Simulate delay event
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isDelayed = true
            }
            
            // Shake plane slightly
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3)) {
                planeOffset += 5
            }
        }
    }
}

#Preview {
    FlightDelayAnimationView()
}
