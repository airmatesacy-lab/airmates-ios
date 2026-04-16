import SwiftUI
import EventKit
import EventKitUI

/// SwiftUI wrapper around EKEventEditViewController so we can present Apple's
/// native event-edit sheet from a SwiftUI view. The user sees the prefilled
/// event, can change the calendar or any detail, and taps Save (or Cancel).
struct EventEditView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    let onCompletion: (EKEventEditViewAction) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.eventStore = eventStore
        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onCompletion: (EKEventEditViewAction) -> Void

        init(onCompletion: @escaping (EKEventEditViewAction) -> Void) {
            self.onCompletion = onCompletion
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            onCompletion(action)
            controller.dismiss(animated: true)
        }
    }
}
