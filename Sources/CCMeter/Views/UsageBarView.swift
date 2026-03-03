import SwiftUI

struct UsageBarView: View {
    let label: String
    let currentTokens: Int
    let limit: Int
    let tintColor: Color

    private var percentage: Double {
        guard limit > 0 else { return 0 }
        return min(Double(currentTokens) / Double(limit), 1.0)
    }

    private var barColor: Color {
        if percentage >= 0.9 {
            return .red
        } else if percentage >= 0.75 {
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
                Text("\(Int(percentage * 100))%")
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
                        .frame(width: max(0, geometry.size.width * percentage), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 8)

            Text("\(TokenFormatter.format(currentTokens)) / \(TokenFormatter.format(limit)) tokens")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
}
