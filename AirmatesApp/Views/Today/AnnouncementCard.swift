import SwiftUI

struct AnnouncementCard: View {
    let announcement: Announcement
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: announcement.isUrgent ? "exclamationmark.triangle.fill" : "megaphone.fill")
                    .foregroundColor(announcement.isUrgent ? .red : .orange)
                Text(announcement.title.strippedHTML)
                    .font(.headline)
                Spacer()
                if announcement.requireConfirmation != true {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(announcement.body.strippedHTML)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if let docUrl = announcement.documentUrl,
               let docName = announcement.documentName,
               let url = URL(string: docUrl) {
                Link(destination: url) {
                    Label(docName, systemImage: "doc.fill")
                        .font(.caption)
                }
            }

            if let createdAt = announcement.createdAt {
                Text(createdAt)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if announcement.requireConfirmation == true {
                Button("Acknowledge") { onDismiss() }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.brandBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(announcement.isUrgent ? Color.red.opacity(0.3) : Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
