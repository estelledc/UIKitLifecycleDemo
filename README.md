# UIKitLifecycleDemo

一个纯 UIKit、纯代码的 iOS 学习 Demo，用来观察 UIKit 生命周期、`UICollectionViewController`、diffable data source、delegate、target-action、closure 回传，以及用 Codex 辅助学习 iOS 的完整流程。

这个项目的目标不是做复杂 App，而是做一个可运行的“UIKit 行为观察实验室”：你可以在 Xcode Console 里看日志，在断点里看 Call Stack，在 Simulator 里真实点击、编辑、保存，然后把现象和理解连起来。

## 学什么

- `loadView` 是 view 创建入口，`viewDidLoad` 是 view 创建完成后的初始化入口。
- `viewWillAppear / viewDidAppear / viewWillDisappear / viewDidDisappear` 是 UIKit 自动调用的。
- `viewWillLayoutSubviews / viewDidLayoutSubviews / viewSafeAreaInsetsDidChange` 和页面出现不是一回事。
- `UICollectionViewController` 自带 `collectionView`。
- `collectionViewLayout` 只决定 cell 怎么排列。
- `DiffableDataSource + Snapshot` 决定当前显示哪些数据。
- `CellRegistration` 决定 item 如何配置成 cell。
- `didSelectItemAt` 是用户点击 cell 后，UIKit 触发的 delegate 回调。
- Save 按钮可以通过 target-action 或 `UIAction` 调用 `saveReminder`。
- 详情页通过 closure 把编辑后的 title 传回列表页。
- `[weak self]` 用来避免 closure 强持有对象形成难释放的引用链。
- 自定义 cell 会复用，cell 数量不等于数据数量。
- pop 回列表页时，List 的 `viewDidLoad` 不会再次执行，但 `viewWillAppear / viewDidAppear` 会再次执行。

## Demo 功能

- 初始列表：`Buy groceries`、`Walk dog`、`Read UIKit docs`
- 点击 cell：默认用 `show` 进入编辑详情页
- Save：closure 回传并刷新列表
- Add：新增 reminder
- Delete：侧滑删除 reminder
- All / Today / Future：切换展示集合
- Same：让两条 reminder 显示同名，观察为什么 identity 不应该只用 title
- 进度条：观察自定义 `UIView`、`layoutSubviews`、`draw(_:)`、`UIStackView`、AutoLayout、accessibility 和动画终态
- Experiments：打开 Show / Push / Present、Snapshot、Cell reuse、String identity、Manual collection view、Save 写法和 closure 捕获实验
- UI Test：自动验证点击、编辑、Save 后列表更新

## 项目结构

```text
UIKitLifecycleDemo.xcodeproj
UIKitLifecycleDemo/
  AppDelegate.swift
  SceneDelegate.swift
  ExperimentSupport.swift
  ReminderListViewController.swift
  ReminderDetailViewController.swift
  ReminderCell.swift
  StringIdentityExperimentViewController.swift
  ManualCollectionViewController.swift
  Info.plist
UIKitLifecycleDemoUITests/
  UIKitLifecycleDemoUITests.swift
Makefile
README.md
CHANGELOG.md
LICENSE
docs/
```

入口链路：

```text
SceneDelegate
-> UIWindow
-> UINavigationController
-> ReminderListViewController
-> ReminderDetailViewController
```

## 快速开始

```bash
cd explorations/_active/UIKitLifecycleDemo
make build
make open
make run
make test-ui
make logs
make clean
```

默认设置：

```text
Scheme: UIKitLifecycleDemo
Simulator: iPhone 17 Pro
```

详细环境准备见：[docs/setup.md](docs/setup.md)。

## 推荐观察方式

第一轮：只看 Console。

1. 在 Xcode 里禁用断点。
2. 点击 Run。
3. 看首次启动日志。
4. 点击第一行 `Buy groceries`。
5. 修改文本并点击 Save。
6. 观察 pop 回列表后的日志。

第二轮：再看断点和 Call Stack。

