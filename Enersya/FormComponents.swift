//
//  FormComponents.swift
//  Enersya
//
//  Created by Esau Gutierrez Tejeida on 01/12/25.
//

import SwiftUI
import UIKit

// MARK: - Teclado Numérico Personalizado

class NumericKeyboardView: UIView {
    weak var target: UITextField?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray5
        setupButtons()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupButtons() {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.distribution = .fillEqually
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])

        for row in keys {
            let hStack = UIStackView()
            hStack.axis = .horizontal
            hStack.distribution = .fillEqually
            hStack.spacing = 6

            for key in row {
                let btn = UIButton(type: .system)
                btn.setTitle(key, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
                btn.backgroundColor = key == "⌫" ? UIColor.systemGray3 : .white
                btn.layer.cornerRadius = 8
                btn.layer.shadowColor = UIColor.black.cgColor
                btn.layer.shadowOpacity = 0.15
                btn.layer.shadowOffset = CGSize(width: 0, height: 1)
                btn.layer.shadowRadius = 1
                btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                hStack.addArrangedSubview(btn)
            }
            vStack.addArrangedSubview(hStack)
        }
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let key = sender.titleLabel?.text, let tf = target else { return }
        if key == "⌫" {
            guard let t = tf.text, !t.isEmpty else { return }
            tf.text = String(t.dropLast())
        } else {
            if key == "." && (tf.text?.contains(".") == true) { return }
            tf.text = (tf.text ?? "") + key
        }
        tf.sendActions(for: .editingChanged)
    }
}

// MARK: - NumericTextField

struct NumericTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String

    class DecimalField: UITextField {
        let numericKeyboard = NumericKeyboardView(frame: CGRect(x: 0, y: 0, width: 0, height: 250))

        override init(frame: CGRect) {
            super.init(frame: frame)
            numericKeyboard.target = self
            inputView = numericKeyboard      // reemplaza el teclado del sistema
        }
        required init?(coder: NSCoder) { fatalError() }
    }

    func makeUIView(context: Context) -> DecimalField {
        let tf = DecimalField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: DecimalField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    class Coordinator: NSObject {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }
        @objc func textChanged(_ tf: UITextField) { text = tf.text ?? "" }
    }
}

// MARK: - FilaFaseInputView

struct FilaFaseInputView: View {
    let titulo: String
    @Binding var lectura: LecturaElectrica

    var body: some View {
        GridRow {
            Text(titulo)
                .font(.caption)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            NumericTextField(placeholder: "Amp", text: $lectura.amp)
                .frame(height: 36)

            NumericTextField(placeholder: "Volts", text: $lectura.volts)
                .frame(height: 36)

            NumericTextField(placeholder: "Hz", text: $lectura.hertz)
                .frame(height: 36)
        }
    }
}

// MARK: - HeaderTablaView

struct HeaderTablaView: View {
    var body: some View {
        GridRow {
            Text("")
            Text("Amp").font(.caption).foregroundColor(.secondary)
            Text("Volts").font(.caption).foregroundColor(.secondary)
            Text("Hz").font(.caption).foregroundColor(.secondary)
        }
    }
}
