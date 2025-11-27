//
//  SignatureCore.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 24/10/25.
//

// SignatureCore.swift

import SwiftUI
import UIKit

// ----------------------------------------------------
// 1. PROTOCOLO DELEGATE
// ----------------------------------------------------
protocol SignatureViewDelegate: AnyObject {
    func signatureViewDidFinishDrawing(signatureView: SignatureView, image: UIImage)
}

// ----------------------------------------------------
// 2. CLASE UIKIT SUBYACENTE (El Lienzo de Dibujo)
// ----------------------------------------------------
class SignatureView: UIView {
    weak var delegate: SignatureViewDelegate?
    private var lastPoint: CGPoint?
    
    // Inicialización requerida para UIView
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Fondo blanco para que la tinta negra sea visible
        backgroundColor = .white
        
        self.isMultipleTouchEnabled = false // Evita gestos multitáctiles extraños
        self.isExclusiveTouch = true        // Intenta bloquear toques en otras vistas
            
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        self.isMultipleTouchEnabled = false
        self.isExclusiveTouch = true
    }
    
    // Mínima implementación del dibujo a mano alzada
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = touches.first?.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let safeLastPoint = lastPoint
        else {
            return
        }
        
        // Punto de dibujo
        let newPoint = touch.location(in: self)
        
        let path = UIBezierPath()
        path.move(to: safeLastPoint)
        path.addLine(to: newPoint)
        
        // Dibuja la línea en el contexto de la vista
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        UIColor.black.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let drawnImage = drawnImage {
            layer.contents = drawnImage.cgImage
            delegate?.signatureViewDidFinishDrawing(signatureView: self, image: drawnImage)
        }
        self.lastPoint = newPoint
    }
    
    // Método para limpiar el lienzo
    func clear() {
        layer.contents = nil
        lastPoint = nil
    }
}

// ----------------------------------------------------
// 3. BRIDGE DE SWIFTUI (SignatureCanvas)
// ----------------------------------------------------
struct SignatureCanvas: UIViewRepresentable {
    @Binding var signatureData: Data?

    func makeUIView(context: Context) -> SignatureView {
        let view = SignatureView()
        view.delegate = context.coordinator
        view.isMultipleTouchEnabled = false
        view.isExclusiveTouch = true
        return view
    }

    func updateUIView(_ uiView: SignatureView, context: Context) {
        if signatureData == nil {
                    uiView.clear()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, SignatureViewDelegate {
        var parent: SignatureCanvas

        init(_ parent: SignatureCanvas) {
            self.parent = parent
        }

        func signatureViewDidFinishDrawing(signatureView: SignatureView, image: UIImage) {
            // Guardamos la firma como PNG Data
            parent.signatureData = image.pngData()
        }
    }
}
