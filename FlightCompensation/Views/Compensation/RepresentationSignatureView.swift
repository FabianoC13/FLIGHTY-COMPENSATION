import SwiftUI
import PencilKit

struct RepresentationSignatureView: View {
    @ObservedObject var viewModel: ClaimViewModel
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Master Authorization")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("By signing below, you authorize us to represent you legally and process the claim on your behalf.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            VStack {
                SignatureCanvas(canvasView: $canvasView, onDraw: {
                    // Use higher scale (3.0) for retina quality signature
                    viewModel.saveSignature(canvasView.drawing.image(from: canvasView.bounds, scale: 3.0))
                })
                .frame(height: 200)
                .background(Color.white) // Canvas needs white background for drawing contrast usually, or we can invert colors. AESA likely expects black on white.
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PremiumTheme.electricBlue.opacity(0.5), lineWidth: 2)
                )
            }
            .glassCard(cornerRadius: 16)
            .padding(4)
            
            HStack {
                Text("Sign within the box")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                Button("Clear Signature") {
                    canvasView.drawing = PKDrawing()
                    viewModel.signatureStrokeImage = nil // Invalidate
                    viewModel.validateCurrentStep()
                }
                .font(.subheadline)
                .foregroundStyle(viewModel.signatureStrokeImage == nil ? Color.gray : PremiumTheme.goldStart)
                .disabled(viewModel.signatureStrokeImage == nil)
            }
            
            Spacer()
        }
        .padding()
    }
}


