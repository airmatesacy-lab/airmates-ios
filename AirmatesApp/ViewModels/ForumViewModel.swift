import Foundation

@Observable
class ForumViewModel {
    var posts: [ForumPost] = []
    var selectedCategory: String? = nil
    var isLoading = true
    var errorMessage: String?
    var unreadCount: Int = 0

    var filteredPosts: [ForumPost] {
        guard let category = selectedCategory else { return posts }
        return posts.filter { $0.category == category }
    }

    func fetchPosts() async {
        isLoading = posts.isEmpty
        errorMessage = nil

        do {
            var query: [URLQueryItem] = []
            if let category = selectedCategory {
                query.append(URLQueryItem(name: "category", value: category))
            }
            posts = try await APIClient.shared.get("/api/forum", query: query.isEmpty ? nil : query)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func fetchUnreadCount() async {
        struct UnreadResponse: Decodable { var count: Int }
        do {
            let response: UnreadResponse = try await APIClient.shared.get("/api/forum/unread")
            unreadCount = response.count
        } catch {
            // Non-fatal
        }
    }

    func createPost(title: String, content: String, category: String) async -> Bool {
        struct PostBody: Encodable {
            let title: String
            let content: String
            let category: String
        }
        do {
            let post: ForumPost = try await APIClient.shared.post(
                "/api/forum",
                body: PostBody(title: title, content: content, category: category)
            )
            posts.insert(post, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
