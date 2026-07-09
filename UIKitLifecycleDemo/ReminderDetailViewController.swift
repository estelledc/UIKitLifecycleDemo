import UIKit

final class ReminderDetailViewController: UIViewController {
    private let reminderTitle: String
    private let presentationMode: DetailPresentationMode
    private let saveActionMode: SaveActionMode
    private let onSave: (String) -> Void

    private let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.placeholder = "Reminder title"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "titleTextField"
        return textField
    }()

    private lazy var useExampleTitleButton: UIButton = {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Use Example Title"
        configuration.image = UIImage(systemName: "text.cursor")
        configuration.imagePadding = 8

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "useExampleTitleButton"
        button.addTarget(self, action: #selector(useExampleTitle), for: .touchUpInside)
        return button
    }()

    init(
        reminderTitle: String,
        presentationMode: DetailPresentationMode,
        saveActionMode: SaveActionMode,
        onSave: @escaping (String) -> Void
    ) {
        self.reminderTitle = reminderTitle
        self.presentationMode = presentationMode
        self.saveActionMode = saveActionMode
        self.onSave = onSave
        DemoLog.print("ReminderDetailViewController", "init(reminderTitle:onSave:)", "reminderTitle: \(reminderTitle), presentationMode: \(presentationMode.rawValue), saveActionMode: \(saveActionMode.rawValue)")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    deinit {
        DemoLog.print("ReminderDetailViewController", "deinit", "detail controller released")
    }

    override func loadView() {
        DemoLog.print("ReminderDetailViewController", "loadView", "before super, isViewLoaded: \(isViewLoaded)")
        super.loadView()
        DemoLog.print("ReminderDetailViewController", "loadView", "after super, isViewLoaded: \(isViewLoaded), view type: \(type(of: view!))")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DemoLog.print("ReminderDetailViewController", "viewDidLoad", "isViewLoaded: \(isViewLoaded), view type: \(type(of: view!)), initial text: \(reminderTitle)")

        setupNavigation()
        setupTextField()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DemoLog.print("ReminderDetailViewController", "viewWillAppear", "detail is about to appear, navigationController exists: \(navigationController != nil), presentingViewController exists: \(presentingViewController != nil)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DemoLog.print("ReminderDetailViewController", "viewDidAppear", "detail is visible, presentationStyle: \(presentationMode.rawValue)")
        printNavigationStack(from: self, "after detail appears")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DemoLog.print("ReminderDetailViewController", "viewWillDisappear", "detail is about to disappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DemoLog.print("ReminderDetailViewController", "viewDidDisappear", "detail disappeared")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DemoLog.print("ReminderDetailViewController", "viewWillLayoutSubviews", "view.bounds: \(view.bounds), safeAreaInsets: \(view.safeAreaInsets)")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DemoLog.print("ReminderDetailViewController", "viewDidLayoutSubviews", "view.bounds: \(view.bounds), safeAreaInsets: \(view.safeAreaInsets), textField.frame: \(textField.frame)")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        DemoLog.print("ReminderDetailViewController", "viewSafeAreaInsetsDidChange", "safeAreaInsets: \(view.safeAreaInsets)")
    }

    // Save 按钮通过 target-action 或 UIAction 让 UIKit 在点击时调用 saveReminder。
    private func setupNavigation() {
        title = "Edit Reminder"
        navigationItem.largeTitleDisplayMode = .never

        let saveButton: UIBarButtonItem
        switch saveActionMode {
        case .targetAction:
            saveButton = UIBarButtonItem(
                barButtonSystemItem: .save,
                target: self,
                action: #selector(saveReminder)
            )
            DemoLog.print("ReminderDetailViewController", "setupNavigation", "Save uses target-action and #selector(saveReminder)")
        case .uiAction:
            saveButton = UIBarButtonItem(
                title: "Save",
                primaryAction: UIAction { [weak self] _ in
                    DemoLog.print("ReminderDetailViewController", "UIAction", "closure received button tap, about to call saveReminder")
                    self?.saveReminder()
                }
            )
            DemoLog.print("ReminderDetailViewController", "setupNavigation", "Save uses UIAction closure")
        }

        saveButton.accessibilityIdentifier = "saveButton"
        navigationItem.rightBarButtonItem = saveButton

        if presentationMode == .present {
            navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
                DemoLog.print("ReminderDetailViewController", "cancel", "dismiss presented navigation controller")
                self?.dismiss(animated: true)
            })
        }
    }

    // 文本框显示列表页传进来的 title；示例按钮减少教学时的键盘噪声。
    private func setupTextField() {
        view.backgroundColor = .systemBackground
        textField.text = reminderTitle
        textField.delegate = self

        let stack = UIStackView(arrangedSubviews: [textField, useExampleTitleButton])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    @objc private func useExampleTitle() {
        textField.text = "Buy groceries today"
        DemoLog.print("ReminderDetailViewController", "useExampleTitle", "set textField.text to Buy groceries today", category: .action, isKeyEvent: true)
    }

    @objc private func saveReminder() {
        let rawText = textField.text ?? ""
        let editedTitle = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleToSave = editedTitle.isEmpty ? reminderTitle : editedTitle

        DemoLog.print("ReminderDetailViewController", "saveReminder", "rawText: \(rawText), titleToSave: \(titleToSave), presentationMode: \(presentationMode.rawValue)")
        DemoLog.print("ReminderDetailViewController", "saveReminder", "about to call onSave")
        onSave(titleToSave)

        switch presentationMode {
        case .show, .push:
            DemoLog.print("ReminderDetailViewController", "saveReminder", "about to popViewController")
            printNavigationStack(from: self, "before pop")
            navigationController?.popViewController(animated: true)
        case .present:
            DemoLog.print("ReminderDetailViewController", "saveReminder", "about to dismiss presented navigation controller")
            dismiss(animated: true)
        }
    }
}

extension ReminderDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
