import SwiftUI

struct DocumentsView: View {
    @State private var documents: [ClubDocument] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading documents...")
            } else if let error = errorMessage {
                ErrorView(message: error) { Task { await fetchDocuments() } }
            } else if documents.isEmpty {
                EmptyStateView(icon: "doc.text", title: "No Documents", message: "Club documents will appear here.")
            } else {
                List(documents) { doc in
                    if let urlStr = doc.fileUrl, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.brandBlue)
                                VStack(alignment: .leading) {
                                    Text(doc.name).font(.subheadline.bold())
                                    if let category = doc.category {
                                        Text(category).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "doc.fill").foregroundColor(.gray)
                            Text(doc.name).font(.subheadline)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Documents")
        .task { await fetchDocuments() }
    }

    func fetchDocuments() async {
        do {
            documents = try await APIClient.shared.get("/api/documents")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
