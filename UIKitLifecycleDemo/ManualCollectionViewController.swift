import UIKit

final class ManualCollectionViewController: UIViewController {
    private var reminders = [Reminder].initialDemoReminders
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Reminder>!

    override func viewDidLoad() {
        super.viewDidLoad()
        DemoLog.print("ManualCollectionViewController", "viewDidLoad", "UIViewController must create collectionView manually")
        title = "Manual Collection"
        view.backgroundColor = .systemGroupedBackground
        setupCollectionView()
        configureDataSource()
        applySnapshot()
    }

    private func setupCollectionView() {
        DemoLog.print("ManualCollectionViewController", "setupCollectionView", "create layout, collectionView, delegate, and Auto Layout constraints")
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.listLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "manualCollectionView"
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private static func listLayout() -> UICollectionViewLayout {
        DemoLog.print("ManualCollectionViewController", "listLayout", "manual UIViewController also needs a layout")
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func configureDataSource() {
        DemoLog.print("ManualCollectionViewController", "configureDataSource", "manual UIViewController also needs a dataSource")
        let registration = UICollectionView.CellRegistration<ReminderCell, Reminder> { cell, indexPath, reminder in
            DemoLog.print("ManualCollectionViewController", "CellRegistration", "indexPath: \(indexPath), reminder: \(formatReminder(reminder))")
            var content = cell.defaultContentConfiguration()
            content.text = reminder.title
            content.secondaryText = "\(reminder.dueBucket.rawValue) - manual version"
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Reminder>(collectionView: collectionView) { collectionView, indexPath, reminder in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: reminder)
        }
    }

    private func applySnapshot() {
        DemoLog.print("ManualCollectionViewController", "applySnapshot", "reminders: \(formatReminders(reminders))")
        var snapshot = NSDiffableDataSourceSnapshot<Section, Reminder>()
        snapshot.appendSections([.main])
        snapshot.appendItems(reminders)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension ManualCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let reminder = dataSource.itemIdentifier(for: indexPath) else { return }
        DemoLog.print("ManualCollectionViewController", "collectionView(_:didSelectItemAt:)", "indexPath: \(indexPath), reminder: \(formatReminder(reminder))")
    }
}
