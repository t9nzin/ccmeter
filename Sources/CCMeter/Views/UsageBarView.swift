import SwiftUI

struct UsageBarView: View {
    let label: String
    let utilization: Double // 0-100
    let tintColor: Color
    var resetsAt: Date? = nil

    private var fraction: Double {
        min(utilization / 100.0, 1.0)
    }

    private var barColor: Color {
        if utilization >= 90 {
            return .red
        } else if utilization >= 75 {
            return .orange
        }
        return tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(utilization.rounded()))%")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(barColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: max(0, geometry.size.width * fraction), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: fraction)
                }
            }
            .frame(height: 8)

            if let resetsAt {
                Text("Resets \(resetsAt, style: .relative)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
