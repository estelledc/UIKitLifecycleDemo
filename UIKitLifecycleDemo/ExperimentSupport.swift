import UIKit

enum Section {
    case main
}

enum DueBucket: String {
    case today = "Today"
    case future = "Future"
}

enum ReminderFilter: Int, CaseIterable {
    case all
    case today
    case future

    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .future:
            return "Future"
        }
    }

    func includes(_ reminder: Reminder) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            return reminder.dueBucket == .today
        case .future:
            return reminder.dueBucket == .future
        }
    }
}

struct Reminder: Hashable {
    typealias ID = String

    let id: ID
    var title: String
    var dueBucket: DueBucket

    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum DetailPresentationMode: String {
    case show
    case push
    case present

    var readableName: String { rawValue }
}

enum SaveActionMode: String {
    case targetAction = "Target-action"
    case uiAction = "UIAction"

    mutating func toggle() {
        self = self == .targetAction ? .uiAction : .targetAction
    }
}

enum ClosureCaptureMode: String {
    case weakSelf = "Weak self"
    case strongSelf = "Strong self"

    mutating func toggle() {
        self = self == .weakSelf ? .strongSelf : .weakSelf
    }
}

enum SnapshotUpdateMode: String {
    case fullApply = "Full Apply"
    case reloadItem = "Reload Item"
    case reconfigureItem = "Reconfigure Item"
}

extension Array where Element == Reminder {
    static let initialDemoReminders = [
        Reminder(id: "buy-groceries", title: "Buy groceries", dueBucket: .today),
        Reminder(id: "walk-dog", title: "Walk dog", dueBucket: .today),
        Reminder(id: "read-uikit-docs", title: "Read UIKit docs", dueBucket: .future)
    ]

    static func reuseExperimentReminders() -> [Reminder] {
        (1...50).map { index in
            Reminder(
                id: "reuse-\(index)",
                title: "Reuse experiment \(index)",
                dueBucket: index.isMultiple(of: 2) ? .today : .future
            )
        }
    }
}

func formatReminder(_ reminder: Reminder) -> String {
    "\(reminder.id):\(reminder.title)@\(reminder.dueBucket.rawValue)"
}

func formatReminders(_ reminders: [Reminder]) -> String {
    "[" + reminders.map(formatReminder).joined(separator: ", ") + "]"
}

func printNavigationStack(from viewController: UIViewController, _ message: String) {
    let stack = viewController.navigationController?.viewControllers
        .map { String(describing: type(of: $0)) }
        .joined(separator: ", ") ?? "nil"
    DemoLog.print("NavStack", message, "[\(stack)]", category: .navStack)
}
