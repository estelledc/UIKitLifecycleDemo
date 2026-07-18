import UIKit

final class GuidedExperimentViewController: UIViewController {
  private let experiment: GuidedExperiment
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let progressLabel = UILabel()
  private let stepTitleLabel = UILabel()
  private let actionLabel = UILabel()
  private let observeLabel = UILabel()
  private let sourceLabel = UILabel()
  private let xcodeLabel = UILabel()
  private let previousButton = UIButton(type: .system)
  private let nextButton = UIButton(type: .system)
  private var stepIndex = 0

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

    DemoLog.print(
      "GuidedExperimentViewController", "viewDidLoad", "open guide: \(experiment.id)",
      category: .guide)

    setupNavigation()
    setupLayout()
    buildContent()
    renderCurrentStep()
  }

  private func setupNavigation() {
    navigationItem.largeTitleDisplayMode = .never
    let closeButton = UIBarButtonItem(
      title: "Done",
      primaryAction: UIAction { [weak self] _ in
        self?.dismiss(animated: true)
      })
    closeButton.accessibilityIdentifier = "closeGuideButton"
    navigationItem.leftBarButtonItem = closeButton
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Logs",
      primaryAction: UIAction { [weak self] _ in
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
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
    ])
  }

  private func buildContent() {
    let card = UIView()
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.accessibilityIdentifier = "guideCurrentStepCard"

    let cardStack = UIStackView()
    cardStack.translatesAutoresizingMaskIntoConstraints = false
    cardStack.axis = .vertical
    cardStack.spacing = 12
    cardStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    cardStack.isLayoutMarginsRelativeArrangement = true

    configureLabel(progressLabel, style: .caption1, color: .secondaryLabel, id: "guideProgress")
    configureLabel(stepTitleLabel, style: .headline, color: .label, id: "guideStepTitle")
    configureLabel(actionLabel, style: .body, color: .label, id: "guideAction")
    configureLabel(observeLabel, style: .body, color: .label, id: "guideObserve")
    configureLabel(sourceLabel, style: .footnote, color: .secondaryLabel, id: "guideSourceCue")
    configureLabel(xcodeLabel, style: .body, color: .label, id: "guideXcodeAction")

    for label in [
      progressLabel, stepTitleLabel, actionLabel, observeLabel, sourceLabel, xcodeLabel,
    ] {
      cardStack.addArrangedSubview(label)
    }
    card.addSubview(cardStack)
    NSLayoutConstraint.activate([
      cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      cardStack.topAnchor.constraint(equalTo: card.topAnchor),
      cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    previousButton.configuration = .bordered()
    previousButton.configuration?.title = "Previous"
    previousButton.accessibilityIdentifier = "guidePreviousButton"
    previousButton.addAction(
      UIAction { [weak self] _ in self?.moveStep(by: -1) }, for: .touchUpInside)

    nextButton.configuration = .borderedProminent()
    nextButton.configuration?.title = "Next"
    nextButton.accessibilityIdentifier = "guideNextButton"
    nextButton.addAction(UIAction { [weak self] _ in self?.moveStep(by: 1) }, for: .touchUpInside)

    let buttonStack = UIStackView(arrangedSubviews: [previousButton, nextButton])
    buttonStack.axis = .horizontal
    buttonStack.spacing = 12
    buttonStack.distribution = .fillEqually

    let docsLabel = makeLabel(
      "Full steps: docs/guided-learning.md", style: .footnote, color: .secondaryLabel)
    docsLabel.accessibilityIdentifier = "guideDocsCue"

    for view in [card, buttonStack, docsLabel] {
      contentStack.addArrangedSubview(view)
    }
  }

  private func renderCurrentStep() {
    let step = experiment.steps[stepIndex]
    progressLabel.text = "\(stepIndex + 1) / \(experiment.steps.count)"
    stepTitleLabel.text = step.title
    actionLabel.text = "Do · \(step.action)"
    observeLabel.text = "Watch · \(step.observe)"
    sourceLabel.text = "Code · ⌘⇧O \(step.sourceFile)\n\(step.sourceAnchor)"
    xcodeLabel.text = "Xcode · \(step.xcodeAction)"
    previousButton.isEnabled = stepIndex > 0
    nextButton.isEnabled = stepIndex < experiment.steps.count - 1
  }

  private func moveStep(by offset: Int) {
    let nextIndex = stepIndex + offset
    guard experiment.steps.indices.contains(nextIndex) else { return }
    stepIndex = nextIndex
    renderCurrentStep()
    scrollView.setContentOffset(.zero, animated: true)
  }

  private func configureLabel(
    _ label: UILabel,
    style: UIFont.TextStyle,
    color: UIColor,
    id: String
  ) {
    label.font = .preferredFont(forTextStyle: style)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = color
    label.numberOfLines = 0
    label.accessibilityIdentifier = id
  }

  private func makeLabel(_ text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
    let label = UILabel()
    configureLabel(label, style: style, color: color, id: "")
    label.text = text
    return label
  }

  private func openLogs() {
    DemoLog.print(
      "GuidedExperimentViewController", "openLogs", "open logs from guide", category: .guide,
      isKeyEvent: false)
    let logPanel = UINavigationController(rootViewController: DemoLogPanelViewController())
    present(logPanel, animated: true)
  }
}
