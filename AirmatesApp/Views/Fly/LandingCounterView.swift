import SwiftUI

struct LandingCounterView: View {
    @Binding var dayLandings: Int
    @Binding var nightLandings: Int
    @Binding var fullStopDay: Int
    @Binding var fullStopNight: Int
    @Binding var instrumentApproaches: Int
    @Binding var holds: Int

    var body: some View {
        VStack(spacing: 0) {
            CounterRow(label: "Day Landings", value: $dayLandings, icon: "sun.max")
            Divider()
            CounterRow(label: "Night Landings", value: $nightLandings, icon: "moon.stars")
            Divider()
            CounterRow(label: "Full Stop (Day)", value: $fullStopDay, icon: "sun.max.fill")
            Divider()
            CounterRow(label: "Full Stop (Night)", value: $fullStopNight, icon: "moon.stars.fill")
            Divider()
            CounterRow(label: "Instrument Approaches", value: $instrumentApproaches, icon: "gauge.with.dots.needle.33percent")
            Divider()
            CounterRow(label: "Holding Patterns", value: $holds, icon: "arrow.triangle.capsulepath")
        }
    }
}

struct CounterRow: View {
    let label: String
    @Binding var value: Int
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            Text(label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if value > 0 { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(value > 0 ? .brandBlue : .secondary.opacity(0.3))
                }
                .disabled(value <= 0)

                Text("\(value)")
                    .font(.title3.monospaced().bold())
                    .frame(minWidth: 28, alignment: .center)

                Button {
                    value += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
