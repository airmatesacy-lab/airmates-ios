import SwiftUI

struct AircraftNoticesView: View {
    let aircraftId: String
    @State private var notices: [AircraftNotice] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading notices...")
            } else if notices.isEmpty {
                EmptyStateView(icon: "checkmark.shield", title: "No Notices", message: "No active notices for this aircraft.")
            } else {
                List(notices) { notice in
                    NoticeRow(notice: notice)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Notices")
        .task { await fetchNotices() }
    }

    private func fetchNotices() async {
        isLoading = true
        do {
            notices = try await APIClient.shared.get("/api/aircraft/notices", query: [
                URLQueryItem(name: "aircraftId", value: aircraftId),
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct NoticeRow: View {
    let notice: AircraftNotice

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: notice.isCritical ? "exclamationmark.triangle.fill" : notice.isWarning ? "exclamationmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(notice.isCritical ? .red : notice.isWarning ? .orange : .blue)
                Text(notice.title)
                    .font(.headline)
                Spacer()
                if notice.acked == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            Text(notice.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if notice.blockCheckout == true {
                    Label("Blocks checkout", systemImage: "xmark.circle")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                if notice.blockBooking == true {
                    Label("Blocks booking", systemImage: "xmark.circle")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                if notice.requireSignature == true {
                    Label("Signature required", systemImage: "signature")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
