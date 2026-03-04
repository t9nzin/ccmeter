import SwiftUI

struct PopoverView: View {
    let aggregator: UsageAggregator

    var body: some View {
        VStack(spacing: 12) {
            if let error = aggregator.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            UsageBarView(
                label: "Session (5h)",
                utilization: aggregator.sessionUtilization,
                tintColor: .white,
                resetsAt: aggregator.usageData?.fiveHour?.resetsAt
            )

            UsageBarView(
                label: "Weekly",
                utilization: aggregator.weeklyUtilization,
                tintColor: .white,
                resetsAt: aggregator.usageData?.sevenDay?.resetsAt
            )

            if aggregator.weeklyOpusUtilization > 0 {
                UsageBarView(
                    label: "Weekly (Opus)",
                    utilization: aggregator.weeklyOpusUtilization,
                    tintColor: .white,
                    resetsAt: aggregator.usageData?.sevenDayOpus?.resetsAt
                )
            }

            Divider()

            HStack {
                if aggregator.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task { await aggregator.fetchUsage() }
                } label: {
                    Image(systemName: "arrow.clockwise")
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
