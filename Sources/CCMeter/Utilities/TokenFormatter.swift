import Foundation

enum TokenFormatter {
    static func format(_ count: Int) -> String {
        if count >= 1_000_000 {
            let value = Double(count) / 1_000_000.0
            if value == value.rounded(.down) {
                return "\(Int(value))M"
            }
            return String(format: "%.1fM", value)
        } else if count >= 1_000 {
            let value = Double(count) / 1_000.0
            if value == value.rounded(.down) {
                return "\(Int(value))K"
            }
            return String(format: "%.1fK", value)
        }
        return "\(count)"
    }
}
