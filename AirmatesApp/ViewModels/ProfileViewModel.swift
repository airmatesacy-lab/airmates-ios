import Foundation

@Observable
class ProfileViewModel {
    var user: User?
    var accountData: MyAccountData?
    var transactions: [Transaction] = []
    var isLoading = true
    var errorMessage: String?

    var balance: Double {
        accountData?.balance ?? 0
    }

    var hoursUsedThisMonth: Double {
        // Sum tachTime from this month's flights
        let calendar = Calendar.current
        let now = Date()
        return accountData?.flights.reduce(0.0) { sum, flight in
            if let date = DateFormatter.apiDate.date(from: flight.date),
               calendar.isDate(date, equalTo: now, toGranularity: .month) {
                return sum + flight.hobbsTime
            }
            return sum
        } ?? 0
    }

    var freeHoursRemaining: Double {
        let free = user?.membershipTier?.freeHoursPerMonth ?? 0
        return max(0, free - hoursUsedThisMonth)
    }

    // Currency status
    var dayCurrentExpiry: String? { user?.lastPassengerFlight }
    var nightCurrentExpiry: String? { user?.lastNightFlight }
    var ifrCurrentExpiry: String? { user?.lastIFRActivity }

    func loadProfile() async {
        isLoading = user == nil
        errorMessage = nil

        do {
            async let profileReq: User = APIClient.shared.get("/api/profile")
            async let accountReq: MyAccountData = APIClient.shared.get("/api/my-account")

            user = try await profileReq
            accountData = try await accountReq
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadTransactions() async {
        do {
            transactions = try await APIClient.shared.get("/api/transactions")
        } catch {
            // Non-fatal
        }
    }

    struct ProfileUpdate: Encodable {
        var name: String?
        var phone: String?
        var addressLine1: String?
        var city: String?
        var state: String?
        var zip: String?
        var emergencyName: String?
        var emergencyPhone: String?
        var emergencyRelation: String?
    }

    func updateProfile(_ updates: ProfileUpdate) async -> Bool {
        do {
            user = try await APIClient.shared.patch("/api/profile", body: updates)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
