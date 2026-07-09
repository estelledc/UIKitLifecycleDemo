import UIKit

final class ReminderDetailViewController: UIViewController {
    private let reminderTitle: String
    private let onSave: (String) -> Void

    private let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.placeholder = "Reminder title"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    init(reminderTitle: String, onSave: @escaping (String) -> Void) {
        self.reminderTitle = reminderTitle
        self.onSave = onSave
        print("[ReminderDetailViewController] init(reminderTitle:onSave:) - reminderTitle: \(reminderTitle)")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not used in UIKitLifecycleDemo")
    }

    deinit {
        print("[ReminderDetailViewController] deinit - detail controller released")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[ReminderDetailViewController] viewDidLoad - initial text: \(reminderTitle)")

        setupNavigation()
        setupTextField()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[ReminderDetailViewController] viewWillAppear - detail is about to appear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[ReminderDetailViewController] viewDidAppear - detail is visible")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("[ReminderDetailViewController] viewWillDisappear - detail is about to disappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("[ReminderDetailViewController] viewDidDisappear - detail disappeared")
    }

    // Save 按钮通过 target-action 让 UIKit 在点击时调用 saveReminder。
    private func setupNavigation() {
        title = "Edit Reminder"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveReminder)
        )
    }

    // 文本框显示列表页传进来的 title，方便修改后回传。
    private func setupTextField() {
        view.backgroundColor = .systemBackground
        textField.text = reminderTitle
        textField.delegate = self

        view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    @objc private func saveReminder() {
        let rawText = textField.text ?? ""
        let editedTitle = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleToSave = editedTitle.isEmpty ? reminderTitle : editedTitle

        print("[ReminderDetailViewController] saveReminder - rawText: \(rawText), titleToSave: \(titleToSave)")
        print("[ReminderDetailViewController] saveReminder - about to call onSave")
        onSave(titleToSave)

        print("[ReminderDetailViewController] saveReminder - about to popViewController")
        navigationController?.popViewController(animated: true)
    }
}

extension ReminderDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
