import Foundation

@Observable
class MembersViewModel {
    var members: [MemberSummary] = []
    var searchText = ""
    var isLoading = true
    var errorMessage: String?

    var filteredMembers: [MemberSummary] {
        guard !searchText.isEmpty else { return members }
        return members.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func fetchMembers() async {
        isLoading = members.isEmpty
        errorMessage = nil

        do {
            members = try await APIClient.shared.get("/api/members")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
