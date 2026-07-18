# Guided Learning

这份文档是 UIKit Lifecycle Lab 的完整实验手册。App 只负责给出当前目标、真实代码入口和一个 Xcode 动作；解释、LLDB 命令、预期证据、Reset、边界和思考题都留在这里。

## 先建立实验方法

把一次调试看成办案：

1. **先预测**：运行前写一句“我认为会发生什么”。
2. **再暂停**：只在一个能回答问题的源码位置打断点。
3. **看当下**：用 Variables View 或 LLDB 检查当前对象、参数和状态。
4. **看来源**：用 Call Stack 或 `bt` 回答“谁把代码带到这里”。
5. **看过程**：用 App Logs 或 Xcode Console 补足断点前后的事件顺序。
6. **做复验**：Reset 后改变一个条件，再跑一次。
7. **写边界**：明确证据证明了什么，以及还不能证明什么。

不要一次开启九组断点。每轮只做一张卡，拿到下面这份最小证据记录再进入下一张：

```text
实验：
断点：
触发动作：
关键变量：
Call Stack 关键词：
日志顺序：
结论：
仍不能证明：
```

## 工具分工

| 工具 | 这份 Lab 中回答的问题 |
|---|---|
| App Guide | 当前做什么、看哪个真实文件 |
| App Logs | 事件先后顺序、分类和关键字段 |
| Source Breakpoint | 代码是否真的执行到这里 |
| Variables / LLDB | 暂停时对象和参数是什么 |
| Call Stack / `bt` | UIKit、控件事件或业务代码如何调用到这里 |
| Debug Memory Graph | 对象为什么仍然活着、引用从哪里来 |
| Debug View Hierarchy | 当前 view、容器和约束组成是什么 |

Call Stack 中 UIKit 私有实现的具体符号会随系统版本变化。学习目标是认出“Framework frame → 你的 override / delegate / action”，不是背一条固定栈。

## 九张实验卡

建议先完成 1～4 的最小主链，再完成 5～9 的专项实验：

```text
Run List
→ 点击 cell
→ Save
→ closure 回传并返回
→ cell reuse
→ snapshot 更新
→ 页面展示方式
→ closure 引用关系
→ 手动装配 collection view
```

<!-- experiment-card: launch-lifecycle -->
## 实验 1：启动生命周期

### 学习目标

区分“对象创建”“view 被加载”“页面即将可见”“页面已经可见”四类时机。完成后，你应该能解释为什么返回 List 时通常会再次出现 `viewWillAppear`，却不会再次出现同一个实例的 `viewDidLoad`。

运行前先预测：List 第一次显示前，`init`、`loadView`、`viewDidLoad`、`viewWillAppear`、`viewDidAppear` 会按什么顺序出现？

### 机制

`SceneDelegate` 创建导航控制器和 List。导航控制器需要展示 List 时，UIKit 才要求它加载 view，并依次推进可见性生命周期。`viewDidLoad` 表示这一份 view 已完成加载，不等于用户已经看见页面；`viewDidAppear` 才表示展示动画已经结束、页面实际可见。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位：

```swift
override func viewDidLoad()
```

同一文件还可以对照 `init()`、`loadView()`、`viewWillAppear(_:)` 和 `viewDidAppear(_:)`。

### App 操作

1. App 未运行时先设置断点。
2. 在 Xcode 按 `⌘R` 冷启动 App，不点击任何 cell。
3. 断点命中后逐次 Continue，直到 List 完整出现。
4. 打开 `Learn -> Logs`，先看 `Lifecycle`，再看 `List`。

### Xcode / LLDB 操作

在 `viewDidLoad` 第一行设置 Source Breakpoint。命中后先看 Debug Navigator 的当前线程，再输入：

```lldb
bt
frame variable self
po self.isViewLoaded
po self.viewIfLoaded
```

Continue 后，在 List 中打开一个 Detail 再返回，观察 List 的 `viewWillAppear` 和 `viewDidAppear` 是否再次出现。

