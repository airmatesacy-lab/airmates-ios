import SwiftUI

struct TachPadView: View {
    @Binding var value: String
    var label: String = "Tach"
    var prefilledValue: Double?

    private let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "del"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Display
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value.isEmpty ? "0.0" : value)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            // Number pad
            VStack(spacing: 8) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { btn in
                            TachButton(label: btn) {
                                handleTap(btn)
                            }
                        }
                    }
                }
            }

            // Clear button
            Button("Clear") {
                value = ""
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .onAppear {
            if let prefilled = prefilledValue, value.isEmpty {
                value = String(format: "%.1f", prefilled)
            }
        }
    }

    private func handleTap(_ button: String) {
        switch button {
        case "del":
            if !value.isEmpty {
                value.removeLast()
            }
        case ".":
            if !value.contains(".") {
                value += value.isEmpty ? "0." : "."
            }
        default:
            // Limit to 7 characters (99999.9)
            if value.count < 7 {
                // Limit decimal places to 1
                if let dotIndex = value.firstIndex(of: ".") {
                    let decimals = value[value.index(after: dotIndex)...]
                    if decimals.count >= 1 { return }
                }
                value += button
            }
        }
    }
}

struct TachButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if label == "del" {
                    Image(systemName: "delete.left")
                        .font(.title3)
                } else {
                    Text(label)
                        .font(.title2.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(label == "del" ? Color(.systemGray5) : Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(10)
        }
    }
}
