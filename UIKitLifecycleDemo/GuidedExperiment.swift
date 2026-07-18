import Foundation

struct GuidedExperiment {
  let id: String
  let steps: [GuidedStep]

  static let coreTour = GuidedExperiment(
    id: "core-tour",
    steps: [
      GuidedStep(
        id: "launch-lifecycle",
        title: "1. 启动生命周期",
        action: "启动 App，不点击列表；打开 Logs。",
        observe: "Lifecycle：viewDidLoad → viewWillAppear → viewDidAppear",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor: "override func viewDidLoad()",
        xcodeAction: "在 viewDidLoad 首行打断点；命中后查看当前线程调用栈。"
      ),
      GuidedStep(
        id: "tap-cell",
        title: "2. 点击 cell",
        action: "关闭 Guide，点击 Buy groceries。",
        observe: "Delegate 后接 Detail 生命周期",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor:
          "override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)",
        xcodeAction: "在 didSelectItemAt 打断点；点击 cell 后看调用栈。"
      ),
      GuidedStep(
        id: "save",
        title: "3. Save",
        action: "点 Use Example Title，再点 Save。",
        observe: "Action → Closure",
        sourceFile: "ReminderDetailViewController.swift",
        sourceAnchor: "@objc private func saveReminder()",
        xcodeAction: "在 saveReminder 打断点；Step Over 到 onSave。"
      ),
      GuidedStep(
        id: "pop-back",
        title: "4. 返回 List",
        action: "Save 后停住，观察 Detail 消失。",
        observe: "Snapshot / NavStack / Memory",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor:
          "private func openDetail(for selectedReminder: Reminder, using presentationMode: DetailPresentationMode)",
        xcodeAction: "在 onSave closure 打断点；继续运行并确认 Detail deinit。"
      ),
      GuidedStep(
        id: "cell-reuse",
        title: "5. Cell reuse",
        action: "Experiments → Load 50 Reuse Items；上下滚动。",
        observe: "Cell：init / updateConfiguration / prepareForReuse",
        sourceFile: "ReminderCell.swift",
        sourceAnchor: "override func prepareForReuse()",
        xcodeAction: "给 prepareForReuse 加 Symbolic Breakpoint；滚动列表。"
      ),
      GuidedStep(
        id: "snapshot-update",
        title: "6. Snapshot 更新",
        action: "依次运行 Full Apply、Reload、Reconfigure。",
        observe: "Snapshot 与 Cell 日志次数",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor: "private func runSnapshotExperiment(_ updateMode: SnapshotUpdateMode)",
        xcodeAction: "在 runSnapshotExperiment 打断点；比较三次调用路径。"
      ),
      GuidedStep(
        id: "presentation",
        title: "7. Show / Push / Present",
        action: "分别打开三种 Detail。",
        observe: "NavStack 与 Lifecycle",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor:
          "private func openDetail(for selectedReminder: Reminder, using presentationMode: DetailPresentationMode)",
        xcodeAction: "在 switch presentationMode 打断点；比较栈和返回方式。"
      ),
      GuidedStep(
        id: "closure-memory",
        title: "8. Closure memory",
        action: "Toggle Closure；打开 Detail、保存并返回。",
        observe: "Closure 与 Memory：是否出现 deinit",
        sourceFile: "ReminderListViewController.swift",
        sourceAnchor: "private func toggleClosureCaptureMode()",
        xcodeAction: "返回后打开 Debug Memory Graph；检查引用路径。"
      ),
      GuidedStep(
        id: "manual-collection",
        title: "9. 手动 CollectionView",
        action: "打开 Manual UIViewController Version。",
        observe: "Lifecycle / DataSource / Layout",
        sourceFile: "ManualCollectionViewController.swift",
        sourceAnchor: "private func setupCollectionView()",
        xcodeAction: "在 setupCollectionView 打断点；逐步看创建、约束和 dataSource。"
      ),
    ]
  )
}

struct GuidedStep {
  let id: String
  let title: String
  let action: String
  let observe: String
  let sourceFile: String
  let sourceAnchor: String
  let xcodeAction: String
}
