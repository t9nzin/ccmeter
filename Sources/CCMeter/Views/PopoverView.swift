import SwiftUI

struct PopoverView: View {
    let aggregator: UsageAggregator
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 12) {
            UsageBarView(
                label: "Session",
                currentTokens: aggregator.sessionOutputTokens,
                limit: aggregator.sessionTokenLimit,
                tintColor: .blue
            )

            UsageBarView(
                label: "Weekly",
                currentTokens: aggregator.weeklyOutputTokens,
                limit: aggregator.weeklyTokenLimit,
                tintColor: .orange
            )

            if let sessionId = aggregator.activeSessionId {
                Text(String(sessionId.prefix(8)))
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
            }

            Divider()

            if showSettings {
                SettingsView(aggregator: aggregator)
                Divider()
            }

            HStack {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
