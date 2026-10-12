import SwiftUI
import PencilKit

struct RepresentationSignatureView: View {
    @ObservedObject var viewModel: ClaimViewModel
    @State private var canvasView = PKCanvasView()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sign the authorisation")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("\(viewModel.claimRequest.passengerDetails.signerFullName), your signature applies to the service agreement, the assignment of claim and the power of attorney you just accepted for flight \(viewModel.flight.displayFlightNumber) (ref. \(viewModel.pendingReference)).")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            VStack {
                SignatureCanvas(canvasView: $canvasView, onDraw: {
                    if canvasView.drawing.strokes.isEmpty {
                        viewModel.clearSignature()
                    } else {
                        // Render in light mode so the ink stays black on the white PDF; 3x for a crisp signature
                        var image = UIImage()
                        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                            image = canvasView.drawing.image(from: canvasView.bounds, scale: 3.0)
                        }
                        viewModel.saveSignature(image)
                    }
                })
                .frame(height: 200)
                .background(Color.white) // black ink on white, like paper
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
                    viewModel.clearSignature()
                }
                .font(.subheadline)
                .foregroundStyle(viewModel.signatureStrokeImage == nil ? Color.gray : PremiumTheme.goldStart)
                .disabled(viewModel.signatureStrokeImage == nil)
            }

            Text("When you submit, we record the time, your device and a fingerprint (SHA-256) of the document with your signature, and confirm your identity with Face ID or your passcode.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
        .padding()
        .onAppear {
            // The canvas is recreated when coming back to this step; ask for a fresh signature
            if canvasView.drawing.strokes.isEmpty { viewModel.clearSignature() }
        }
    }
}
