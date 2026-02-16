import Foundation

struct MyAccountData: Codable {
    var user: User
    var transactions: [Transaction]
    var flights: [Flight]
    var activeBookings: Int
    var balance: Double
}
