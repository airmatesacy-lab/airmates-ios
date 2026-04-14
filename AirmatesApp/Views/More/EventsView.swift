import SwiftUI

struct EventsView: View {
    @State private var viewModel = EventsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading events...")
            } else if viewModel.events.isEmpty {
                EmptyStateView(icon: "calendar.badge.plus", title: "No Events", message: "No upcoming events.")
            } else {
                List(viewModel.events) { event in
                    NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title).font(.headline)
                            if let start = event.startDate {
                                Text(String(start.prefix(10)))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            if let location = event.location {
                                Label(location, systemImage: "mappin")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Events")
        .task { await viewModel.fetchEvents() }
    }
}

struct EventDetailView: View {
    let event: ClubEvent
    let viewModel: EventsViewModel

    var body: some View {
        List {
            Section {
                Text(event.title).font(.title3.bold())
                if let desc = event.description { Text(desc) }
            }
            Section("Details") {
                if let start = event.startDate { LabeledContent("Starts", value: String(start.prefix(16))) }
                if let end = event.endDate { LabeledContent("Ends", value: String(end.prefix(16))) }
                if let location = event.location { LabeledContent("Location", value: location) }
                if let category = event.category { LabeledContent("Category", value: category) }
            }
            if let count = event.rsvpCount {
                Section("Attendees") {
                    LabeledContent("RSVPs", value: "\(count)")
                }
            }
            Section {
                HStack(spacing: 12) {
                    Button("Attending") { rsvp("ATTENDING") }
                        .buttonStyle(.borderedProminent)
                    Button("Maybe") { rsvp("MAYBE") }
                        .buttonStyle(.bordered)
                    Button("Decline") { rsvp("DECLINED") }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
        }
        .navigationTitle("Event")
    }

    func rsvp(_ status: String) {
        Task { _ = await viewModel.rsvp(eventId: event.id, status: status) }
    }
}