建议断点：

- `ReminderListViewController.viewDidLoad`
- `ReminderListViewController.viewWillAppear`
- `ReminderListViewController.collectionView(_:didSelectItemAt:)`
- `ReminderDetailViewController.viewDidLoad`
- `ReminderDetailViewController.saveReminder`
- `ReminderCell.prepareForReuse`
- `StringIdentityExperimentViewController.applyUnsafeSnapshot`

断点命中后，在 LLDB 输入：

```lldb
bt
```

详细观察步骤见：[docs/xcode-observation-guide.md](docs/xcode-observation-guide.md)。

## 1.1.0 可观测实验目录

| 实验 | 操作入口 | 预期观察 | 学到什么 |
|---|---|---|---|
| Call Stack 证明 UIKit 调用链 | Xcode 给指定方法打断点，LLDB 执行 `bt` | 栈里出现 `UIKitCore`、`UIViewController`、`UICollectionViewController`、`UINavigationController`、`UIApplication sendAction` | 生命周期、delegate、target-action 不是你手动调用 |
| `loadView / viewDidLoad` | 启动 App 或 push Detail | `loadView before super -> loadView after super -> viewDidLoad` | `loadView` 创建 root view，`viewDidLoad` 做创建后的初始化 |
| 布局生命周期 | 启动、push、pop、旋转模拟器 | `viewWillLayoutSubviews / viewDidLayoutSubviews / viewSafeAreaInsetsDidChange` 可能多次出现 | 页面加载完成不等于布局尺寸最终稳定 |
| Navigation Stack | 点击 cell、Save 返回 | `[ReminderListViewController]` 变成 `[ReminderListViewController, ReminderDetailViewController]`，pop 后回到 List | push 是压栈，pop 是出栈 |
| Show / Push / Present | `Experiments -> Open Detail` | show/push 在同一个导航栈中，present 会出现新的 `UINavigationController` | 展示方式会影响返回方式和生命周期关系 |
| Diffable identity | `Experiments -> String Identity Experiment` | 重复 `Walk dog` 被识别为重复 identifier，页面用安全日志提示风险 | item identity 不应该只用 title |
| Snapshot 更新 | `Experiments -> Snapshot` | Full Apply、Reload、Reconfigure 都会刷新，但 cell 配置次数不同 | apply 提交整体状态，reload 重载 item，reconfigure 适合只改文字 |
| Cell 复用 | `Experiments -> Load 50 Reuse Items` 后滚动 | `ReminderCell init / prepareForReuse / updateConfiguration` 交替出现 | cell 是可复用视图，不是业务数据本身 |
| Target-action vs UIAction | `Experiments -> Toggle Save` 后进入详情页 Save | target-action 走 `#selector(saveReminder)`，UIAction 先打印 closure 日志再调用 `saveReminder` | 两者都是 UIKit 在用户点击后回调 |
| Closure 内存管理 | `Experiments -> Toggle Closure`，Save 后看 `deinit` 和 Memory Graph | weak/strong 捕获日志不同，Detail pop 后应释放 | closure 默认强捕获，是否泄漏取决于引用链 |
| 手动 CollectionView | `Experiments -> Manual UIViewController Version` | 手动创建 collectionView、layout、dataSource、delegate、constraints | `UICollectionViewController` 方便在于帮你准备好 collectionView |
| UI Test 自动验证 | `make test-ui` | 测试启动 App、点击第一行、编辑、Save、断言新标题出现 | 手动观察可以逐步沉淀成自动验证 |

## Call Stack 观察实验

像查快递路线一样，Call Stack 能告诉你“这个方法是从哪里一路调用过来的”。断点停住后，在 LLDB 输入：

```lldb
bt
```

观察报告模板：

```text
断点位置：
我做了什么操作：
bt 里看到的 UIKit 关键词：
是否看到 UIViewController / UICollectionViewController / UINavigationController：
我认为是谁调用了这个方法：
我的一句话结论：
```

判断口诀：

