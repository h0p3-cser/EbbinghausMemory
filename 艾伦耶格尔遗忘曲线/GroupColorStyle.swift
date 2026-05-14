import SwiftUI

extension GroupColorName {
    var color: Color {
        switch self {
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .gray:
            return .gray
        }
    }
}

func formattedTime(hour: Int, minute: Int) -> String {
    String(format: "%02d:%02d", min(max(hour, 0), 23), min(max(minute, 0), 59))
}
