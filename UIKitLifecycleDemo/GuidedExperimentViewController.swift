import UIKit

final class GuidedExperimentViewController: UIViewController {
    private let experiment: GuidedExperiment
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(experiment: GuidedExperiment = .coreTour) {
        self.experiment = experiment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Guide"
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "guidedExperimentView"

        DemoLog.print("GuidedExperimentViewController", "viewDidLoad", "open guide: \(experiment.id)", category: .guide)

        setupNavigation()
        setupLayout()
        buildContent()
    }

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        let closeButton = UIBarButtonItem(title: "Done", primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        closeButton.accessibilityIdentifier = "closeGuideButton"
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logs", primaryAction: UIAction { [weak self] _ in
            self?.openLogs()
        })
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "openLogsFromGuideButton"
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "guidedExperimentView"
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 24, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func buildContent() {
        contentStack.addArrangedSubview(makeIntroView())
        experiment.steps.forEach { step in
            contentStack.addArrangedSubview(makeCard(for: step))
        }
    }

    private func makeIntroView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.text = experiment.title
        titleLabel.numberOfLines = 0

        let goalLabel = UILabel()
        goalLabel.font = .preferredFont(forTextStyle: .body)
        goalLabel.adjustsFontForContentSizeCategory = true
        goalLabel.textColor = .secondaryLabel
        goalLabel.text = experiment.goal
        goalLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(goalLabel)
        return stack
    }

    private func makeCard(for step: GuidedStep) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 8
        card.accessibilityIdentifier = "guideStepCard_\(step.id)"

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        stack.addArrangedSubview(makeLabel(step.title, style: .headline, color: .label))
        stack.addArrangedSubview(makeSection(title: "当前做什么", body: step.instruction))
        stack.addArrangedSubview(makeSection(title: "应该看哪里", body: step.lookAt))
        stack.addArrangedSubview(makeSection(title: "操作前预测", body: step.predictionQuestion))
        stack.addArrangedSubview(makeSection(title: "预期日志", body: step.expectedLogs.map { "• \($0)" }.joined(separator: "\n")))
        stack.addArrangedSubview(makeSection(title: "完成后问题", body: step.understandingQuestion))
        stack.addArrangedSubview(makeSection(title: "一句话复盘", body: step.recap))
        stack.addArrangedSubview(makeSection(title: "胜利条件", body: step.victoryCondition))

        return card
    }

    private func makeSection(title: String, body: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 3
        stack.addArrangedSubview(makeLabel(title, style: .caption1, color: .secondaryLabel))
        stack.addArrangedSubview(makeLabel(body, style: .body, color: .label))
        return stack
    }

    private func makeLabel(_ text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.text = text
        label.numberOfLines = 0
        return label
    }

    private func openLogs() {
        DemoLog.print("GuidedExperimentViewController", "openLogs", "open logs from guide", category: .guide, isKeyEvent: false)
        let logPanel = UINavigationController(rootViewController: DemoLogPanelViewController())
        present(logPanel, animated: true)
    }
}
