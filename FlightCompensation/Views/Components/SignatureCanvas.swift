import SwiftUI
import PencilKit

struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var onDraw: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Use fixed black color (non-adaptive) to ensure visibility on white paper background
        canvasView.tool = PKInkingTool(.pen, color: UIColor(red: 0, green: 0, blue: 0, alpha: 1), width: 3)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear // Let SwiftUI background show through
        canvasView.overrideUserInterfaceStyle = .light // Force light mode (Paper look)
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignatureCanvas
        
        init(_ parent: SignatureCanvas) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Debounce or just call directly
            parent.onDraw()
        }
    }
}