### 预期真实证据

以本次运行日志为准，重点记录这条相对顺序：

```text
ReminderListViewController init
loadView before super
loadView after super
viewDidLoad
viewWillAppear
viewDidAppear
```

`viewDidLoad` 断点的上游栈应包含 UIKit 加载 ViewController view 的 frame；具体私有符号可能变化。返回 List 时，应再次看到可见性回调，而同一 List 实例通常不再次执行 `viewDidLoad`。

### Reset / 复验

1. 在 Logs 点 `Clear`。
2. Stop App，再次 `⌘R`，得到一轮全新的 List 实例。
3. 第二轮给 `viewWillAppear` 也加断点，比较冷启动与从 Detail 返回的两次调用栈。

### 误区 / 边界

- 错误认知：`viewDidLoad` 表示页面已经显示。正确理解：它只证明 view 已加载。
- 错误认知：`viewDidLoad` 在整个 App 生命周期只执行一次。正确理解：它针对某个 ViewController 的某次 view 加载；新建实例仍会执行。
- 日志能证明回调顺序，不能单独证明“是谁调用”；调用来源要看栈。

### 思考题

如果返回 List 后数据没有恢复，你会优先检查 `viewDidLoad` 还是 `viewWillAppear`？你的判断依据是什么？
<!-- /experiment-card -->

<!-- experiment-card: tap-cell -->
## 实验 2：点击 cell 与 delegate 回调

### 学习目标

证明 `collectionView(_:didSelectItemAt:)` 是 UICollectionView 在用户选择 item 后回调 delegate，而不是业务代码手动调用；同时把 `indexPath` 转换为稳定的 `Reminder` 标识。

运行前先预测：点击 `Buy groceries` 后，先出现 delegate 日志，还是先创建 Detail？

### 机制

触摸经过 UIKit 的事件分发和 collection view 选择处理后，UICollectionView 调用 delegate 方法。这个方法用 diffable data source 把当前位置解析成 `Reminder`，再调用业务路由方法 `openDetail`。因此“点中了哪个位置”和“真正打开哪个业务对象”是两层证据。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位完整签名：

```swift
override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
```

### App 操作

1. 保持 App 在初始 List。
2. 点击 `Buy groceries`。
3. Detail 出现后先返回 List，不修改数据。
4. 打开 `Learn -> Logs`，依次查看 `Delegate`、`Detail` 和 `Lifecycle`。

### Xcode / LLDB 操作

在 delegate 方法第一行设置 Source Breakpoint。命中后 Step Over 到 `dataSource.itemIdentifier(for:)` 完成，再执行：

```lldb
bt
frame variable indexPath
po dataSource.itemIdentifier(for: indexPath)
```

继续运行，观察下一站是否进入 `openDetail(for:using:)`，再命中 Detail 的 `viewDidLoad`。

### 预期真实证据

需要同时拿到两类证据：

```text
Call Stack：UICollectionView / UIKit frame → didSelectItemAt
Logs：collectionView(_:didSelectItemAt:) → openDetail → Detail init → Detail viewDidLoad
```

`indexPath` 证明用户点了哪个当前位置；`itemIdentifier(for:)` 返回的 `Reminder.ID` 才是 diffable data source 当前快照中的业务身份。

### Reset / 复验

1. 返回 List，清空 Logs。
2. 改点另一条 reminder，记录新的 `indexPath` 和 item identifier。
3. 切换 `Today` 或 `Future` filter 后再点一次，确认位置会随快照变化，而业务 ID 仍来自 data source。

### 误区 / 边界

- 错误认知：`didSelectItemAt` 负责创建 cell。正确理解：它处理选择；cell 创建由 data source / registration 负责。
- 错误认知：`indexPath` 就是业务 ID。正确理解：过滤、插入和排序都可能改变位置。
- UIKit 内部栈名不是稳定 API，不要把某个私有 frame 名写成永久结论。

