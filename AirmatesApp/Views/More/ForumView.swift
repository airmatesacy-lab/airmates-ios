import SwiftUI

struct ForumView: View {
    @State private var viewModel = ForumViewModel()
    @State private var showNewPost = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading forum...")
            } else if viewModel.posts.isEmpty {
                EmptyStateView(icon: "bubble.left.and.bubble.right", title: "No Posts", message: "Be the first to start a discussion.")
            } else {
                List(viewModel.filteredPosts) { post in
                    NavigationLink(destination: ForumPostView(post: post)) {
                        ForumPostRow(post: post)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Forum")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewPost = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All") { viewModel.selectedCategory = nil; reload() }
                    ForEach(AppConstants.forumCategories, id: \.self) { cat in
                        Button(cat.capitalized) { viewModel.selectedCategory = cat; reload() }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showNewPost) {
            NewPostSheet(viewModel: viewModel)
        }
        .refreshable { await viewModel.fetchPosts() }
        .task { await viewModel.fetchPosts() }
    }

    func reload() { Task { await viewModel.fetchPosts() } }
}

struct ForumPostRow: View {
    let post: ForumPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if post.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Text(post.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            HStack {
                Text(post.category?.capitalized ?? "General")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.brandBlue.opacity(0.1))
                    .cornerRadius(3)
                Text(post.member?.name ?? "Member")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if post.totalReplies > 0 {
                    Label("\(post.totalReplies)", systemImage: "bubble.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let views = post.viewCount, views > 0 {
                    Label("\(views)", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ForumPostView: View {
    let post: ForumPost
    @State private var replyText = ""
    @State private var isSending = false

    var allReplies: [ForumReply] {
        post.replies ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.title).font(.title3.bold())
                        if let content = post.content {
                            LinkedText(content.strippedHTML, font: .body)
                        }
                        HStack {
                            Text(post.member?.name ?? "")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            if let date = post.createdAt {
                                Text(String(date.prefix(10)))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Section("Replies (\(post.totalReplies))") {
                    if allReplies.isEmpty {
                        Text("No replies yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(allReplies) { reply in
                            ReplyRow(reply: reply, depth: 0)
                        }
                    }
                }
            }
            .listStyle(.plain)

            // Reply input
            if !post.isLocked {
                HStack {
                    TextField("Reply...", text: $replyText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        sendReply()
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandBlue)
                        }
                    }
                    .disabled(replyText.isEmpty || isSending)
                }
                .padding()
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    @State private var replyError: String?

    func sendReply() {
        let text = replyText
        replyText = ""
        replyError = nil
        isSending = true
        Task {
            struct ReplyBody: Encodable { let content: String }
            do {
                let _: ForumReply = try await APIClient.shared.post(
                    "/api/forum/\(post.id)/replies", body: ReplyBody(content: text)
                )
                // Reply sent — user needs to pull-to-refresh to see it
            } catch {
                replyText = text // Restore text so user doesn't lose their reply
                replyError = error.localizedDescription
            }
            isSending = false
        }
    }
}

struct ReplyRow: View {
    let reply: ForumReply
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if depth > 0 {
                    Rectangle()
                        .fill(Color.brandBlue.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, CGFloat(depth * 12))
                }
                VStack(alignment: .leading, spacing: 4) {
                    LinkedText(reply.content.strippedHTML, font: .subheadline)
                    HStack {
                        Text(reply.member?.name ?? "Member")
                            .font(.caption).foregroundColor(.secondary)
                        if let date = reply.createdAt {
                            Text(String(date.prefix(10)))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Nested replies (threaded)
            if let children = reply.childReplies, !children.isEmpty {
                ForEach(children) { child in
                    ReplyRow(reply: child, depth: depth + 1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct NewPostSheet: View {
    let viewModel: ForumViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var category = "GENERAL"
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(AppConstants.forumCategories, id: \.self) { cat in
                        Text(cat.capitalized).tag(cat)
                    }
                }
                Section("Content") {
                    TextField("What's on your mind?", text: $content, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        isSubmitting = true
                        Task {
                            if await viewModel.createPost(title: title, content: content, category: category) {
                                dismiss()
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSubmitting)
                }
            }
        }
    }
}
