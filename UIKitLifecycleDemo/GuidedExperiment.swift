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
