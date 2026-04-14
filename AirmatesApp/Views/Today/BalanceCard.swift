import SwiftUI

struct BalanceCard: View {
    let balance: Double
    let tier: MembershipTier?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.brandBlue)
                Text("Account")
                    .font(.headline)
                Spacer()
            }

            HStack {
                let displayBal = abs(balance) < 0.01 ? 0.0 : balance
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "$%.2f", abs(displayBal)))
                        .font(.title2.bold())
                        .foregroundColor(displayBal > 0 ? .red : displayBal < 0 ? .green : .primary)
                    Text(displayBal > 0 ? "Balance due — tap to pay" : displayBal < 0 ? "Credit" : "Paid up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let tier {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(tier.name)
                            .font(.subheadline.bold())
                        if tier.freeHoursPerMonth > 0 {
                            Text("\(String(format: "%.0f", tier.freeHoursPerMonth))hr/mo included")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
