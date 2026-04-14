import Foundation

@Observable
class TrainingViewModel {
    var lessons: [StudentLesson] = []
    var progress: TrainingProgress?
    var isLoading = true
    var errorMessage: String?

    func loadTraining() async {
        isLoading = lessons.isEmpty
        errorMessage = nil

        do {
            async let lessonsReq: [StudentLesson] = APIClient.shared.get("/api/training/lessons")
            async let progressReq: TrainingProgress = APIClient.shared.get("/api/training/progress")

            lessons = try await lessonsReq
            progress = try await progressReq
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
