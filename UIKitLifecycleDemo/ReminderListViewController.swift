import UIKit

final class ReminderListViewController: UICollectionViewController {
    private var reminders = [Reminder].initialDemoReminders
    private var selectedFilter: ReminderFilter = .all
    private var saveActionMode: SaveActionMode = .targetAction
    private var closureCaptureMode: ClosureCaptureMode = .weakSelf
    private var dataSource: UICollectionViewDiffableDataSource<Section, Reminder>!
    private let progressLabel = UILabel()
    private let progressView = ReminderProgressView()
    private var cellConfigurationCount = 0

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
        DemoLog.print("ReminderListViewController", "progressStack", "axis: horizontal, spacing: \(stack.spacing)")
        return stack
    }()

    private var displayedReminders: [Reminder] {
        reminders.filter { selectedFilter.includes($0) }
    }

    init() {
        DemoLog.print("ReminderListViewController", "init", "create list with initial reminders: \(formatReminders([Reminder].initialDemoReminders))")
        super.init(collectionViewLayout: Self.initialLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    deinit {
        DemoLog.print("ReminderListViewController", "deinit", "list controller released")
    }

    override func loadView() {
        DemoLog.print("ReminderListViewController", "loadView", "before super, isViewLoaded: \(isViewLoaded)")
        super.loadView()
        DemoLog.print("ReminderListViewController", "loadView", "after super, isViewLoaded: \(isViewLoaded), collectionView exists: \(collectionView != nil), view type: \(type(of: view!))")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DemoLog.print("ReminderListViewController", "viewDidLoad", "isViewLoaded: \(isViewLoaded), collectionView exists: \(collectionView != nil)")

        setupNavigation()
        setupCollectionView()
        configureDataSource()
        applyInitialSnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DemoLog.print("ReminderListViewController", "viewWillAppear", "current reminders: \(formatReminders(reminders))")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DemoLog.print("ReminderListViewController", "viewDidAppear", "list is visible")
        printNavigationStack(from: self, "list viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DemoLog.print("ReminderListViewController", "viewWillDisappear", "list is about to leave screen")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DemoLog.print("ReminderListViewController", "viewDidDisappear", "list left screen")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DemoLog.print("ReminderListViewController", "viewWillLayoutSubviews", "view.bounds: \(view.bounds), safeAreaInsets: \(view.safeAreaInsets), collectionView.bounds: \(collectionView.bounds)")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DemoLog.print("ReminderListViewController", "viewDidLayoutSubviews", "view.bounds: \(view.bounds), safeAreaInsets: \(view.safeAreaInsets), collectionView.bounds: \(collectionView.bounds)")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        DemoLog.print("ReminderListViewController", "viewSafeAreaInsetsDidChange", "safeAreaInsets: \(view.safeAreaInsets), collectionView.bounds: \(collectionView.bounds)")
    }

    // 配置导航栏：实验入口都放在菜单里，主流程保持简洁。
    private func setupNavigation() {
        title = "Reminders"
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.titleView = filterControl
        navigationController?.navigationBar.prefersLargeTitles = true

        let sameButton = UIBarButtonItem(title: "Same", style: .plain, target: self, action: #selector(makeFirstTwoTitlesMatch))
        let progressItem = UIBarButtonItem(customView: progressStack)
        navigationItem.leftBarButtonItems = [sameButton, progressItem]

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addReminder))
        addButton.accessibilityIdentifier = "addReminderButton"

        let learnButton = UIBarButtonItem(title: "Learn", menu: learnMenu())
        learnButton.accessibilityIdentifier = "learnButton"
        navigationItem.rightBarButtonItems = [addButton, learnButton]
    }

    private func learnMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: "Logs", image: UIImage(systemName: "list.bullet.rectangle")) { [weak self] _ in
                self?.showLogPanel()
            },
            experimentsMenu()
        ])
    }

    private func experimentsMenu() -> UIMenu {
        UIMenu(title: "Experiments", children: [
            UIMenu(title: "Open Detail", options: .displayInline, children: [
                UIAction(title: "Show") { [weak self] _ in self?.openFirstReminder(using: .show) },
                UIAction(title: "Push") { [weak self] _ in self?.openFirstReminder(using: .push) },
                UIAction(title: "Present") { [weak self] _ in self?.openFirstReminder(using: .present) }
            ]),
            UIMenu(title: "Snapshot", options: .displayInline, children: [
                UIAction(title: SnapshotUpdateMode.fullApply.rawValue) { [weak self] _ in self?.runSnapshotExperiment(.fullApply) },
                UIAction(title: SnapshotUpdateMode.reloadItem.rawValue) { [weak self] _ in self?.runSnapshotExperiment(.reloadItem) },
                UIAction(title: SnapshotUpdateMode.reconfigureItem.rawValue) { [weak self] _ in self?.runSnapshotExperiment(.reconfigureItem) }
            ]),
            UIMenu(title: "Modes", options: .displayInline, children: [
                UIAction(title: "Toggle Save: \(saveActionMode.rawValue)") { [weak self] _ in self?.toggleSaveActionMode() },
                UIAction(title: "Toggle Closure: \(closureCaptureMode.rawValue)") { [weak self] _ in self?.toggleClosureCaptureMode() },
                UIAction(title: "Load 50 Reuse Items") { [weak self] _ in self?.loadReuseExperimentItems() }
            ]),
            UIMenu(title: "More", options: .displayInline, children: [
                UIAction(title: "String Identity Experiment") { [weak self] _ in self?.showStringIdentityExperiment() },
                UIAction(title: "Manual UIViewController Version") { [weak self] _ in self?.showManualCollectionVersion() }
            ])
        ])
    }

    private func showLogPanel() {
        DemoLog.print("ReminderListViewController", "showLogPanel", "present in-app log panel", category: .action)
        let logPanel = UINavigationController(rootViewController: DemoLogPanelViewController())
        present(logPanel, animated: true)
    }

    // 配置 collectionView 本体：继承 UICollectionViewController 后，它已经帮我们创建好了 collectionView。
    private func setupCollectionView() {
        DemoLog.print("ReminderListViewController", "setupCollectionView", "UICollectionViewController provides collectionView: \(collectionView != nil)")
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.collectionViewLayout = listLayout()
        collectionView.accessibilityIdentifier = "reminderCollectionView"
    }

    // layout 只决定 cell 怎么摆放，不决定显示哪些数据。
    private func listLayout() -> UICollectionViewLayout {
        DemoLog.print("ReminderListViewController", "listLayout", "create UICollectionViewCompositionalLayout.list")
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.deleteActions(for: indexPath)
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    // dataSource 负责把 item 变成 cell；真正显示哪些 item 由 snapshot 决定。
    private func configureDataSource() {
        DemoLog.print("ReminderListViewController", "configureDataSource", "configure ReminderCell, CellRegistration, and DiffableDataSource")

        let cellRegistration = UICollectionView.CellRegistration<ReminderCell, Reminder> { [weak self] cell, indexPath, reminder in
            self?.cellConfigurationCount += 1
            let count = self?.cellConfigurationCount ?? 0
            DemoLog.print("ReminderListViewController", "CellRegistration", "count: \(count), indexPath: \(indexPath), reminder: \(formatReminder(reminder))")

            var content = cell.defaultContentConfiguration()
            content.text = reminder.title
            content.secondaryText = "\(reminder.dueBucket.rawValue) - Tap to edit"
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            cell.accessibilityIdentifier = "reminderCell_\(reminder.id)"
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Reminder>(collectionView: collectionView) { collectionView, indexPath, reminder in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: reminder)
        }
    }

    // 第一次把初始数据交给 collectionView。
    private func applyInitialSnapshot() {
        DemoLog.print("ReminderListViewController", "applyInitialSnapshot", "before apply, reminders: \(formatReminders(reminders))")
        applyCurrentSnapshot()
    }

    // snapshot 决定当前列表显示哪些数据，以及顺序是什么。
    private func applyCurrentSnapshot(reconfiguring remindersToReconfigure: [Reminder] = [], reloading remindersToReload: [Reminder] = []) {
        let currentReminders = displayedReminders
        DemoLog.print("ReminderListViewController", "applyCurrentSnapshot", "filter: \(selectedFilter.title), all reminders: \(formatReminders(reminders)), displayed reminders: \(formatReminders(currentReminders))")
        updateProgressView(displaying: currentReminders)

        var snapshot = NSDiffableDataSourceSnapshot<Section, Reminder>()
        snapshot.appendSections([.main])
        snapshot.appendItems(currentReminders)

        let visibleReloads = remindersToReload.filter { currentReminders.contains($0) }
        let visibleReconfigures = remindersToReconfigure.filter { currentReminders.contains($0) }
        if !visibleReloads.isEmpty {
            DemoLog.print("ReminderListViewController", "applyCurrentSnapshot", "reloadItems: \(formatReminders(visibleReloads))")
            snapshot.reloadItems(visibleReloads)
        }
        if !visibleReconfigures.isEmpty {
            DemoLog.print("ReminderListViewController", "applyCurrentSnapshot", "reconfigureItems: \(formatReminders(visibleReconfigures))")
            snapshot.reconfigureItems(visibleReconfigures)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateProgressView(displaying currentReminders: [Reminder]) {
        let progress = reminders.isEmpty ? 0 : CGFloat(currentReminders.count) / CGFloat(reminders.count)
        DemoLog.print("ReminderListViewController", "updateProgressView", "progress: \(progress)")
        let percent = Int((progress * 100).rounded())
        progressLabel.text = "\(percent)%"
        progressStack.accessibilityValue = "\(currentReminders.count) of \(reminders.count), \(percent)%"
        DemoLog.print("ReminderListViewController", "updateProgressAccessibility", "label: \(progressStack.accessibilityLabel ?? ""), value: \(progressStack.accessibilityValue ?? "")")
        progressView.progress = progress
    }

    @objc private func addReminder() {
        let dueBucket: DueBucket = selectedFilter == .future ? .future : .today
        let newReminder = Reminder(id: UUID().uuidString, title: "New Reminder \(reminders.count + 1)", dueBucket: dueBucket)

        DemoLog.print("ReminderListViewController", "addReminder", "appending new reminder: \(formatReminder(newReminder))")
        reminders.append(newReminder)
        applyCurrentSnapshot()
    }

    @objc private func makeFirstTwoTitlesMatch() {
        guard reminders.count >= 2 else {
            DemoLog.print("ReminderListViewController", "makeFirstTwoTitlesMatch", "not enough reminders: \(formatReminders(reminders))")
            return
        }

        let sharedTitle = reminders[0].title
        DemoLog.print("ReminderListViewController", "makeFirstTwoTitlesMatch", "before update: \(formatReminders(reminders))")
        reminders[1].title = sharedTitle
        DemoLog.print("ReminderListViewController", "makeFirstTwoTitlesMatch", "after update, first id: \(reminders[0].id), second id: \(reminders[1].id), shared title: \(sharedTitle)")
        applyCurrentSnapshot(reconfiguring: [reminders[0], reminders[1]])
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        guard let nextFilter = ReminderFilter(rawValue: sender.selectedSegmentIndex) else {
            DemoLog.print("ReminderListViewController", "filterChanged", "invalid selected index: \(sender.selectedSegmentIndex)")
            return
        }

        selectedFilter = nextFilter
        DemoLog.print("ReminderListViewController", "filterChanged", "selected filter: \(selectedFilter.title)")
        applyCurrentSnapshot()
    }

    private func deleteActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let reminder = dataSource.itemIdentifier(for: indexPath) else {
            DemoLog.print("ReminderListViewController", "deleteActions(for:)", "no item at indexPath: \(indexPath)")
            return nil
        }

        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            DemoLog.print("ReminderListViewController", "delete action", "reminderID: \(reminder.id)")
            self?.deleteReminder(reminder.id)
            completion(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }

    private func deleteReminder(_ reminderID: Reminder.ID) {
        DemoLog.print("ReminderListViewController", "deleteReminder", "reminderID: \(reminderID)")

        guard let index = reminders.firstIndex(where: { $0.id == reminderID }) else {
            DemoLog.print("ReminderListViewController", "deleteReminder", "reminderID not found, current reminders: \(formatReminders(reminders))")
            return
        }

        let removedReminder = reminders.remove(at: index)
        DemoLog.print("ReminderListViewController", "deleteReminder", "removed: \(formatReminder(removedReminder)), remaining reminders: \(formatReminders(reminders))")
        applyCurrentSnapshot()
    }

    // Save 后列表页在这里更新数组，再重新 apply snapshot。
    private func update(_ reminderID: Reminder.ID, with editedTitle: String, updateMode: SnapshotUpdateMode = .reconfigureItem) {
        DemoLog.print("ReminderListViewController", "update(_:with:)", "reminderID: \(reminderID), editedTitle: \(editedTitle), updateMode: \(updateMode.rawValue)")

        guard let index = reminders.firstIndex(where: { $0.id == reminderID }) else {
            DemoLog.print("ReminderListViewController", "update(_:with:)", "reminderID not found, current reminders: \(formatReminders(reminders))")
            return
        }

        let oldReminder = reminders[index]
        reminders[index].title = editedTitle
        let updatedReminder = reminders[index]
        DemoLog.print("ReminderListViewController", "update(_:with:)", "old: \(formatReminder(oldReminder)), new: \(formatReminder(updatedReminder)), all: \(formatReminders(reminders))")

        switch updateMode {
        case .fullApply:
            applyCurrentSnapshot()
        case .reloadItem:
            applyCurrentSnapshot(reloading: [updatedReminder])
        case .reconfigureItem:
            applyCurrentSnapshot(reconfiguring: [updatedReminder])
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let selectedReminder = dataSource.itemIdentifier(for: indexPath) else {
            DemoLog.print("ReminderListViewController", "collectionView(_:didSelectItemAt:)", "no item at indexPath: \(indexPath)")
            return
        }

        DemoLog.print("ReminderListViewController", "collectionView(_:didSelectItemAt:)", "indexPath: \(indexPath), selectedReminder: \(formatReminder(selectedReminder))")
        openDetail(for: selectedReminder, using: .show)
    }

    private func openFirstReminder(using presentationMode: DetailPresentationMode) {
        guard let reminder = displayedReminders.first else {
            DemoLog.print("ReminderListViewController", "openFirstReminder(using:)", "no displayed reminder")
            return
        }
        openDetail(for: reminder, using: presentationMode)
    }

    private func openDetail(for selectedReminder: Reminder, using presentationMode: DetailPresentationMode) {
        printNavigationStack(from: self, "before \(presentationMode.readableName)")

        let onSave: (String) -> Void
        switch closureCaptureMode {
        case .weakSelf:
            onSave = { [weak self] editedTitle in
                DemoLog.print("ReminderListViewController", "onSave closure", "captureMode: weakSelf, selectedReminderID: \(selectedReminder.id), editedTitle: \(editedTitle)")
                self?.update(selectedReminder.id, with: editedTitle)
            }
        case .strongSelf:
            onSave = { editedTitle in
                DemoLog.print("ReminderListViewController", "onSave closure", "captureMode: strongSelf, selectedReminderID: \(selectedReminder.id), editedTitle: \(editedTitle)")
                self.update(selectedReminder.id, with: editedTitle)
            }
        }

        let detailViewController = ReminderDetailViewController(
            reminderTitle: selectedReminder.title,
            presentationMode: presentationMode,
            saveActionMode: saveActionMode,
            onSave: onSave
        )

        DemoLog.print("ReminderListViewController", "openDetail", "presentationMode: \(presentationMode.rawValue), saveActionMode: \(saveActionMode.rawValue), closureCaptureMode: \(closureCaptureMode.rawValue), selectedReminder: \(formatReminder(selectedReminder))")

        switch presentationMode {
        case .show:
            show(detailViewController, sender: self)
        case .push:
            navigationController?.pushViewController(detailViewController, animated: true)
        case .present:
            let navigationController = UINavigationController(rootViewController: detailViewController)
            present(navigationController, animated: true)
        }

        printNavigationStack(from: self, "after requesting \(presentationMode.readableName)")
    }

    private func runSnapshotExperiment(_ updateMode: SnapshotUpdateMode) {
        guard let firstReminder = displayedReminders.first else {
            DemoLog.print("ReminderListViewController", "runSnapshotExperiment", "no visible item")
            return
        }

        DemoLog.print("ReminderListViewController", "runSnapshotExperiment", "mode: \(updateMode.rawValue), reminder: \(formatReminder(firstReminder))")
        update(firstReminder.id, with: "\(firstReminder.title) *", updateMode: updateMode)
    }

    private func toggleSaveActionMode() {
        saveActionMode.toggle()
        DemoLog.print("ReminderListViewController", "toggleSaveActionMode", "next detail pages use: \(saveActionMode.rawValue)")
        setupNavigation()
    }

    private func toggleClosureCaptureMode() {
        closureCaptureMode.toggle()
        DemoLog.print("ReminderListViewController", "toggleClosureCaptureMode", "next detail pages use: \(closureCaptureMode.rawValue)")
        setupNavigation()
    }

    private func loadReuseExperimentItems() {
        reminders = .reuseExperimentReminders()
        selectedFilter = .all
        filterControl.selectedSegmentIndex = selectedFilter.rawValue
        DemoLog.print("ReminderListViewController", "loadReuseExperimentItems", "loaded \(reminders.count) reminders. Scroll to observe init, prepareForReuse, and updateConfiguration.")
        applyCurrentSnapshot()
    }

    private func showStringIdentityExperiment() {
        DemoLog.print("ReminderListViewController", "showStringIdentityExperiment", "push String identity comparison page")
        navigationController?.pushViewController(StringIdentityExperimentViewController(), animated: true)
    }

    private func showManualCollectionVersion() {
        DemoLog.print("ReminderListViewController", "showManualCollectionVersion", "push manual UIViewController version")
        navigationController?.pushViewController(ManualCollectionViewController(), animated: true)
    }

    private static func initialLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        return UICollectionViewCompositionalLayout.list(using: configuration)
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
        DemoLog.print("ReminderProgressView", "layoutSubviews", "bounds: \(bounds), progress: \(storedProgress)")
        fillView.frame = CGRect(x: 0, y: 0, width: bounds.width * storedProgress, height: bounds.height)
        layer.cornerRadius = bounds.height / 2
        fillView.layer.cornerRadius = bounds.height / 2
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        DemoLog.print("ReminderProgressView", "draw", "rect: \(rect)")

        let borderPath = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: bounds.height / 2)
        UIColor.separator.setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()
    }
}
