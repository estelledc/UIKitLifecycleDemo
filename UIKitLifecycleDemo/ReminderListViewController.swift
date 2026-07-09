import UIKit

final class ReminderListViewController: UICollectionViewController {
    private enum Section {
        case main
    }

    private enum DueBucket: String {
        case today = "Today"
        case future = "Future"
    }

    private enum ReminderFilter: Int, CaseIterable {
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

    private struct Reminder: Hashable {
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

    private var reminders = [
        Reminder(id: "buy-groceries", title: "Buy groceries", dueBucket: .today),
        Reminder(id: "walk-dog", title: "Walk dog", dueBucket: .today),
        Reminder(id: "read-uikit-docs", title: "Read UIKit docs", dueBucket: .future)
    ]

    private var selectedFilter: ReminderFilter = .all
    private var dataSource: UICollectionViewDiffableDataSource<Section, Reminder>!
    private let progressLabel = UILabel()
    private let progressView = ReminderProgressView()

    private lazy var filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ReminderFilter.allCases.map(\.title))
        control.selectedSegmentIndex = selectedFilter.rawValue
        control.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        return control
    }()

    private lazy var progressStack: UIStackView = {
        progressLabel.font = .preferredFont(forTextStyle: .caption2)
        progressLabel.textColor = .secondaryLabel
        progressLabel.text = "0%"
        progressLabel.isAccessibilityElement = false
        progressLabel.setContentHuggingPriority(.required, for: .horizontal)

        progressView.isAccessibilityElement = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalToConstant: 54),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])

        let stack = UIStackView(arrangedSubviews: [progressLabel, progressView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isAccessibilityElement = true
        stack.accessibilityLabel = "Visible reminders"
        stack.accessibilityValue = "0 of \(reminders.count), 0%"
        print("[ReminderListViewController] progressStack - axis: horizontal, spacing: \(stack.spacing)")
        return stack
    }()

    private var displayedReminders: [Reminder] {
        reminders.filter { selectedFilter.includes($0) }
    }

    init() {
        print("[ReminderListViewController] init - create list with initial reminders: \(Self.format(Self.initialReminders))")
        super.init(collectionViewLayout: Self.initialLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[ReminderListViewController] viewDidLoad - collectionView already exists: \(collectionView != nil)")

        setupNavigation()
        setupCollectionView()
        configureDataSource()
        applyInitialSnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[ReminderListViewController] viewWillAppear - current reminders: \(Self.format(reminders))")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[ReminderListViewController] viewDidAppear - list is visible")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("[ReminderListViewController] viewWillDisappear - list is about to leave screen")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("[ReminderListViewController] viewDidDisappear - list left screen")
    }

    // 配置导航栏：列表页标题会显示在导航栏上。
    private func setupNavigation() {
        title = "Reminders"
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.titleView = filterControl
        let sameButton = UIBarButtonItem(
            title: "Same",
            style: .plain,
            target: self,
            action: #selector(makeFirstTwoTitlesMatch)
        )
        let progressItem = UIBarButtonItem(customView: progressStack)
        navigationItem.leftBarButtonItems = [sameButton, progressItem]
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addReminder)
        )
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // 配置 collectionView 本体：继承 UICollectionViewController 后，它已经帮我们创建好了 collectionView。
    private func setupCollectionView() {
        print("[ReminderListViewController] setupCollectionView - UICollectionViewController provides collectionView: \(collectionView != nil)")
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.collectionViewLayout = listLayout()
    }

    // layout 只决定 cell 怎么摆放，不决定显示哪些数据。
    private func listLayout() -> UICollectionViewLayout {
        print("[ReminderListViewController] listLayout - create UICollectionViewCompositionalLayout.list")
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.deleteActions(for: indexPath)
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    // dataSource 负责把 item 变成 cell；真正显示哪些 item 由 snapshot 决定。
    private func configureDataSource() {
        print("[ReminderListViewController] configureDataSource - configure CellRegistration and DiffableDataSource")

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Reminder> { cell, indexPath, reminder in
            print("[ReminderListViewController] CellRegistration - configure cell at indexPath: \(indexPath), id: \(reminder.id), title: \(reminder.title)")

            var content = cell.defaultContentConfiguration()
            content.text = reminder.title
            content.secondaryText = "\(reminder.dueBucket.rawValue) - Tap to edit"
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Reminder>(
            collectionView: collectionView
        ) { collectionView, indexPath, reminder in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: reminder
            )
        }
    }

    // 第一次把初始数据交给 collectionView。
    private func applyInitialSnapshot() {
        print("[ReminderListViewController] applyInitialSnapshot - before apply, reminders: \(Self.format(reminders))")
        applyCurrentSnapshot()
    }

    // snapshot 决定当前列表显示哪些数据，以及顺序是什么。
    private func applyCurrentSnapshot(reconfiguring remindersToReconfigure: [Reminder] = []) {
        let currentReminders = displayedReminders
        print("[ReminderListViewController] applyCurrentSnapshot - filter: \(selectedFilter.title), all reminders: \(Self.format(reminders)), displayed reminders: \(Self.format(currentReminders))")
        updateProgressView(displaying: currentReminders)

        var snapshot = NSDiffableDataSourceSnapshot<Section, Reminder>()
        snapshot.appendSections([.main])
        snapshot.appendItems(currentReminders)
        snapshot.reconfigureItems(remindersToReconfigure.filter { currentReminders.contains($0) })
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateProgressView(displaying currentReminders: [Reminder]) {
        let progress = reminders.isEmpty ? 0 : CGFloat(currentReminders.count) / CGFloat(reminders.count)
        print("[ReminderListViewController] updateProgressView - progress: \(progress)")
        let percent = Int((progress * 100).rounded())
        progressLabel.text = "\(percent)%"
        progressStack.accessibilityValue = "\(currentReminders.count) of \(reminders.count), \(percent)%"
        print("[ReminderListViewController] updateProgressAccessibility - label: \(progressStack.accessibilityLabel ?? ""), value: \(progressStack.accessibilityValue ?? "")")
        progressView.progress = progress
    }

    @objc private func addReminder() {
        let dueBucket: DueBucket = selectedFilter == .future ? .future : .today
        let newReminder = Reminder(
            id: UUID().uuidString,
            title: "New Reminder \(reminders.count + 1)",
            dueBucket: dueBucket
        )

        print("[ReminderListViewController] addReminder - appending new reminder: \(Self.format(newReminder))")
        reminders.append(newReminder)
        applyCurrentSnapshot()
    }

    @objc private func makeFirstTwoTitlesMatch() {
        guard reminders.count >= 2 else {
            print("[ReminderListViewController] makeFirstTwoTitlesMatch - not enough reminders: \(Self.format(reminders))")
            return
        }

        let sharedTitle = reminders[0].title
        print("[ReminderListViewController] makeFirstTwoTitlesMatch - before update: \(Self.format(reminders))")
        reminders[1].title = sharedTitle
        print("[ReminderListViewController] makeFirstTwoTitlesMatch - after update, first id: \(reminders[0].id), second id: \(reminders[1].id), shared title: \(sharedTitle)")
        applyCurrentSnapshot(reconfiguring: [reminders[0], reminders[1]])
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        guard let nextFilter = ReminderFilter(rawValue: sender.selectedSegmentIndex) else {
            print("[ReminderListViewController] filterChanged - invalid selected index: \(sender.selectedSegmentIndex)")
            return
        }

        selectedFilter = nextFilter
        print("[ReminderListViewController] filterChanged - selected filter: \(selectedFilter.title)")
        applyCurrentSnapshot()
    }

    private func deleteActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let reminder = dataSource.itemIdentifier(for: indexPath) else {
            print("[ReminderListViewController] deleteActions(for:) - no item at indexPath: \(indexPath)")
            return nil
        }

        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            print("[ReminderListViewController] delete action - reminderID: \(reminder.id)")
            self?.deleteReminder(reminder.id)
            completion(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }

    private func deleteReminder(_ reminderID: Reminder.ID) {
        print("[ReminderListViewController] deleteReminder - reminderID: \(reminderID)")

        guard let index = reminders.firstIndex(where: { $0.id == reminderID }) else {
            print("[ReminderListViewController] deleteReminder - reminderID not found, current reminders: \(Self.format(reminders))")
            return
        }

        let removedReminder = reminders.remove(at: index)
        print("[ReminderListViewController] deleteReminder - removed: \(Self.format(removedReminder)), remaining reminders: \(Self.format(reminders))")
        applyCurrentSnapshot()
    }

    // Save 后列表页在这里更新数组，再重新 apply snapshot。
    private func update(_ reminderID: Reminder.ID, with editedTitle: String) {
        print("[ReminderListViewController] update(_:with:) - reminderID: \(reminderID), editedTitle: \(editedTitle)")

        guard let index = reminders.firstIndex(where: { $0.id == reminderID }) else {
            print("[ReminderListViewController] update(_:with:) - reminderID not found, current reminders: \(Self.format(reminders))")
            return
        }

        reminders[index].title = editedTitle
        print("[ReminderListViewController] update(_:with:) - updated reminders: \(Self.format(reminders))")
        applyCurrentSnapshot(reconfiguring: [reminders[index]])
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let selectedReminder = dataSource.itemIdentifier(for: indexPath) else {
            print("[ReminderListViewController] collectionView(_:didSelectItemAt:) - no item at indexPath: \(indexPath)")
            return
        }

        print("[ReminderListViewController] collectionView(_:didSelectItemAt:) - indexPath: \(indexPath), selectedReminder: \(Self.format(selectedReminder))")

        let detailViewController = ReminderDetailViewController(reminderTitle: selectedReminder.title) { [weak self] editedTitle in
            print("[ReminderListViewController] onSave closure - selectedReminderID: \(selectedReminder.id), editedTitle: \(editedTitle)")
            self?.update(selectedReminder.id, with: editedTitle)
        }

        print("[ReminderListViewController] collectionView(_:didSelectItemAt:) - push detail for selectedReminder: \(Self.format(selectedReminder))")
        show(detailViewController, sender: self)
    }

    private static let initialReminders = [
        Reminder(id: "buy-groceries", title: "Buy groceries", dueBucket: .today),
        Reminder(id: "walk-dog", title: "Walk dog", dueBucket: .today),
        Reminder(id: "read-uikit-docs", title: "Read UIKit docs", dueBucket: .future)
    ]

    private static func initialLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private static func format(_ reminder: Reminder) -> String {
        "\(reminder.id):\(reminder.title)@\(reminder.dueBucket.rawValue)"
    }

    private static func format(_ reminders: [Reminder]) -> String {
        "[" + reminders.map(format).joined(separator: ", ") + "]"
    }
}

private final class ReminderProgressView: UIView {
    private let fillView = UIView()
    private var storedProgress: CGFloat = 0

    var progress: CGFloat {
        get { storedProgress }
        set {
            storedProgress = min(max(newValue, 0), 1)
            accessibilityValue = "\(Int((storedProgress * 100).rounded()))%"
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        isOpaque = false
        accessibilityLabel = "Visible reminders"
        backgroundColor = .tertiarySystemFill
        layer.cornerRadius = 4
        clipsToBounds = true

        fillView.backgroundColor = .systemGreen
        addSubview(fillView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 54, height: 8)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("[ReminderProgressView] layoutSubviews - bounds: \(bounds), progress: \(storedProgress)")
        fillView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width * storedProgress,
            height: bounds.height
        )
        layer.cornerRadius = bounds.height / 2
        fillView.layer.cornerRadius = bounds.height / 2
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        print("[ReminderProgressView] draw - rect: \(rect)")

        let borderPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: bounds.height / 2
        )
        UIColor.separator.setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()
    }
}
