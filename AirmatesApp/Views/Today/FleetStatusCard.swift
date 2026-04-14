import SwiftUI

struct FleetStatusCard: View {
    let summary: TodayViewModel.FleetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.brandBlue)
                Text("Fleet")
                    .font(.headline)
                Spacer()
                Text("\(summary.total) aircraft")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                FleetStatusPill(count: summary.available, label: "Available", color: .green)
                FleetStatusPill(count: summary.inFlight, label: "Flying", color: .blue)
                FleetStatusPill(count: summary.maintenance, label: "Maint.", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

struct FleetStatusPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
