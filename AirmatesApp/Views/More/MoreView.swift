import SwiftUI

struct MoreView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("Personal") {
                    NavigationLink(destination: ProfileView()) {
                        Label("Profile & Certificates", systemImage: "person.crop.circle")
                    }
                    NavigationLink(destination: CurrencyStatusView()) {
                        Label("Currency Status", systemImage: "clock.badge.checkmark")
                    }
                    NavigationLink(destination: FlightHistoryView()) {
                        Label("Flight History", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink(destination: NotificationSettingsView().environment(appState)) {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                }

                Section("Club") {
                    NavigationLink(destination: MemberDirectoryView()) {
                        Label("Members", systemImage: "person.3")
                    }
                    NavigationLink(destination: ForumView()) {
                        Label("Forum", systemImage: "bubble.left.and.bubble.right")
                    }
                    NavigationLink(destination: EventsView()) {
                        Label("Events", systemImage: "calendar.badge.plus")
                    }
                    NavigationLink(destination: DocumentsView()) {
                        Label("Documents", systemImage: "doc.text")
                    }
                }

                if appState.currentUser?.isInstructor == true || appState.currentUser?.isAdmin == true {
                    Section("Training") {
                        NavigationLink(destination: TrainingView()) {
                            Label("Training", systemImage: "graduationcap")
                        }
                    }
                }

                if appState.currentUser?.isAdmin == true {
                    Section("Admin") {
                        NavigationLink(destination: AdminView()) {
                            Label("Admin Panel", systemImage: "gearshape.2")
                        }
                    }
                }

                Section {
                    if appState.currentUser?.hasMultipleOrgs == true {
                        NavigationLink(destination: OrgSwitcherView()) {
                            Label("Switch Club", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading profile...")
            } else if let user = viewModel.user {
                List {
                    Section("Account") {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Email", value: user.email)
                        if let phone = user.phone { LabeledContent("Phone", value: phone) }
                        LabeledContent("Role", value: user.role)
                        if let tier = user.membershipTier { LabeledContent("Tier", value: tier.name) }
                    }
                    Section("Pilot Info") {
                        if let cert = user.pilotCertType { LabeledContent("Certificate", value: cert) }
                        if let ratings = user.ratings, !ratings.isEmpty {
                            LabeledContent("Ratings", value: ratings.joined(separator: ", "))
                        }
                        if let medical = user.medicalClass { LabeledContent("Medical", value: medical) }
                        if let medExp = user.medicalExpiry { LabeledContent("Medical Expires", value: String(medExp.prefix(10))) }
                        if let hours = user.totalHours { LabeledContent("Total Hours", value: String(format: "%.0f", hours)) }
                    }
                    Section("Balance") {
                        LabeledContent("Balance", value: String(format: "$%.2f", viewModel.balance))
                        LabeledContent("Hours This Month", value: String(format: "%.1f", viewModel.hoursUsedThisMonth))
                        LabeledContent("Free Hours Left", value: String(format: "%.1f", viewModel.freeHoursRemaining))
                    }
                    if let user = viewModel.user {
                        Section {
                            NavigationLink("Edit Profile") {
                                ProfileEditView(user: user, onSave: {
                                    Task { await viewModel.loadProfile() }
                                })
                            }
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) { Task { await viewModel.loadProfile() } }
            }
        }
        .navigationTitle("Profile")
        .task { await viewModel.loadProfile() }
    }
}
