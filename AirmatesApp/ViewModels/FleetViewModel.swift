import Foundation

@Observable
class FleetViewModel {
    var aircraft: [Aircraft] = []
    var isLoading = true
    var errorMessage: String?
    var selectedFilter: AircraftFilter = .all

    enum AircraftFilter: String, CaseIterable {
        case all = "All"
        case available = "Available"
        case inFlight = "In Flight"
        case maintenance = "Maintenance"
    }

    var filteredAircraft: [Aircraft] {
        switch selectedFilter {
        case .all: return aircraft
        case .available: return aircraft.filter { $0.isAvailable }
        case .inFlight: return aircraft.filter { $0.isInFlight }
        case .maintenance: return aircraft.filter { $0.isInMaintenance }
        }
    }

    func fetchAircraft() async {
        isLoading = aircraft.isEmpty
        errorMessage = nil

        do {
            aircraft = try await APIClient.shared.get("/api/aircraft")
            CacheService.shared.save(aircraft, key: CacheService.fleetKey)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            // Load from cache
            if let cached = CacheService.shared.load([Aircraft].self, key: CacheService.fleetKey) {
                aircraft = cached.data
            }
            isLoading = false
        }
    }
}