### 思考题

如果 `didSelectItemAt` 已命中，但打开了错误 reminder，下一步应该检查触摸事件、`indexPath`，还是 `itemIdentifier(for:)`？为什么？
<!-- /experiment-card -->

<!-- experiment-card: save -->
## 实验 3：Save、target-action 与 closure

### 学习目标

把一次 Save 拆成两段：UIKit 如何把按钮事件送到 `saveReminder`，以及 Detail 如何主动调用 `onSave` 把结果传回 List。

运行前先预测：`saveReminder` 和 `onSave closure` 哪个由 UIKit 调用，哪个由业务代码调用？

### 机制

默认模式下，Save 使用 target-action 和 selector；切换模式后则由 `UIAction` closure 接收点击，两条路径最终都进入 `saveReminder`。`saveReminder` 清洗文本后主动执行 `onSave(titleToSave)`，所以 action 是 UI 事件入口，`onSave` 是页面间的数据回传通道。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderDetailViewController.swift`](../UIKitLifecycleDemo/ReminderDetailViewController.swift)，定位：

```swift
@objc private func saveReminder()
```

同时对照 `setupNavigation()` 中 `.targetAction` 与 `.uiAction` 两个分支。

### App 操作

1. 从 List 打开 `Buy groceries`。
2. 点 `Use Example Title`，避免第一轮被键盘输入干扰。
3. 点 `Save`。
4. 打开 Logs，先看 `Action`，再看 `Closure` 和 `Snapshot`。

### Xcode / LLDB 操作

在 `saveReminder` 第一行设置断点。命中后：

```lldb
bt
po textField.text
```

Step Over 到 `titleToSave` 已生成，再执行：

```lldb
frame variable rawText editedTitle titleToSave
```

对 `onSave(titleToSave)` 使用 Step Into，观察执行点跳入 List 在 `openDetail` 中创建的 closure。

### 预期真实证据

默认 target-action 模式下，Call Stack 应能看出按钮事件经过 UIKit 到达 `saveReminder`；具体 frame 名随系统版本变化。日志主链应为：

```text
useExampleTitle
saveReminder rawText / titleToSave
saveReminder about to call onSave
onSave closure
update(_:with:)
applyCurrentSnapshot
```

切换 UIAction 模式后，会多出 `UIAction closure received button tap`，但最终仍进入同一个 `saveReminder`。

### Reset / 复验

1. Stop 并重启 App，恢复初始标题和默认 target-action。
2. 运行一次默认模式并保存栈摘要。
3. `Learn -> Experiments -> Toggle Save`，重新打开 Detail，再跑 UIAction 模式。
4. 对比两次调用栈的入口差异与共同终点。

### 误区 / 边界

- 错误认知：closure 都是系统回调。正确理解：`onSave` 是本项目代码主动调用。
- 错误认知：Step Over 和 Step Into 只是移动速度不同。正确理解：前者不进入被调用函数，后者用于追进下一段控制流。
- 断点会改变交互时序；它适合证明调用链，不适合测量点击性能。

### 思考题

如果日志出现 `saveReminder`，却没有 `onSave closure`，你会在哪一行新增断点，准备检查哪个值？
<!-- /experiment-card -->

<!-- experiment-card: pop-back -->
## 实验 4：closure 回传、列表刷新与返回

### 学习目标

串起 Save 之后的完整顺序：Detail 调 closure、List 更新 model、应用 snapshot、页面 pop 或 dismiss、List 再次可见、Detail 最终释放。

运行前先预测：列表数据更新发生在返回动画之前还是之后？`viewDidLoad` 会不会再次出现？

### 机制

`openDetail` 创建 `onSave` closure 并交给 Detail 持有。Detail 点击 Save 时先调用 closure，所以 List 的数组和 snapshot 会先更新；之后 Detail 才根据展示方式执行 pop 或 dismiss。List 是原来的实例，因此返回时走可见性生命周期，而不是重新初始化。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位：

```swift
private func openDetail(for selectedReminder: Reminder, using presentationMode: DetailPresentationMode)
```

重点看此方法里的两个 `onSave` closure，以及它们调用的 `update(_:with:updateMode:)`。

### App 操作

1. 打开第一条 reminder。
2. 点 `Use Example Title`，再点 `Save`。
3. 返回 List 后不要继续操作，先打开 Logs。
4. 依次查看 `Closure`、`Snapshot`、`NavStack`、`Lifecycle` 和 `Memory`。

### Xcode / LLDB 操作

在 weak closure 内的 `self?.update(...)` 设置断点；切到 strong 模式时改在 `self.update(...)`。命中后：

```lldb
bt
frame variable editedTitle
po self?.navigationController?.viewControllers
```

Continue 后观察 `applyCurrentSnapshot`、Detail 的消失生命周期和 `deinit`。也可在 `ReminderDetailViewController.deinit` 添加断点，但不要依赖它在动画结束前立即命中。

### 预期真实证据

转场开始前的业务顺序应为：

```text
saveReminder about to call onSave
onSave closure
update(_:with:)
applyCurrentSnapshot
about to popViewController 或 about to dismiss
```

转场过程中还会出现 Detail 的消失回调与 List 的出现回调；它们的实际交错顺序由你记录，不在文档中伪造固定答案。返回 List 后不应出现同一 List 实例的新 `viewDidLoad`。`deinit` 可能晚于动画结束或其他临时引用释放，因此证据应是“最终出现”，不是“必须紧跟某一行”。

### Reset / 复验

1. 清空 Logs 并重启 App。
2. 第一轮用默认 Show 完成 Save。
3. 第二轮用 `Learn -> Experiments -> Present` 打开 Detail，再 Save。
4. 对比 pop 与 dismiss 的日志，同时确认两轮都会回传数据。

### 误区 / 边界

- 错误认知：返回页面一定会重新创建 List。正确理解：navigation pop 通常暴露原有 List。
- 错误认知：没立刻看到 `deinit` 就一定泄漏。正确理解：先等待转场完成，再查仍然持有对象的引用。
- snapshot 更新成功只证明 UI 数据通路执行了，不自动证明磁盘持久化；本 Lab 没有持久化层。

### 思考题

如果 List 标题已更新，但 Detail 一直不 `deinit`，你会先用 Logs、Call Stack 还是 Memory Graph？各自能排除什么？
<!-- /experiment-card -->

<!-- experiment-card: cell-reuse -->
## 实验 5：Cell reuse

### 学习目标

亲眼证明列表不会为 50 条数据永久创建 50 个可见 cell；屏幕外的 cell 可以被回收并用于新的 item，而内容配置和 cell 实例身份是两件事。

运行前先预测：快速滚动 50 条数据时，`init`、`prepareForReuse`、`updateConfiguration` 哪个次数最多？为什么？

### 机制

UICollectionView 只维护当前可见区域和少量预取所需的 cell。旧 cell 离开复用周期时会执行 `prepareForReuse`，随后用新 item 再配置。`updateConfiguration(using:)` 还可能因为 selected、highlighted 等状态变化重复发生，所以它不等于“创建了一个新 cell”。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderCell.swift`](../UIKitLifecycleDemo/ReminderCell.swift)，定位：

