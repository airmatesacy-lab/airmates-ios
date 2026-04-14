import SwiftUI

struct OrgSwitcherView: View {
    @Environment(AppState.self) private var appState

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
                        if membership.organizationId == appState.currentUser?.organizationId {
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
        }
        .navigationTitle("Switch Club")
    }

    @State private var errorMessage: String?

    func switchOrg(_ membership: OrgMembership) {
        Task {
            do {
                let response = try await AuthService.shared.refreshToken()
                KeychainManager.shared.saveToken(response.token)
                appState.currentUser = response.user
            } catch {
                errorMessage = "Failed to switch: \(error.localizedDescription)"
            }
        }
    }
}
