import UIKit

final class StringIdentityExperimentViewController: UICollectionViewController {
    private let items = ["Walk dog", "Walk dog", "Read UIKit docs"]
    private var dataSource: UICollectionViewDiffableDataSource<Section, String>!

    init() {
        DemoLog.print("StringIdentityExperiment", "init", "items: \(items)")
        super.init(collectionViewLayout: Self.listLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DemoLog.print("StringIdentityExperiment", "viewDidLoad", "String mode intentionally contains duplicate titles")
        title = "String Identity"
        collectionView.backgroundColor = .systemGroupedBackground
        configureDataSource()
        applyUnsafeSnapshot()
    }

    private static func listLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, indexPath, title in
            DemoLog.print("StringIdentityExperiment", "CellRegistration", "indexPath: \(indexPath), title: \(title)")
            var content = cell.defaultContentConfiguration()
            content.text = title
            content.secondaryText = "String itself is the item identity"
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) { collectionView, indexPath, title in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: title)
        }
    }

    private func applyUnsafeSnapshot() {
        DemoLog.print("StringIdentityExperiment", "applyUnsafeSnapshot", "about to append duplicate String identifiers: \(items)")
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])

        var seen = Set<String>()
        let duplicates = items.filter { !seen.insert($0).inserted }
        if duplicates.isEmpty {
            snapshot.appendItems(items)
        } else {
            DemoLog.print("StringIdentityExperiment", "applyUnsafeSnapshot", "duplicate identifiers found: \(duplicates). DiffableDataSource requires unique item identifiers, so this page shows the risk instead of crashing the teaching app.")
            snapshot.appendItems(Array(dictatingUniqueOrderFrom: items))
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension Array where Element: Hashable {
    init(dictatingUniqueOrderFrom values: [Element]) {
        var seen = Set<Element>()
        self = values.filter { seen.insert($0).inserted }
    }
}
