# UIKitLifecycleDemo

一个纯 UIKit、纯代码的 iOS 学习 Demo，用来观察 UIKit 生命周期、`UICollectionViewController`、diffable data source、delegate、target-action、closure 回传，以及用 Codex 辅助学习 iOS 的完整流程。

这个项目的目标不是做一个复杂 App，而是做一个可运行的“UIKit 生命周期实验室”：你可以在 Xcode Console 里看日志，在断点里看 Call Stack，在 Simulator 里真实点击、编辑、保存，然后把现象和理解连起来。

## 学什么

- `viewDidLoad / viewWillAppear / viewDidAppear / viewWillDisappear / viewDidDisappear` 是 UIKit 自动调用的。
- `UICollectionViewController` 自带 `collectionView`。
- `collectionViewLayout` 只决定 cell 怎么排列。
- `DiffableDataSource + Snapshot` 决定当前显示哪些数据。
- `CellRegistration` 决定 item 如何配置成 cell。
- `didSelectItemAt` 是用户点击 cell 后，UIKit 触发的 delegate 回调。
- Save 按钮通过 target-action 调用 `saveReminder`。
- 详情页通过 closure 把编辑后的 title 传回列表页。
- pop 回列表页时，List 的 `viewDidLoad` 不会再次执行，但 `viewWillAppear / viewDidAppear` 会再次执行。
- 用 Codex + Xcode + Simulator + Console + Call Stack 建立一套可复用 iOS 学习方法。

## Demo 功能

- 初始列表：`Buy groceries`、`Walk dog`、`Read UIKit docs`
- 点击 cell：push 到编辑详情页
- Save：closure 回传并刷新列表
- Add：新增 reminder
- Delete：侧滑删除 reminder
- All / Today / Future：切换展示集合
- Same：让两条 reminder 显示同名，观察为什么 identity 不应该只用 title
- 进度条：观察自定义 `UIView`、`layoutSubviews`、`draw(_:)`、`UIStackView` 和 AutoLayout

## 项目结构

```text
UIKitLifecycleDemo.xcodeproj
UIKitLifecycleDemo/
  AppDelegate.swift
  SceneDelegate.swift
  ReminderListViewController.swift
  ReminderDetailViewController.swift
  Info.plist
Makefile
README.md
CHANGELOG.md
LICENSE
docs/
  setup.md
  codex-learning-workflow.md
  xcode-observation-guide.md
  agent-flow.md
```

入口链路：

```text
SceneDelegate
-> UIWindow
-> UINavigationController
-> ReminderListViewController
-> ReminderDetailViewController
```

## 环境准备

必需：

- macOS
- Xcode
- iOS Simulator
- Xcode Command Line Tools

推荐：

- Homebrew
- `xcbeautify`
- GitHub CLI
- 支持 Computer Use 的 Codex / Agent 工具

详细安装步骤见：[docs/setup.md](docs/setup.md)。

## 快速开始

进入项目目录：

```bash
cd UIKitLifecycleDemo
```

构建：

```bash
make build
```

打开 Xcode：

```bash
make open
```

构建并启动到 Simulator：

```bash
make run
```

查看最近一次构建日志：

```bash
make logs
```

清理本项目构建产物：

```bash
make clean
```

默认设置：

```text
Scheme: UIKitLifecycleDemo
Simulator: iPhone 17 Pro
```

## 推荐观察方式

先不要一上来就打断点。对初学者来说，断点会把完整流程切碎。

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

断点命中后，在 Call Stack 里找：

- `UIKitCore`
- `UIViewController`
- `UICollectionViewController`
- `UINavigationController`
- `UICollectionView`
- `UIApplication sendAction`

详细观察步骤见：[docs/xcode-observation-guide.md](docs/xcode-observation-guide.md)。

## 预期日志顺序

首次启动：

```text
[ReminderListViewController] init
[ReminderListViewController] viewDidLoad
[ReminderListViewController] setupCollectionView
[ReminderListViewController] listLayout
[ReminderListViewController] configureDataSource
[ReminderListViewController] applyInitialSnapshot
[ReminderListViewController] applyCurrentSnapshot
[ReminderListViewController] viewWillAppear
[ReminderListViewController] CellRegistration
[ReminderListViewController] viewDidAppear
```

点击 cell：

```text
[ReminderListViewController] collectionView(_:didSelectItemAt:)
[ReminderDetailViewController] init(reminderTitle:onSave:)
[ReminderListViewController] collectionView(_:didSelectItemAt:) - push detail
[ReminderDetailViewController] viewDidLoad
[ReminderListViewController] viewWillDisappear
[ReminderDetailViewController] viewWillAppear
[ReminderListViewController] viewDidDisappear
[ReminderDetailViewController] viewDidAppear
```

点击 Save：

```text
[ReminderDetailViewController] saveReminder
[ReminderDetailViewController] saveReminder - about to call onSave
[ReminderListViewController] onSave closure
[ReminderListViewController] update(_:with:)
[ReminderListViewController] applyCurrentSnapshot
[ReminderDetailViewController] saveReminder - about to popViewController
[ReminderDetailViewController] viewWillDisappear
[ReminderListViewController] viewWillAppear
[ReminderDetailViewController] viewDidDisappear
[ReminderListViewController] viewDidAppear
[ReminderDetailViewController] deinit
```

重点确认：返回 List 时，没有新的 List `viewDidLoad`，但会再次出现 List `viewWillAppear / viewDidAppear`。

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

## 核心类比

- `UICollectionView`：货架本体。
- `collectionViewLayout`：摆放规则。
- `DiffableDataSource + Snapshot`：当前陈列清单。
- `CellRegistration`：把商品放进格子的规则。
- `delegate`：用户交互接待员。
- `target-action`：按钮事件登记表。
- `closure`：详情页递回列表页的小纸条。

## 1.0.0 范围

1.0.0 聚焦 UIKit 生命周期和列表回调观察。

暂不包含：

- SwiftUI
- 第三方库
- 网络请求
- 持久化
- UI 自动化测试
- EventKit
- Combine / RxSwift

这些会留给后续版本继续深入。

## License

MIT. See [LICENSE](LICENSE).
