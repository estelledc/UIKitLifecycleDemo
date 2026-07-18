import UIKit

final class DemoLogPanelViewController: UITableViewController {
    private enum Filter: Equatable {
        case all
        case category(DemoLogCategory)

        var title: String {
            switch self {
            case .all:
                return "All"
            case .category(let category):
                return category.title
            }
        }
    }

    private let filterButton = UIButton(type: .system)
    private let onlyKeyEventsSwitch = UISwitch()
    private let headerStack = UIStackView()
    private let searchController = UISearchController(searchResultsController: nil)
    private var pauseScrollButton: UIBarButtonItem?
    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private var selectedFilter: Filter = .all
    private var isAutoScrollPaused = false
    private var visibleEvents: [DemoLogEvent] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        view.accessibilityIdentifier = "demoLogPanel"

        setupNavigation()
        setupHeader()
        setupTableView()
        setupSearch()
        reloadEvents(scrollToBottom: true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(logStoreDidChange),
            name: .demoLogStoreDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        let closeButton = UIBarButtonItem(title: "Done", primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        closeButton.accessibilityIdentifier = "closeLogsButton"
        navigationItem.leftBarButtonItem = closeButton

        let clearButton = UIBarButtonItem(title: "Clear", primaryAction: UIAction { [weak self] _ in
            DemoLogStore.shared.clear()
            self?.reloadEvents(scrollToBottom: false)
        })
        clearButton.accessibilityIdentifier = "clearLogsButton"

        let copyButton = UIBarButtonItem(title: "Copy", primaryAction: UIAction { [weak self] _ in
            self?.copyVisibleLogs()
        })
        copyButton.accessibilityIdentifier = "copyVisibleLogsButton"

        let pauseButton = UIBarButtonItem(
            title: "Pause Scroll",
            style: .plain,
            target: self,
            action: #selector(toggleAutoScroll)
        )
        pauseButton.accessibilityIdentifier = "pauseLogsButton"
        pauseScrollButton = pauseButton

        navigationItem.rightBarButtonItems = [copyButton, clearButton, pauseButton]
    }

    private func setupHeader() {
        filterButton.accessibilityIdentifier = "logFilterButton"
        filterButton.showsMenuAsPrimaryAction = true
        filterButton.contentHorizontalAlignment = .leading
        filterButton.setContentHuggingPriority(.required, for: .horizontal)
        updateFilterMenu()

        let keyLabel = UILabel()
        keyLabel.text = "Only Key Events"
        keyLabel.font = .preferredFont(forTextStyle: .subheadline)
        keyLabel.textColor = .secondaryLabel

        onlyKeyEventsSwitch.accessibilityIdentifier = "onlyKeyEventsSwitch"
        onlyKeyEventsSwitch.addTarget(self, action: #selector(onlyKeyEventsChanged), for: .valueChanged)

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 12
        headerStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.addArrangedSubview(filterButton)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(keyLabel)
        headerStack.addArrangedSubview(onlyKeyEventsSwitch)
        tableView.tableHeaderView = headerStack
    }

    private func setupTableView() {
        tableView.accessibilityIdentifier = "demoLogPanel"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LogCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.separatorStyle = .singleLine
    }

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search owner, method, message"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerStack.systemLayoutSizeFitting(targetSize).height
        if tableView.tableHeaderView?.frame.height != height {
            headerStack.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
            tableView.tableHeaderView = headerStack
        }
    }

    private func updateFilterMenu() {
        let allAction = UIAction(title: "All", state: selectedFilter == .all ? .on : .off) { [weak self] _ in
            self?.selectedFilter = .all
            self?.updateFilterMenu()
            self?.reloadEvents(scrollToBottom: true)
        }

        let categoryActions = DemoLogCategory.allCases.map { category in
            UIAction(
                title: category.title,
                state: selectedFilter == .category(category) ? .on : .off
            ) { [weak self] _ in
                self?.selectedFilter = .category(category)
                self?.updateFilterMenu()
                self?.reloadEvents(scrollToBottom: true)
            }
        }

        filterButton.setTitle("Filter: \(selectedFilter.title)", for: .normal)
        filterButton.menu = UIMenu(children: [allAction] + categoryActions)
    }

    @objc private func onlyKeyEventsChanged() {
        reloadEvents(scrollToBottom: true)
    }

    @objc private func logStoreDidChange() {
        reloadEvents(scrollToBottom: !isAutoScrollPaused)
    }

    @objc private func toggleAutoScroll() {
        isAutoScrollPaused.toggle()
        pauseScrollButton?.title = isAutoScrollPaused ? "Resume Scroll" : "Pause Scroll"
        if !isAutoScrollPaused {
            scrollToBottom()
        }
    }

    private func reloadEvents(scrollToBottom shouldScrollToBottom: Bool) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        visibleEvents = DemoLogStore.shared.events.filter { event in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .category(let category):
                matchesFilter = event.category == category
            }

            let matchesKey = !onlyKeyEventsSwitch.isOn || event.isKeyEvent
            let matchesSearch = query.isEmpty
                || event.owner.lowercased().contains(query)
                || event.method.lowercased().contains(query)
                || event.message.lowercased().contains(query)

            return matchesFilter && matchesKey && matchesSearch
        }

        tableView.reloadData()
        if shouldScrollToBottom {
            scrollToBottom()
        }
    }

    private func scrollToBottom() {
        guard !visibleEvents.isEmpty else { return }
        let indexPath = IndexPath(row: visibleEvents.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func copyVisibleLogs() {
        let copiedText = visibleEvents
            .map { event in
                "#\(event.sequence) [\(event.category.title)] \(event.consoleLine)"
            }
            .joined(separator: "\n")
        UIPasteboard.general.string = copiedText

        let alert = UIAlertController(title: "Copied", message: "Visible logs are on the pasteboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleEvents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = visibleEvents[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)

        var content = UIListContentConfiguration.subtitleCell()
        content.text = "#\(event.sequence) \(timestampFormatter.string(from: event.timestamp)) [\(event.category.title)] \(event.owner).\(event.method)"
        content.secondaryText = event.message
        content.textProperties.font = .preferredFont(forTextStyle: .caption1)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.backgroundColor = event.isKeyEvent ? UIColor.systemYellow.withAlphaComponent(0.18) : .systemBackground
        cell.accessibilityIdentifier = "logEvent_\(event.sequence)"
        return cell
    }
}

extension DemoLogPanelViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        reloadEvents(scrollToBottom: false)
    }
}
