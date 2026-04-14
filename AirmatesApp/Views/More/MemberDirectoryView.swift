import SwiftUI

struct MemberDirectoryView: View {
    @State private var viewModel = MembersViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading members...")
            } else {
                List(viewModel.filteredMembers) { member in
                    NavigationLink(destination: MemberProfileView(member: member)) {
                        HStack {
                            Circle()
                                .fill(member.isAdmin ? Color.red.opacity(0.2) : member.isInstructor ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(member.name.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(member.isAdmin ? .red : member.isInstructor ? .blue : .gray)
                                )
                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.subheadline.bold())
                                HStack(spacing: 4) {
                                    Text(member.role ?? "Member")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let tier = member.membershipTier {
                                        Text("\u{2022} \(tier.name ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $viewModel.searchText, prompt: "Search members")
            }
        }
        .navigationTitle("Members")
        .task { await viewModel.fetchMembers() }
    }
}

struct MemberProfileView: View {
    let member: MemberSummary

    var body: some View {
        List {
            Section("Info") {
                LabeledContent("Name", value: member.name)
                if let email = member.email { LabeledContent("Email", value: email) }
                if let phone = member.phone { LabeledContent("Phone", value: phone) }
                LabeledContent("Role", value: member.role ?? "Member")
            }
            if let cert = member.pilotCertType {
                Section("Pilot") {
                    LabeledContent("Certificate", value: cert)
                    if let ratings = member.ratings, !ratings.isEmpty {
                        LabeledContent("Ratings", value: ratings.joined(separator: ", "))
                    }
                    if let hours = member.totalHours {
                        LabeledContent("Total Hours", value: String(format: "%.0f", hours))
                    }
                }
            }
        }
        .navigationTitle(member.name)
    }
}
