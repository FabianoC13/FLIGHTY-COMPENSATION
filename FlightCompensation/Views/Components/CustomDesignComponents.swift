import SwiftUI

// MARK: - MIIDNIGHT LUXURY THEME
struct PremiumTheme {
    // Colors
    static let midnightBlueStart = Color(hex: "0F172A") // Deep Slate Blue
    static let midnightBlueEnd = Color(hex: "020617")   // Almost Black
    static let electricBlue = Color(hex: "3B82F6")      // Bright Blue Action
    static let goldStart = Color(hex: "F59E0B")
    static let goldEnd = Color(hex: "D97706")
    
    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [midnightBlueStart, midnightBlueEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [goldStart, goldEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - GLASSMORPHISM MODIFIERS

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.1) // Subtle blur
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - BACKGROUND
struct WorldMapBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base
            PremiumTheme.backgroundGradient.ignoresSafeArea()
            
            // Animated Gradient Orbs
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(PremiumTheme.electricBlue.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animate ? -50 : 50, y: animate ? -100 : 0)
                    
                    Circle()
                        .fill(PremiumTheme.goldStart.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: animate ? 100 : -50, y: animate ? 200 : 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Grid Overlay
            VStack(spacing: 40) {
                ForEach(0..<20) { _ in
                    Divider().background(Color.white.opacity(0.03))
                }
            }
            .ignoresSafeArea()
            .rotationEffect(.degrees(-15))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - GLOW TEXT FIELD
struct PremiumTextField: View {
    var placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            }
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .focused($isFocused)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
        }
        .frame(height: 56)
        .glassCard(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? PremiumTheme.electricBlue.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .shadow(color: isFocused ? PremiumTheme.electricBlue.opacity(0.3) : .clear, radius: 8)
        .animation(.easeInOut, value: isFocused)
    }
}

// MARK: - NEO BUTTON
struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    if isDisabled {
                        Color.gray.opacity(0.3)
                    } else {
                        gradient
                    }
                }
            )
            .foregroundColor(.white.opacity(isDisabled ? 0.6 : 1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isDisabled ? .clear : Color.blue.opacity(0.3), radius: 15, y: 5)
        }
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 1.0 : 1.0) // Placeholder for press animation
        .animation(.spring(response: 0.3), value: isDisabled)
    }
}


