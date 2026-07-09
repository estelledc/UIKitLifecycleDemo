import UIKit

final class ReminderCell: UICollectionViewListCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        DemoLog.print("ReminderCell", "init", "frame: \(frame)", category: .cell)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    deinit {
        DemoLog.print("ReminderCell", "deinit", "cell released", category: .memory, isKeyEvent: true)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        DemoLog.print("ReminderCell", "updateConfiguration(using:)", "isSelected: \(state.isSelected), isHighlighted: \(state.isHighlighted)", category: .cell)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        DemoLog.print("ReminderCell", "prepareForReuse", "cell is ready for another reminder", category: .cell, isKeyEvent: true)
    }
}
