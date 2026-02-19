import Foundation

extension Date {
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var mediumFormatted: String {
        formatted(date: .long, time: .omitted)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var monthYear: String {
        formatted(.dateTime.month(.wide).year())
    }

    var isOverdue: Bool {
        self < .now
    }
}
