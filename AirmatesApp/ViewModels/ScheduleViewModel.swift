import Foundation

@Observable
class ScheduleViewModel {
    var bookings: [Booking] = []
    var monthBookings: [Booking] = [] // All bookings for the visible month (for dots)
    var selectedDate = Date()
    var isLoading = true
    var errorMessage: String?

    // Dates that have bookings (for calendar dots)
    var bookedDates: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(monthBookings.compactMap { booking in
            if let date = DateFormatter.apiDate.date(from: booking.startDate) {
                return formatter.string(from: date)
            }
            return nil
        })
    }

    // Sorted dates that have bookings (for date chips)
    var sortedBookedDates: [String] {
        bookedDates.sorted()
    }

    // Count bookings for a specific date
    func bookingCount(for dateStr: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return monthBookings.filter { booking in
            if let date = DateFormatter.apiDate.date(from: booking.startDate) {
                return formatter.string(from: date) == dateStr
            }
            return false
        }.count
    }

    // Bookings for the selected day only
    var selectedDayBookings: [Booking] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let selectedStr = formatter.string(from: selectedDate)
        return monthBookings.filter { booking in
            if let date = DateFormatter.apiDate.date(from: booking.startDate) {
                return formatter.string(from: date) == selectedStr
            }
            return false
        }
    }

    func fetchBookings() async {
        isLoading = bookings.isEmpty
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        do {
            bookings = try await APIClient.shared.get("/api/bookings", query: [
                URLQueryItem(name: "date", value: dateStr),
            ])
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func fetchMonthBookings() async {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)
        else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        do {
            monthBookings = try await APIClient.shared.get("/api/bookings", query: [
                URLQueryItem(name: "from", value: formatter.string(from: monthStart)),
                URLQueryItem(name: "to", value: formatter.string(from: monthEnd)),
            ])
        } catch {
            // Silent fail — dots are a nice-to-have
        }
    }

    func cancelBooking(_ booking: Booking) async {
        struct DeleteResponse: Decodable { var deleted: Bool }
        do {
            let _: DeleteResponse = try await APIClient.shared.delete("/api/bookings", query: [
                URLQueryItem(name: "id", value: booking.id),
            ])
            bookings.removeAll { $0.id == booking.id }
            monthBookings.removeAll { $0.id == booking.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