```swift
override func prepareForReuse()
```

同文件还要对照 `init(frame:)` 和 `updateConfiguration(using:)`。

### App 操作

1. `Learn -> Experiments -> Load 50 Reuse Items`。
2. 先停在列表顶部，观察当前可见 cell。
3. 连续滚动到底部，再滚回顶部。
4. 打开 Logs，选择 `Cell`，必要时用 Search 查 `prepareForReuse`。

### Xcode / LLDB 操作

在 `prepareForReuse` 设置 Source Breakpoint。每次命中时记录对象身份：

```lldb
bt
po ObjectIdentifier(self)
po self.contentConfiguration
```

Continue 并滚动，观察同一个 `ObjectIdentifier` 是否在不同时间服务不同内容。需要更少打断时，可给断点添加 Action `po ObjectIdentifier(self)` 并勾选自动 Continue。

### 预期真实证据

你应看到三种不同含义的日志：

```text
init：创建新的 cell 实例
prepareForReuse：旧实例准备进入下一次使用
CellRegistration / updateConfiguration：把当前 item 或 UI 状态配置到 cell
```

实际次数受屏幕尺寸、预取和系统实现影响，不应写死。可验证结论是：滚动过程中出现复用，同一实例身份可以对应不同 item，而不是“50 条数据必有 50 个 cell”。

