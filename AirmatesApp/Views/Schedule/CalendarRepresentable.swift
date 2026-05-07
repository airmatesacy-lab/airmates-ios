import SwiftUI
import UIKit

private let uiBrandBlue = UIColor(red: 37 / 255, green: 99 / 255, blue: 235 / 255, alpha: 1)

struct CalendarRepresentable: UIViewRepresentable {
    @Binding var selectedDate: Date
    let bookedDates: Set<String>

    func makeUIView(context: Context) -> UICalendarView {
        let cal = UICalendarView()
        cal.calendar = Calendar.current
        cal.locale = Locale.current
        cal.tintColor = uiBrandBlue
        cal.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        cal.selectionBehavior = selection
        cal.delegate = context.coordinator

        let initialComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        selection.setSelected(initialComponents, animated: false)

        return cal
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self

        // Sync selection when changed externally (chip tap, booking form, etc.)
        let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate
        let newStr = ymd(selectedDate)
        let currentStr: String? = selection?.selectedDate.flatMap { dc in
            guard let y = dc.year, let m = dc.month, let d = dc.day else { return nil }
            return String(format: "%04d-%02d-%02d", y, m, d)
        }
        if currentStr != newStr {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            selection?.setSelected(components, animated: false)
        }

        // Reload decorations only for dates that changed
        let oldDates = context.coordinator.bookedDates
        if oldDates != bookedDates {
            context.coordinator.bookedDates = bookedDates
            let changed = oldDates.symmetricDifference(bookedDates)
            let components = changed.compactMap { str -> DateComponents? in
                guard let date = ymdToDate(str) else { return nil }
                return Calendar.current.dateComponents([.year, .month, .day], from: date)
            }
            if !components.isEmpty {
                uiView.reloadDecorations(forDateComponents: components, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Helpers

    private func ymd(_ date: Date) -> String {
        String(
            format: "%04d-%02d-%02d",
            Calendar.current.component(.year, from: date),
            Calendar.current.component(.month, from: date),
            Calendar.current.component(.day, from: date)
        )
    }

    private func ymdToDate(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: str)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarRepresentable
        var bookedDates: Set<String>

        init(parent: CalendarRepresentable) {
            self.parent = parent
            self.bookedDates = parent.bookedDates
        }

        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            guard let y = dateComponents.year,
                  let m = dateComponents.month,
                  let d = dateComponents.day
            else { return nil }
            let dateStr = String(format: "%04d-%02d-%02d", y, m, d)
            return bookedDates.contains(dateStr) ? .default(color: uiBrandBlue) : nil
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            guard let dc = dateComponents,
                  let date = Calendar.current.date(from: dc)
            else { return }
            DispatchQueue.main.async { self.parent.selectedDate = date }
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            canSelectDate dateComponents: DateComponents?
        ) -> Bool { true }
    }
}
