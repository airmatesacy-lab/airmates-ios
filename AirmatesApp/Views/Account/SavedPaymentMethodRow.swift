import SwiftUI

/// A tappable row displaying a saved Stripe payment method (card or bank)
/// with a radio-style selection indicator.
struct SavedPaymentMethodRow: View {
    let method: SavedPaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    private var iconName: String {
        if method.isCard { return "creditcard.fill" }
        if method.isBank { return "building.columns.fill" }
        return "questionmark.circle"
    }

    private var iconColor: Color {
        method.isBank ? .brandGreen : .brandBlue
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    if let exp = expirationLabel {
                        Text(exp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if method.isBank, let type = method.accountType {
                        Text(type.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if method.isDefault {
                    Text("DEFAULT")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brandBlue.opacity(0.1))
                        .foregroundColor(.brandBlue)
                        .cornerRadius(3)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .brandBlue : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.brandBlue.opacity(0.05) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.brandBlue : Color(.separator), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var expirationLabel: String? {
        guard method.isCard, let month = method.expMonth, let year = method.expYear else {
            return nil
        }
        return String(format: "Expires %02d/%d", month, year)
    }
}