- 看到 `UIViewController`：通常是页面生命周期。
- 看到 `UICollectionView`：通常是列表触摸、选择或 cell 相关流程。
- 看到 `UINavigationController`：通常是 push / pop / show 相关流程。
- 看到 `UIApplication sendAction`：通常是 target-action 或按钮事件分发。

## 预期日志顺序

首次启动：

```text
[ReminderListViewController] init
[ReminderListViewController] loadView - before super
[ReminderListViewController] loadView - after super
[ReminderListViewController] viewDidLoad
[ReminderListViewController] setupCollectionView
[ReminderListViewController] listLayout
[ReminderListViewController] configureDataSource
[ReminderListViewController] applyInitialSnapshot
[ReminderListViewController] applyCurrentSnapshot
[ReminderListViewController] viewWillAppear
[ReminderListViewController] CellRegistration
[ReminderListViewController] viewDidAppear
[NavStack] list viewDidAppear
```

点击 cell：

```text
[ReminderListViewController] collectionView(_:didSelectItemAt:)
[NavStack] before show
[ReminderDetailViewController] init(reminderTitle:onSave:)
[ReminderListViewController] openDetail
[ReminderDetailViewController] loadView
[ReminderDetailViewController] viewDidLoad
[ReminderListViewController] viewWillDisappear
[ReminderDetailViewController] viewWillAppear
[ReminderListViewController] viewDidDisappear
[ReminderDetailViewController] viewDidAppear
[NavStack] after detail appears
```

点击 Save：

```text
[ReminderDetailViewController] saveReminder
[ReminderDetailViewController] saveReminder - about to call onSave
[ReminderListViewController] onSave closure
[ReminderListViewController] update(_:with:)
[ReminderListViewController] applyCurrentSnapshot
[ReminderDetailViewController] saveReminder - about to popViewController
[NavStack] before pop
[ReminderDetailViewController] viewWillDisappear
[ReminderListViewController] viewWillAppear
[ReminderDetailViewController] viewDidDisappear
[ReminderListViewController] viewDidAppear
[ReminderDetailViewController] deinit
```

重点确认：返回 List 时，没有新的 List `viewDidLoad`，但会再次出现 List `viewWillAppear / viewDidAppear`。

## 核心类比

- `UICollectionView`：货架本体。
- `collectionViewLayout`：摆放规则。
- `DiffableDataSource + Snapshot`：当前陈列清单。
- `CellRegistration`：把商品放进格子的规则。
- `delegate`：用户交互接待员。
- `target-action`：按钮事件登记表。
- `closure`：详情页递回列表页的小纸条。

## 常见系统噪声

这些日志通常来自 Simulator 或系统框架，初学时可以先忽略：

- `UIAccessibilityLoaderWebShared`
- `CHHapticPattern`
- `Gesture gate timed out`

先抓住以 `[ClassName]` 开头的教学日志，再回头理解系统噪声。

## 用 Codex 学 iOS

这个项目也沉淀了一套学习方法：

1. 让 Codex 从零创建最小 UIKit Demo。
2. 要求每个关键生命周期、事件和数据流都加日志。
3. 用 `make build` 做命令行验证。
4. 用 `make open` 进入 Xcode。
5. 第一轮只看完整 Console。
6. 第二轮打断点看 Call Stack。
7. 用 Simulator 做真实点击、编辑、保存。
8. 最后把“看到什么、说明什么、下次怎么复现”写成笔记。

完整方法见：

- [docs/codex-learning-workflow.md](docs/codex-learning-workflow.md)
- [docs/agent-flow.md](docs/agent-flow.md)

## 版本范围

1.0.0 聚焦 UIKit 生命周期和列表回调观察。

1.1.0 增加 12 组可观测实验，重点从“看见基础生命周期”扩展到“比较不同 UIKit 机制”。

暂不包含：

- SwiftUI
- 第三方业务库
- 网络请求
- 持久化
- EventKit
- Combine / RxSwift

这些会留给后续版本继续深入。

## License

MIT. See [LICENSE](LICENSE).
