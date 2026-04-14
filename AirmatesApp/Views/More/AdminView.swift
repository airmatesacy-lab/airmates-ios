import SwiftUI

struct AdminView: View {
    @State private var viewModel = AdminViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading...")
            } else {
                List {
                    if !viewModel.pendingApprovals.isEmpty {
                        Section("Pending Approvals (\(viewModel.pendingApprovals.count))") {
                            ForEach(viewModel.pendingApprovals) { member in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(member.name).font(.subheadline.bold())
                                        Text(member.email ?? "").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("Approve") {
                                        Task { _ = await viewModel.approveMember(member) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }

                    Section("All Members (\(viewModel.allMembers.count))") {
                        ForEach(viewModel.allMembers) { member in
                            NavigationLink(destination: AdminMemberEditView(member: member, viewModel: viewModel)) {
                                HStack {
                                    Text(member.name).font(.subheadline)
                                    Spacer()
                                    Text(member.role ?? "Member")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Admin")
        .task { await viewModel.loadAdmin() }
    }
}

struct AdminMemberEditView: View {
    let member: MemberSummary
    let viewModel: AdminViewModel
    @State private var selectedRole: String

    init(member: MemberSummary, viewModel: AdminViewModel) {
        self.member = member
        self.viewModel = viewModel
        _selectedRole = State(initialValue: member.role ?? "PILOT_MEMBER")
    }

    var body: some View {
        List {
            Section("Member Info") {
                LabeledContent("Name", value: member.name)
                LabeledContent("Email", value: member.email ?? "")
                LabeledContent("Status", value: member.active == true ? "Active" : "Inactive")
            }
            Section("Role") {
                Picker("Role", selection: $selectedRole) {
                    Text("Pilot").tag("PILOT_MEMBER")
                    Text("Instructor").tag("INSTRUCTOR")
                    Text("Admin").tag("ADMIN")
                }
                .pickerStyle(.segmented)

                if selectedRole != member.role {
                    Button("Save Role Change") {
                        Task { _ = await viewModel.updateMemberRole(member.id, role: selectedRole) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(member.name)
    }
}
