import SwiftUI

struct NoticeAckSheet: View {
    let notices: [AircraftNotice]
    let viewModel: FlyViewModel
    let onAllAcknowledged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var signedName = ""
    @State private var isSubmitting = false

    var currentNotice: AircraftNotice? {
        guard currentIndex < notices.count else { return nil }
        return notices[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let notice = currentNotice {
                    // Progress
                    Text("Notice \(currentIndex + 1) of \(notices.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Priority badge
                            HStack {
                                Image(systemName: notice.isCritical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(notice.isCritical ? .red : .orange)
                                Text(notice.priority)
                                    .font(.caption.bold())
                                    .foregroundColor(notice.isCritical ? .red : .orange)
                                Spacer()
                            }

                            Text(notice.title)
                                .font(.title3.bold())

                            Text(notice.body)
                                .font(.body)
                                .foregroundColor(.secondary)

                            // Document link
                            if let docUrl = notice.documentUrl, let url = URL(string: docUrl) {
                                Link(destination: url) {
                                    Label(notice.documentName ?? "View Document", systemImage: "doc.fill")
                                        .font(.subheadline)
                                }
                            }

                            // Video link
                            if let videoUrl = notice.videoUrl, let url = URL(string: videoUrl) {
                                Link(destination: url) {
                                    Label("Watch Video", systemImage: "play.circle.fill")
                                        .font(.subheadline)
                                }
                            }

                            Divider()

                            // Signature if required
                            if notice.requireSignature == true {
                                SignaturePadView(signedName: $signedName)
                            }
                        }
                        .padding()
                    }

                    // Acknowledge button
                    Button {
                        acknowledgeAndAdvance()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(currentIndex < notices.count - 1 ? "Acknowledge & Next" : "Acknowledge & Continue")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAcknowledge ? Color.brandBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canAcknowledge || isSubmitting)
                    .padding(.horizontal)
                } else {
                    // All done
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("All notices acknowledged")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Aircraft Notices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    var canAcknowledge: Bool {
        guard let notice = currentNotice else { return false }
        if notice.requireSignature == true {
            return !signedName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    func acknowledgeAndAdvance() {
        guard let notice = currentNotice else { return }
        isSubmitting = true
        Task {
            let success = await viewModel.acknowledgeNotice(
                notice,
                signedName: notice.requireSignature == true ? signedName : nil
            )
            isSubmitting = false
            if success {
                signedName = ""
                if currentIndex < notices.count - 1 {
                    currentIndex += 1
                } else {
                    onAllAcknowledged()
                    dismiss()
                }
            }
        }
    }
}
