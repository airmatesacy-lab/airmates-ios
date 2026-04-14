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
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "$%.2f", abs(balance)))
                        .font(.title2.bold())
                        .foregroundColor(balance > 0 ? .red : balance < 0 ? .green : .primary)
                    Text(balance > 0 ? "Balance due — tap to pay" : balance < 0 ? "Credit" : "Paid up")
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
