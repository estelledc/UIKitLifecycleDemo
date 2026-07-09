import Foundation

struct GuidedExperiment {
    let id: String
    let title: String
    let goal: String
    let steps: [GuidedStep]

    static let coreTour = GuidedExperiment(
        id: "core-tour",
        title: "5-minute UIKit Core Tour",
        goal: "按启动、点击、保存、返回四步，亲眼观察 UIKit 自动调用链路。",
        steps: [
            GuidedStep(
                id: "launch-lifecycle",
                title: "Step 1: 启动生命周期",
                instruction: "先不要点任何 cell，只打开 Logs，观察 List 页面第一次出现。",
                lookAt: "Logs -> Lifecycle / List",
                predictionQuestion: "viewDidLoad 是 controller 一创建就调用，还是 view 加载完成后调用？",
                expectedLogs: [
                    "ReminderListViewController init",
                    "loadView",
                    "viewDidLoad",
                    "viewWillAppear",
                    "viewDidAppear"
                ],
                understandingQuestion: "viewDidLoad 和 viewWillAppear 的区别是什么？",
                recap: "viewDidLoad 只说明 view 第一次加载完成，viewWillAppear 说明页面即将出现在屏幕上。",
                victoryCondition: "能说出 viewDidLoad 不会在每次返回 List 时重复执行。"
            ),
            GuidedStep(
                id: "tap-cell",
                title: "Step 2: 点击 cell",
                instruction: "回到列表页，点击第一条 Buy groceries。",
                lookAt: "Logs -> Delegate / Detail / Lifecycle",
                predictionQuestion: "点击 cell 后，先出现 didSelectItemAt，还是 Detail viewDidLoad？",
                expectedLogs: [
                    "collectionView(_:didSelectItemAt:)",
                    "ReminderDetailViewController init",
                    "ReminderDetailViewController viewDidLoad"
                ],
                understandingQuestion: "didSelectItemAt 是普通方法，还是 UIKit 触发的 delegate 回调？",
                recap: "用户点 cell 后，UIKit 把点击转换成 collection view 的 delegate 回调。",
                victoryCondition: "能说出 didSelectItemAt 是 UIKit 捕获点击后触发的 delegate 回调。"
            ),
            GuidedStep(
                id: "save",
                title: "Step 3: Save",
                instruction: "在 Detail 页修改标题，点击 Save。",
                lookAt: "Logs -> Action / Closure",
                predictionQuestion: "Save 是 List 调用的吗，还是按钮机制触发 Detail 的方法？",
                expectedLogs: [
                    "saveReminder",
                    "about to call onSave"
                ],
                understandingQuestion: "target-action / UIAction 和 onSave closure 分别负责什么？",
                recap: "Save 由按钮事件触发；onSave closure 是 Detail 把数据交回 List 的通道。",
                victoryCondition: "能说出 Save 是 target-action 或 UIAction 触发的。"
            ),
            GuidedStep(
                id: "pop-back",
                title: "Step 4: pop 回 List",
                instruction: "保存后不要继续点击，观察 Detail 消失和 List 重新出现。",
                lookAt: "Logs -> Closure / Snapshot / NavStack / Memory",
                predictionQuestion: "返回 List 时，List.viewDidLoad 会不会再次出现？",
                expectedLogs: [
                    "onSave closure",
                    "update(_:with:)",
                    "applyCurrentSnapshot",
                    "popViewController",
                    "List viewWillAppear",
                    "Detail deinit"
                ],
                understandingQuestion: "为什么 viewWillAppear 会再次出现，但 viewDidLoad 不会？",
                recap: "List 没有重新加载 view，只是重新显示；Detail pop 后释放，所以会看到 deinit。",
                victoryCondition: "能说出 viewDidLoad 一次、viewWillAppear 多次、deinit 代表释放。"
            ),
            GuidedStep(
                id: "cell-reuse",
                title: "Step 5: Cell reuse",
                instruction: "打开 Learn -> Experiments -> Load 50 Reuse Items，然后上下滚动列表。",
                lookAt: "Logs -> Cell",
                predictionQuestion: "滚动时，UIKit 会一直创建新 cell，还是复用旧 cell？",
                expectedLogs: [
                    "ReminderCell init",
                    "updateConfiguration(using:)",
                    "prepareForReuse"
                ],
                understandingQuestion: "prepareForReuse 出现时，说明 cell 发生了什么？",
                recap: "collection view 会复用离开屏幕的 cell，再用新数据重新配置它。",
                victoryCondition: "能说出 cell 本体可复用，显示内容由配置决定。"
            ),
            GuidedStep(
                id: "snapshot-update",
                title: "Step 6: Snapshot 更新",
                instruction: "依次运行 Learn -> Experiments -> Snapshot 里的 Full Apply、Reload Item、Reconfigure Item。",
                lookAt: "Logs -> Snapshot / Cell",
                predictionQuestion: "改一条数据时，必须重建整个列表吗？",
                expectedLogs: [
                    "runSnapshotExperiment",
                    "applyCurrentSnapshot",
                    "reloadItems",
                    "reconfigureItems"
                ],
                understandingQuestion: "Full Apply、Reload、Reconfigure 哪个更像“只更新展示内容”？",
                recap: "snapshot 描述当前显示哪些 item；reload/reconfigure 是更局部的刷新方式。",
                victoryCondition: "能说出 snapshot 管数据集合，cell registration 管显示配置。"
            ),
            GuidedStep(
                id: "presentation",
                title: "Step 7: Show / Push / Present",
                instruction: "分别运行 Learn -> Experiments -> Open Detail 里的 Show、Push、Present。",
                lookAt: "Logs -> NavStack / Lifecycle",
                predictionQuestion: "Present 出来的 Detail 会不会进入原来的 navigation stack？",
                expectedLogs: [
                    "before show / push / present",
                    "after requesting show / push / present",
                    "detail viewDidAppear"
                ],
                understandingQuestion: "push 和 present 的返回方式为什么不同？",
                recap: "push/show 走 navigation stack；present 是模态展示，保存后 dismiss。",
                victoryCondition: "能从 NavStack 日志区分 push/show 与 present。"
            ),
            GuidedStep(
                id: "closure-memory",
                title: "Step 8: Closure memory",
                instruction: "切换 Learn -> Experiments -> Toggle Closure，再打开详情页并保存返回。",
                lookAt: "Logs -> Closure / Memory",
                predictionQuestion: "强捕获 self 会不会影响 Detail 或 List 的释放时机？",
                expectedLogs: [
                    "toggleClosureCaptureMode",
                    "onSave closure",
                    "deinit"
                ],
                understandingQuestion: "为什么学习 closure 时要同时观察 deinit？",
                recap: "closure 是业务回传通道；内存实验要用 deinit 和 Memory Graph 一起判断引用是否释放。",
                victoryCondition: "能说出 closure 回传数据和 UIKit 生命周期不是同一件事。"
            ),
            GuidedStep(
                id: "manual-collection",
                title: "Step 9: 手动 CollectionView 对照",
                instruction: "打开 Learn -> Experiments -> Manual UIViewController Version，对照 UICollectionViewController 版本。",
                lookAt: "Logs -> Lifecycle / DataSource / Layout",
                predictionQuestion: "不继承 UICollectionViewController 时，collectionView 还会自动存在吗？",
                expectedLogs: [
                    "ManualCollectionViewController",
                    "setupCollectionView",
                    "configureDataSource"
                ],
                understandingQuestion: "UICollectionViewController 帮我们省掉了哪一步？",
                recap: "手动版本需要自己创建 collectionView、设置 layout/dataSource/delegate 和 constraints。",
                victoryCondition: "能说出 UICollectionViewController 自带 collectionView，普通 UIViewController 不自带。"
            )
        ]
    )
}

struct GuidedStep {
    let id: String
    let title: String
    let instruction: String
    let lookAt: String
    let predictionQuestion: String
    let expectedLogs: [String]
    let understandingQuestion: String
    let recap: String
    let victoryCondition: String
}
