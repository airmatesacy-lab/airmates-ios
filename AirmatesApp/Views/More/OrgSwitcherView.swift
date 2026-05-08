import SwiftUI

struct OrgSwitcherView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var switchingId: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let memberships = appState.currentUser?.memberships {
                ForEach(memberships) { membership in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(membership.orgName ?? "Club")
                                .font(.headline)
                            Text(membership.role ?? "Member")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if switchingId == membership.id {
                            ProgressView()
                        } else if membership.organizationId == appState.currentUser?.organizationId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.brandBlue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switchOrg(membership)
                    }
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Switch Club")
    }

    func switchOrg(_ membership: OrgMembership) {
        // Tapping the row for the already-current org is a no-op visually,
        // but a server round-trip would still happen — short-circuit here so
        // the UI matches expectations.
        guard membership.organizationId != appState.currentUser?.organizationId else { return }
        guard let targetOrgId = membership.organizationId else { return }
        switchingId = membership.id
        errorMessage = nil
        Task {
            defer { switchingId = nil }
            do {
                let response = try await AuthService.shared.refreshToken(targetOrgId: targetOrgId)
                KeychainManager.shared.saveToken(response.token)
                appState.currentUser = response.user
                dismiss()
            } catch {
                errorMessage = "Failed to switch: \(error.localizedDescription)"
            }
        }
    }
}
