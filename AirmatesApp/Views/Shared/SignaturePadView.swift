import SwiftUI

struct SignaturePadView: View {
    @Binding var signedName: String
    var label: String = "Type your full legal name to sign"
    var placeholder: String = "Full Legal Name"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $signedName)
                .font(.title3)
                .italic()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(signedName.isEmpty ? Color.gray.opacity(0.3) : Color.brandBlue, lineWidth: 1)
                )

            if !signedName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Signed as: \(signedName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
