import SwiftUI

struct SettingsView: View {
    @Bindable var aggregator: UsageAggregator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Limits")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Session")
                    .font(.system(size: 11))
                    .frame(width: 55, alignment: .leading)
                TextField(
                    "300000",
                    value: $aggregator.sessionTokenLimit,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11).monospacedDigit())
            }

            HStack {
                Text("Weekly")
                    .font(.system(size: 11))
                    .frame(width: 55, alignment: .leading)
                TextField(
                    "3500000",
                    value: $aggregator.weeklyTokenLimit,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11).monospacedDigit())
            }

            Text("Pro plan defaults: 300K session, 3.5M weekly")
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)
        }
    }
}