### Reset / 复验

1. Stop 并重启 App，恢复初始数据。
2. 清空 Logs，再加载 50 条。
3. 第二轮先慢滚，第三轮快滚，比较调用次数，但不要把次数差直接解释成性能优劣。

### 误区 / 边界

- 错误认知：`prepareForReuse` 表示 cell 被销毁。正确理解：它仍然活着，正准备再次使用。
- 错误认知：每次 `updateConfiguration` 都绑定了新 model。正确理解：高亮和选择状态也会触发配置更新。
- 断点会显著打断滚动，不能用这轮操作判断真实帧率。

### 思考题

如果滚动后 A 行短暂显示 B 行标题，为什么第一检查点应是“重新绑定和旧状态清理”，而不是先怀疑 datasource 少了一条数据？
<!-- /experiment-card -->

<!-- experiment-card: snapshot-update -->
## 实验 6：Diffable Snapshot 的 Full Apply、Reload 与 Reconfigure

### 学习目标

区分“提交一份完整快照”“要求 reload 目标 item”“在不替换现有 cell 的前提下重新配置目标 item”三种更新意图，并用真实调用和日志比较它们。

运行前先预测：只修改第一条 reminder 的标题时，三种模式是否都必须创建新 cell？

### 机制

三个菜单动作都会先修改同一个业务 model，再进入 `applyCurrentSnapshot`。区别在于 snapshot 是否额外标记 `reloadItems` 或 `reconfigureItems`。Full Apply 让 diffable data source 比较完整标识集合；Reload 请求重新加载 item；Reconfigure 更适合只刷新现有 item 的内容配置，不要求替换现有 cell。

这里 `Reminder` 的相等与 hash 只使用稳定 `id`：snapshot 表达“哪几个 item、什么顺序”，不是最新标题的权威存储。CellRegistration 收到 snapshot item 后，会用它的 `id` 回查当前 `reminders` 再渲染。否则系统即使触发 reconfigure，也可能把 data source 内保存的旧 value 再画一遍；反过来，只修改 title 后做 Full Apply，也不保证相同 identifier 的可见 cell 自动刷新。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位：

```swift
private func runSnapshotExperiment(_ updateMode: SnapshotUpdateMode)
```

继续对照 `update(_:with:updateMode:)` 和 `applyCurrentSnapshot(reconfiguring:reloading:)`。

### App 操作

每种模式都从干净启动单独运行一次：

1. `Learn -> Experiments -> Snapshot -> Full Apply`。
2. 记录后重启，再运行 `Reload Item`。
3. 再次重启，运行 `Reconfigure Item`。
4. 每轮在 Logs 对照 `Snapshot` 与 `Cell`。

### Xcode / LLDB 操作

在 `runSnapshotExperiment` 和 `applyCurrentSnapshot` 各设一个断点。第一处执行：

```lldb
bt
frame variable updateMode
po dataSource.snapshot().itemIdentifiers
```

在第二处检查参数：

```lldb
frame variable remindersToReconfigure remindersToReload
```

Step Over 到 `snapshot.reloadItems` 或 `snapshot.reconfigureItems`，确认本轮究竟标记了哪一组 item。

### 预期真实证据

三轮都应出现：

