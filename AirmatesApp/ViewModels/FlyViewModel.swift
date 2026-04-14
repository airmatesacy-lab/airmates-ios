import Foundation

@Observable
class FlyViewModel {
    var activeCheckouts: [Checkout] = []
    var myActiveCheckout: Checkout?
    var aircraft: [Aircraft] = []
    var notices: [AircraftNotice] = []
    var unackedNotices: [AircraftNotice] = []
    var recentFlights: [Flight] = []
    var isLoading = true
    var errorMessage: String?
    var checkoutError: String?

    // Check-in form state
    var tachIn = ""
    var fuelAdded = ""
    var flightType = "SOLO"
    var notes = ""
    var dayLandings = 0
    var nightLandings = 0
    var fullStopDay = 0
    var fullStopNight = 0
    var instrumentApproaches = 0
    var holds = 0

    var tachDelta: Double? {
        guard let checkout = myActiveCheckout,
              let tachInVal = Double(tachIn) else { return nil }
        return max(0, tachInVal - checkout.tachOut)
    }

    var needsTachConfirmation: Bool {
        guard let delta = tachDelta else { return false }
        return delta > AppConstants.maxTachDeltaBeforeConfirmation
    }

    func loadAll(userId: String?) async {
        isLoading = activeCheckouts.isEmpty
        errorMessage = nil

        do {
            async let checkoutsReq: [Checkout] = APIClient.shared.get("/api/checkouts")
            async let aircraftReq: [Aircraft] = APIClient.shared.get("/api/aircraft")
            async let flightsReq: [Flight] = APIClient.shared.get("/api/flights", query: [
                URLQueryItem(name: "limit", value: "10"),
            ])

            activeCheckouts = try await checkoutsReq
            aircraft = try await aircraftReq
            recentFlights = try await flightsReq

            // Find current user's active checkout
            if let userId {
                myActiveCheckout = activeCheckouts.first { $0.isOut && $0.memberId == userId }
            }

            CacheService.shared.save(aircraft, key: CacheService.fleetKey)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchNotices(for aircraftId: String) async {
        do {
            notices = try await APIClient.shared.get("/api/aircraft/notices", query: [
                URLQueryItem(name: "aircraftId", value: aircraftId),
            ])
            unackedNotices = notices.filter { ($0.blockCheckout == true || $0.blockBooking == true) && $0.acked != true }
        } catch {
            // Non-fatal — checkout can proceed if notice fetch fails
        }
    }

    func acknowledgeNotice(_ notice: AircraftNotice, signedName: String?) async -> Bool {
        do {
            let body = NoticeAckRequest(
                noticeId: notice.id,
                noticeVersion: notice.version ?? 1,
                signedName: signedName
            )
            let _: [String: Bool] = try await APIClient.shared.patch("/api/aircraft/notices/ack", body: body)
            unackedNotices.removeAll { $0.id == notice.id }
            return true
        } catch {
            checkoutError = error.localizedDescription
            return false
        }
    }

    func checkOut(aircraftId: String, tachOut: String, destination: String?, forMemberId: String? = nil, currentUserId: String? = nil) async -> Bool {
        checkoutError = nil
        do {
            let body = CheckOutBody(
                aircraftId: aircraftId,
                tachOut: tachOut,
                destination: destination,
                memberId: forMemberId
            )
            let checkout: Checkout = try await APIClient.shared.post("/api/checkouts", body: body)
            // Only set as MY active checkout if checking out for self
            if forMemberId == nil || forMemberId == currentUserId {
                myActiveCheckout = checkout
            }
            activeCheckouts.append(checkout)
            return true
        } catch let err as APIError {
            if case .preconditionRequired(let msg, let data) = err {
                // Parse notice block response
                if let data, let noticeBlock = try? JSONDecoder().decode(NoticeBlockResponse.self, from: data),
                   noticeBlock.noticesRequired == true {
                    checkoutError = "Please acknowledge aircraft notices first"
                } else {
                    checkoutError = msg
                }
            } else {
                checkoutError = err.errorDescription
            }
            return false
        } catch {
            checkoutError = error.localizedDescription
            return false
        }
    }

    func checkIn() async -> Bool {
        guard let checkout = myActiveCheckout else { return false }
        checkoutError = nil

        do {
            let body = CheckInBody(
                checkoutId: checkout.id,
                tachIn: tachIn,
                fuelAdded: fuelAdded.isEmpty ? nil : fuelAdded,
                flightType: flightType,
                notes: notes.isEmpty ? nil : notes,
                dayLandings: dayLandings > 0 ? dayLandings : nil,
                nightLandings: nightLandings > 0 ? nightLandings : nil,
                fullStopDay: fullStopDay > 0 ? fullStopDay : nil,
                fullStopNight: fullStopNight > 0 ? fullStopNight : nil,
                instrumentApproaches: instrumentApproaches > 0 ? instrumentApproaches : nil,
                holds: holds > 0 ? holds : nil
            )
            let response: CheckoutResponse = try await APIClient.shared.post("/api/checkouts", body: body)
            myActiveCheckout = nil
            activeCheckouts.removeAll { $0.id == checkout.id }
            if let flight = response.flight {
                recentFlights.insert(flight, at: 0)
            }
            resetCheckInForm()
            return true
        } catch {
            checkoutError = error.localizedDescription
            return false
        }
    }

    func resetCheckInForm() {
        tachIn = ""
        fuelAdded = ""
        flightType = "SOLO"
        notes = ""
        dayLandings = 0
        nightLandings = 0
        fullStopDay = 0
        fullStopNight = 0
        instrumentApproaches = 0
        holds = 0
    }
}
