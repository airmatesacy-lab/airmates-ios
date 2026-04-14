import SwiftUI

struct TrainingView: View {
    @State private var viewModel = TrainingViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading training...")
            } else {
                List {
                    if let progress = viewModel.progress {
                        Section("Progress") {
                            if let completed = progress.completedObjectives, let total = progress.totalObjectives, total > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: Double(completed), total: Double(total))
                                        .tint(.brandBlue)
                                    Text("\(completed)/\(total) objectives completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if let hours = progress.totalHours {
                                LabeledContent("Total Training Hours", value: String(format: "%.1f", hours))
                            }
                        }

                        if let endorsements = progress.endorsements, !endorsements.isEmpty {
                            Section("Endorsements") {
                                ForEach(endorsements) { endorsement in
                                    VStack(alignment: .leading) {
                                        Text(endorsement.type ?? "Endorsement")
                                            .font(.subheadline.bold())
                                        if let date = endorsement.dateIssued {
                                            Text(String(date.prefix(10)))
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section("Recent Lessons") {
                        ForEach(viewModel.lessons.prefix(20)) { lesson in
                            NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                                HStack {
                                    Circle()
                                        .fill(lesson.isSatisfactory ? Color.green : Color.orange)
                                        .frame(width: 8)
                                    VStack(alignment: .leading) {
                                        Text(lesson.date?.prefix(10) ?? "Lesson")
                                            .font(.subheadline.bold())
                                        Text(lesson.grade ?? "Pending")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if let hours = lesson.durationHours {
                                        Text(String(format: "%.1fh", hours))
                                            .font(.caption.monospaced())
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Training")
        .task { await viewModel.loadTraining() }
    }
}

struct LessonDetailView: View {
    let lesson: StudentLesson

    var body: some View {
        List {
            Section("Lesson Info") {
                if let date = lesson.date { LabeledContent("Date", value: String(date.prefix(10))) }
                if let grade = lesson.grade { LabeledContent("Grade", value: grade) }
                if let hours = lesson.durationHours { LabeledContent("Duration", value: String(format: "%.1f hours", hours)) }
            }
            if let instructor = lesson.instructor {
                Section("Instructor") {
                    LabeledContent("Name", value: instructor.name)
                }
            }
            if let notes = lesson.notes, !notes.isEmpty {
                Section("Notes") { Text(notes) }
            }
            if let preBrief = lesson.preBriefNotes, !preBrief.isEmpty {
                Section("Pre-Brief") { Text(preBrief) }
            }
            if let postBrief = lesson.postBriefNotes, !postBrief.isEmpty {
                Section("Post-Brief") { Text(postBrief) }
            }
            if let objectives = lesson.completedObjectives, !objectives.isEmpty {
                Section("Completed Objectives") {
                    ForEach(objectives, id: \.self) { obj in
                        Label(obj, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Lesson Details")
    }
}