```text
runSnapshotExperiment mode
update(_:with:) old / new
applyCurrentSnapshot
```

Reload 轮应额外出现 `reloadItems` 日志；Reconfigure 轮应额外出现 `reconfigureItems`；Full Apply 轮没有这两种显式标记。Reload 与 Reconfigure 触发配置时，标题应来自当前 model；Full Apply 若判断 identifier 集合无变化，标题可能保持不变，这正是本轮要记录的负对照。Cell 的具体回调次数受系统调度影响，应记录而不是预设。若要判断 cell 是否被替换，可结合实验 5 的实例身份。

### Reset / 复验

每个模式后 Stop 并重启，因为实验会给标题追加 `*`。只有从同一初始 model 开始，三轮证据才可比较。清空日志但不重启，不能恢复已修改的内存数据。

### 误区 / 边界

- 错误认知：Full Apply 就一定全量重建所有 cell。正确理解：diffable data source 会依据 identifier 和差异决定实际更新。
- 错误认知：Reload 与 Reconfigure 只是名字不同。正确理解：前者表达重新加载，后者强调更新现有 cell 配置。
- 错误认知：snapshot 里的 value 一定是最新业务数据。正确理解：identifier 与 payload 要分工；本实验用稳定 ID 回查当前 model。
- 日志能证明传入的更新意图；实际渲染成本仍需性能工具或更专门的测量。

### 思考题

如果只是“已读状态改变，item 身份和位置不变”，你会先选择 Full Apply、Reload 还是 Reconfigure？还需要验证什么边界？
<!-- /experiment-card -->

<!-- experiment-card: presentation -->
## 实验 7：Show、Push 与 Present

### 学习目标

不靠动画外观猜路由，而是用 navigation stack、容器关系和返回代码判断页面究竟被 push 到原栈，还是被 present 为独立模态导航容器。

运行前先预测：Present 出来的 Detail 会不会进入 List 所在的原 navigation stack？

### 机制

本项目中，Show 交给当前容器决定展示方式，在当前 navigation 环境里表现为 push；Push 明确把 Detail 加入现有栈；Present 则新建一个以 Detail 为 root 的 `UINavigationController` 并模态展示。容器不同，返回时分别使用 pop 或 dismiss。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位：

```swift
private func openDetail(for selectedReminder: Reminder, using presentationMode: DetailPresentationMode)
```

重点看最后的 `switch presentationMode`。

### App 操作

1. `Learn -> Experiments -> Open Detail -> Show`，进入后用 Back 返回。
2. 运行 `Push`，再次返回。
3. 运行 `Present`，用 Cancel 或 Save 关闭。
4. 每轮在 Logs 查看 `NavStack` 和 `Lifecycle`。

### Xcode / LLDB 操作

在 `switch presentationMode` 前设置断点：

```lldb
frame variable presentationMode
po navigationController?.viewControllers
```

再在 `ReminderDetailViewController.viewDidAppear` 设置断点，执行：

```lldb
po self.navigationController
po self.navigationController?.viewControllers
po self.navigationController?.presentingViewController
```

分别保存三轮结果。最后在 `saveReminder` 的 switch 处确认 Show / Push 走 pop，Present 走 dismiss。

### 预期真实证据

| 模式 | 真实容器证据 | 返回证据 |
|---|---|---|
| Show | 在本 Demo 中，原 navigation stack 出现 Detail | `popViewController` |
| Push | 原 navigation stack 明确出现 Detail | `popViewController` |
| Present | 新 navigation controller 以 Detail 为 root；原栈不新增 Detail | `dismiss` |

App 的 `printNavigationStack` 日志与 LLDB 对象结果应相互印证，而不是只凭转场动画下结论。

### Reset / 复验

每轮先完整退出当前 Detail，再清空 Logs 后启动下一种模式。若误把 Present 留在屏幕上，不要直接开始下一轮，否则容器层级会混入上一轮状态。

### 误区 / 边界

