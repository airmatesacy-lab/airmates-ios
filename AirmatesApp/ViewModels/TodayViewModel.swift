import Foundation

@Observable
class TodayViewModel {
    var weather: WeatherData?
    var announcements: [Announcement] = []
    var nextBooking: Booking?
    var activeCheckout: Checkout?
    var fleetSummary: FleetSummary?
    var dashboardData: DashboardData?
    var personalBalance: Double = 0
    var isLoading = true
    var errorMessage: String?

    struct FleetSummary {
        var available: Int = 0
        var inFlight: Int = 0
        var maintenance: Int = 0
        var total: Int = 0
    }

    var userId: String?

    func loadAll() async {
        isLoading = dashboardData == nil
        errorMessage = nil
        var hasError = false

        // Fetch each independently so one failure doesn't kill everything
        do {
            dashboardData = try await APIClient.shared.get("/api/dashboard")
            nextBooking = dashboardData?.myUpcomingBookings?.first
            // Dashboard may include announcements
            if let dashAnnouncements = dashboardData?.announcements {
                announcements = dashAnnouncements
            }
        } catch {
            hasError = true
        }

        do {
            weather = try await APIClient.shared.get("/api/weather")
            CacheService.shared.save(weather, key: CacheService.weatherKey)
        } catch {
            hasError = true
            if let cached = CacheService.shared.load(WeatherData.self, key: CacheService.weatherKey) {
                weather = cached.data
            }
        }

        do {
            let aircraft: [Aircraft] = try await APIClient.shared.get("/api/aircraft")
            fleetSummary = FleetSummary(
                available: aircraft.filter { $0.isAvailable }.count,
                inFlight: aircraft.filter { $0.isInFlight }.count,
                maintenance: aircraft.filter { $0.isInMaintenance }.count,
                total: aircraft.count
            )
        } catch {
            hasError = true
        }

        do {
            let checkouts: [Checkout] = try await APIClient.shared.get("/api/checkouts")
            activeCheckout = checkouts.first { $0.isOut && $0.memberId == userId }
        } catch {
            hasError = true
        }

        do {
            let accountData: MyAccountData = try await APIClient.shared.get("/api/my-account")
            personalBalance = accountData.balance ?? 0
        } catch {
            hasError = true
        }

        if hasError && dashboardData == nil && weather == nil {
            errorMessage = "Unable to load data. Pull to refresh."
        }
        isLoading = false
    }

    func dismissAnnouncement(_ announcement: Announcement) async {
        struct DismissBody: Encodable { let id: String; let dismissed: Bool }
        do {
            let _: Announcement = try await APIClient.shared.patch(
                "/api/announcements",
                body: DismissBody(id: announcement.id, dismissed: true)
            )
            announcements.removeAll { $0.id == announcement.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
