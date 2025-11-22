import Foundation

extension Date {
    /// Returns a human-readable relative time string (e.g., "5m ago", "2h ago")
    func relativeTimeString() -> String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours)h ago"
        } else if minutes < 10080 {
            let days = minutes / 1440
            return "\(days)d ago"
        } else {
            let weeks = minutes / 10080
            return "\(weeks)w ago"
        }
    }

    /// Returns a short time string for widgets (e.g., "5m", "2h", "3d")
    func shortRelativeTimeString() -> String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours)h"
        } else {
            let days = minutes / 1440
            return "\(days)d"
        }
    }

    /// Returns minutes since this date
    var minutesAgo: Int {
        let interval = Date().timeIntervalSince(self)
        return Int(interval / 60)
    }

    /// Returns hours since this date
    var hoursAgo: Int {
        let interval = Date().timeIntervalSince(self)
        return Int(interval / 3600)
    }

    /// Returns true if date is within the last N minutes
    func isWithinLast(minutes: Int) -> Bool {
        let interval = Date().timeIntervalSince(self)
        return interval <= Double(minutes * 60)
    }

    /// Returns true if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns true if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}