- 错误认知：Show 永远等于 Push。正确理解：Show 是自适应 API，行为取决于当前容器和环境。
- 错误认知：Push 与 Present 只差动画。正确理解：它们改变页面所有权、导航栈和关闭方式。
- 本 Lab 的 Present 主动包了一层 navigation controller，这不是 UIKit 对所有 present 的强制规则。

### 思考题

如果一个页面看起来像从右侧进入，但 LLDB 显示它不在原 navigation stack，你应相信动画还是容器证据？下一步如何确认？
<!-- /experiment-card -->

<!-- experiment-card: closure-memory -->
## 实验 8：Closure capture 与 Debug Memory Graph

### 学习目标

从完整引用链判断对象是否泄漏，不把“closure 强捕获 self”直接等同于“必有 retain cycle”。完成后，你应该能说明当前代码为什么即使使用 strong capture，Detail 仍可能正常释放。

运行前先预测：`Detail -> onSave closure -> List` 这条强引用路径，是否已经构成环？

### 机制

Detail 强持有 `onSave` closure。strong 模式下，closure 再强持有 List；但当前 List 没有反向强持有 Detail。页面退出后，navigation controller 或 presented controller 关系释放 Detail，Detail 随后释放 closure，因此这条链本身不是闭环。只有再出现一条 `List -> Detail` 或其他返回边，才会形成环。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ReminderListViewController.swift`](../UIKitLifecycleDemo/ReminderListViewController.swift)，定位：

```swift
private func toggleClosureCaptureMode()
```

再向上找到 `openDetail(for:using:)` 中 weak 与 strong 两个 `onSave` 分支。

### App 操作

1. 冷启动时默认是 weak 模式，打开 Detail 并停留。
2. 在 Xcode 打开 `Debug -> View Memory Graph`，搜索 `ReminderDetailViewController` 和 `ReminderListViewController`。
3. 退出 Detail，等待转场结束，检查 `deinit`。
4. 重启后执行 `Learn -> Experiments -> Toggle Closure` 切为 strong，再重复同一流程。

### Xcode / LLDB 操作

在 `toggleClosureCaptureMode` 设置断点确认模式：

```lldb
po closureCaptureMode
```

在 Memory Graph 中选中 Detail，沿引用边检查它持有的 closure 以及 closure 与 List 的关系；再查看“谁在强持有 Detail”。退出页面后重新抓一份 Memory Graph，不要只看旧快照。

### 预期真实证据

当前实现中，两种模式退出后都应最终出现：

```text
ReminderDetailViewController deinit - detail controller released
```

Detail 仍在屏幕上时，strong 模式可存在 `Detail -> closure -> List` 的强路径；但如果没有返回到 Detail 的强边，它不是循环。Memory Graph 的 UI 标签可能随 Xcode 版本变化，也不一定出现紫色泄漏警告；判断依据是引用方向和退出后的新快照。

### Reset / 复验

每个模式从冷启动开始，因为 closure 模式保存在 List 实例内。退出后等待转场结束、清空日志并重新抓图。不要拿“页面仍显示时”的图与“页面退出后”的图直接混为同一时刻。

### 误区 / 边界

- 错误认知：看到 strong self 就已经证明泄漏。正确理解：泄漏需要一条闭合的强引用环或其他永久 owner。
- 错误认知：没看到紫色警告就证明没有内存问题。正确理解：仍要检查实例数量和引用路径。
- Memory Graph 是某一暂停时刻的快照；它不能替代长期内存增长分析。

### 思考题

如果 List 新增一个强属性长期保存当前 Detail，引用图会变成什么环？你会在哪一条边使用 weak，或者改变谁负责持有谁？
<!-- /experiment-card -->

<!-- experiment-card: manual-collection -->
## 实验 9：手动装配 CollectionView

### 学习目标

比较 `UICollectionViewController` 与普通 `UIViewController` 的职责边界，亲自确认手动版本必须创建 layout、collection view、约束、delegate、diffable data source 和 snapshot。

运行前先预测：普通 `UIViewController` 进入 `viewDidLoad` 时，是否已经自动拥有可用的 collection view？

### 机制

主列表继承 `UICollectionViewController`，其 `loadView` 会准备 collection view 容器；手动版本只继承 `UIViewController`，所以项目代码必须创建 `UICollectionView`、加入 view hierarchy、设置约束和 delegate，并强持有 diffable data source 后提交 snapshot。

### 真实源码锚点

按 `⌘⇧O` 打开 [`ManualCollectionViewController.swift`](../UIKitLifecycleDemo/ManualCollectionViewController.swift)，定位：

```swift
private func setupCollectionView()
```

同文件依次对照 `configureDataSource()` 与 `applySnapshot()`。

### App 操作

1. `Learn -> Experiments -> More -> Manual UIViewController Version`。
2. 页面出现后滚动并点击一条 reminder。
3. 打开 Logs，查看 `ManualCollectionViewController`、`DataSource`、`Delegate` 和 `Layout` 相关记录。
4. 返回主列表，与 `UICollectionViewController` 版本对照。

### Xcode / LLDB 操作

在 `setupCollectionView` 第一行设置断点。赋值前后分别检查：

```lldb
bt
po collectionView as Any
```

Step Over 到 `collectionView.delegate = self` 和约束激活后，再执行：

```lldb
po collectionView
po collectionView.delegate
po collectionView.superview
```

继续到 `configureDataSource` 和 `applySnapshot`，确认 data source 与 item identifiers 已建立。

页面完整出现后点击 Debug Bar 的 `Debug View Hierarchy`，在 3D 层级中选中 `manualCollectionView`，确认它确实被加到根 view 并由四条边约束铺满。

### 预期真实证据

日志与变量应呈现这条装配链：

```text
viewDidLoad
setupCollectionView：create layout / collectionView / delegate / constraints
configureDataSource：create registration / diffable data source
applySnapshot：append section / items and apply
```

在 `setupCollectionView` 赋值前，手动版本的 `collectionView` 尚未创建；完成后它应有 superview、delegate 和约束。主列表则由 `UICollectionViewController` 提供基础 collection view，再由项目代码替换 layout、配置 data source。

### Reset / 复验

1. Pop 回主列表。
2. 清空 Logs，再次打开手动版本，得到新的 controller 和 collection view 实例。
3. 第二轮分别在 `setupCollectionView` 末尾和 `configureDataSource` 末尾暂停，对比“已有容器”和“已有数据供给”两个时刻。

### 误区 / 边界

- 错误认知：创建 `UICollectionView` 后就会自动显示业务数据。正确理解：还需要注册 / 配置 cell、data source 和 snapshot。
- 错误认知：delegate 与 data source 是同一个职责。正确理解：前者处理交互，后者提供展示内容。
- Debug View Hierarchy 能证明 view 已加入层级和约束结果，不能替代 data source 状态检查。

### 思考题

如果页面是空白，但 Debug View Hierarchy 已看到 collection view 铺满屏幕，你下一步会检查 layout、data source 还是 navigation stack？请写出最短排查顺序。
<!-- /experiment-card -->

## 完成标准

“看完文档”不算完成。九张卡每张至少保留一份真实记录，并满足：

- 能指出一个真实断点和触发动作。
- 能解释一个关键变量，而不是只截图。
- 能从 Call Stack 说出入口来自 UIKit、控件 action 还是业务 closure。
- 能写出实际日志相对顺序。
- 能说明这轮证据还不能证明什么。
- Reset 后改变一个条件，结果仍能被解释。

推荐把最小主链的最终复述压缩成：

```text
UIKit 创建并展示 List
→ UICollectionView delegate 接住选择
→ 路由创建 Detail
→ Save action 进入 saveReminder
→ Detail 主动调用 onSave
→ List 更新 model 并 apply snapshot
→ pop / dismiss
→ Detail 最终 deinit
```
