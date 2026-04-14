import SwiftUI

struct NextFlightCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.brandBlue)
                Text("Next Flight")
                    .font(.headline)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.aircraft?.tailNumber ?? "Aircraft")
                        .font(.title3.bold())
                    Text(booking.aircraft?.type ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(booking.formattedDateRange)
                        .font(.subheadline)
                    HStack(spacing: 4) {
                        Text(booking.type)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandBlue.opacity(0.1))
                            .foregroundColor(.brandBlue)
                            .cornerRadius(4)
                        if booking.isStandby {
                            Text("STANDBY")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
