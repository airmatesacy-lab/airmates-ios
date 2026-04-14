import Foundation

@Observable
class AdminViewModel {
    var pendingApprovals: [MemberSummary] = []
    var allMembers: [MemberSummary] = []
    var isLoading = true
    var errorMessage: String?

    func loadAdmin() async {
        isLoading = allMembers.isEmpty
        errorMessage = nil

        do {
            allMembers = try await APIClient.shared.get("/api/members")
            pendingApprovals = allMembers.filter { $0.approved == false }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approveMember(_ member: MemberSummary) async -> Bool {
        struct ApproveBody: Encodable { let memberId: String; let approved: Bool }
        do {
            let _: MemberSummary = try await APIClient.shared.patch(
                "/api/profile",
                body: ApproveBody(memberId: member.id, approved: true)
            )
            pendingApprovals.removeAll { $0.id == member.id }
            if let idx = allMembers.firstIndex(where: { $0.id == member.id }) {
                allMembers[idx].approved = true
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateMemberRole(_ memberId: String, role: String) async -> Bool {
        struct RoleBody: Encodable { let memberId: String; let role: String }
        do {
            let _: MemberSummary = try await APIClient.shared.patch(
                "/api/profile",
                body: RoleBody(memberId: memberId, role: role)
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
