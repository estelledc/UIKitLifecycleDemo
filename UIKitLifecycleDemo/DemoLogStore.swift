import UIKit

enum DemoLogCategory: String, CaseIterable {
    case lifecycle
    case layout
    case list
    case detail
    case navStack
    case dataSource
    case snapshot
    case cell
    case delegate
    case action
    case closure
    case memory
    case guide
    case general

    var title: String {
        switch self {
        case .lifecycle:
            return "Lifecycle"
        case .layout:
            return "Layout"
        case .list:
            return "List"
        case .detail:
            return "Detail"
        case .navStack:
            return "NavStack"
        case .dataSource:
            return "DataSource"
        case .snapshot:
            return "Snapshot"
        case .cell:
            return "Cell"
        case .delegate:
            return "Delegate"
        case .action:
            return "Action"
        case .closure:
            return "Closure"
        case .memory:
            return "Memory"
        case .guide:
            return "Guide"
        case .general:
            return "General"
        }
    }
}

struct DemoLogEvent: Identifiable, Hashable {
    let id: UUID
    let sequence: Int
    let timestamp: Date
    let category: DemoLogCategory
    let owner: String
    let method: String
    let message: String
    let isKeyEvent: Bool
    let experimentID: String?

    var consoleLine: String {
        "🧭 [\(owner)] \(method) - \(message)"
    }
}

extension Notification.Name {
    static let demoLogStoreDidChange = Notification.Name("demoLogStoreDidChange")
}

final class DemoLogStore {
    static let shared = DemoLogStore()

    private let lock = NSLock()
    private var sequence = 0
    private var storedEvents: [DemoLogEvent] = []
    private let maxEvents = 1000

    var isConsolePrintingEnabled = true

    var events: [DemoLogEvent] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    private init() {}

    // 记录结构化事件，同时保留 Xcode Console 输出，方便两种观察方式并存。
    func record(
        owner: String,
        method: String,
        message: String,
        category explicitCategory: DemoLogCategory? = nil,
        isKeyEvent explicitIsKeyEvent: Bool? = nil,
        experimentID: String? = nil
    ) {
        let category = explicitCategory ?? Self.inferCategory(owner: owner, method: method, message: message)
        let isKeyEvent = explicitIsKeyEvent ?? Self.inferIsKeyEvent(method: method, message: message)

        lock.lock()
        sequence += 1
        let event = DemoLogEvent(
            id: UUID(),
            sequence: sequence,
            timestamp: Date(),
            category: category,
            owner: owner,
            method: method,
            message: message,
            isKeyEvent: isKeyEvent,
            experimentID: experimentID
        )
        storedEvents.append(event)
        if storedEvents.count > maxEvents {
            storedEvents.removeFirst(storedEvents.count - maxEvents)
        }
        let shouldPrint = isConsolePrintingEnabled
        lock.unlock()

        if shouldPrint {
            Swift.print(event.consoleLine)
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .demoLogStoreDidChange, object: self)
        }
    }

    func clear() {
        lock.lock()
        storedEvents.removeAll()
        lock.unlock()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .demoLogStoreDidChange, object: self)
        }
    }

    private static func inferCategory(owner: String, method: String, message: String) -> DemoLogCategory {
        let combined = "\(owner) \(method) \(message)"

        if owner == "NavStack" {
            return .navStack
        }
        if owner.contains("ReminderCell") {
            return .cell
        }
        if owner.contains("ReminderListViewController") {
            if method.contains("Snapshot") || method.contains("snapshot") {
                return .snapshot
            }
            if method.contains("CellRegistration") || method.contains("DataSource") || method.contains("dataSource") {
                return .dataSource
            }
            if method.contains("collectionView") || method.contains("didSelectItemAt") {
                return .delegate
            }
            if method.contains("onSave") {
                return .closure
            }
            return .list
        }
        if owner.contains("ReminderDetailViewController") {
            if method.contains("saveReminder") || method.contains("UIAction") || method.contains("cancel") {
                return .action
            }
            return .detail
        }
        if combined.contains("viewWillLayoutSubviews")
            || combined.contains("viewDidLayoutSubviews")
            || combined.contains("viewSafeAreaInsetsDidChange")
            || combined.contains("layoutSubviews")
            || combined.contains("draw") {
            return .layout
        }
        if combined.contains("deinit") {
            return .memory
        }
        if combined.contains("Guide") || combined.contains("Guided") {
            return .guide
        }

        return .general
    }

    private static func inferIsKeyEvent(method: String, message: String) -> Bool {
        let combined = "\(method) \(message)"
        let keyPatterns = [
            "viewDidLoad",
            "viewWillAppear",
            "didSelectItemAt",
            "saveReminder",
            "onSave closure",
            "applyCurrentSnapshot",
            "deinit"
        ]
        return keyPatterns.contains { combined.contains($0) }
    }
}

enum DemoLog {
    static func print(
        _ owner: String,
        _ method: String,
        _ message: String,
        category: DemoLogCategory? = nil,
        isKeyEvent: Bool? = nil,
        experimentID: String? = nil
    ) {
        DemoLogStore.shared.record(
            owner: owner,
            method: method,
            message: message,
            category: category,
            isKeyEvent: isKeyEvent,
            experimentID: experimentID
        )
    }
}
