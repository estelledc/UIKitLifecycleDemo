# UIKitLifecycleDemo

一个纯 UIKit、纯代码的中文学习实验室。它不是提醒事项业务 App，而是一台“UIKit 显微镜”：你可以在 App 内 Logs、Xcode Console、断点和 Call Stack 里观察 UIKit 什么时候自动调用生命周期、delegate、target-action、closure 回传、snapshot 刷新和 cell 复用。

## 5 分钟 Guided Tour

推荐第一次学习先走这条路线：

1. 运行 App。
2. 点右上角 `Learn -> Guide`。
3. 按 Guide 里的步骤预测、操作、观察、复盘。
4. 点 `Logs` 打开 App 内日志面板，不要一开始就盯 Xcode Console。

核心四步：

```text
启动 List -> 点击 cell -> Save -> pop 回 List
```

你最终要亲眼确认：

- `viewDidLoad` 只在 view 第一次加载后执行。
- `viewWillAppear / viewDidAppear` 每次页面重新出现都会执行。
- `didSelectItemAt` 是 UIKit 收到 cell 点击后的 delegate 回调。
- `saveReminder` 是按钮事件通过 target-action 或 UIAction 触发。
- `onSave closure` 是 Detail 把编辑结果交回 List 的业务通道。
- Detail pop 后出现 `deinit`，说明详情页释放了。

## 如何运行

```bash
cd explorations/_active/UIKitLifecycleDemo
make build
make open
make run
make test-ui
```

默认设置：

```text
Scheme: UIKitLifecycleDemo
Simulator: iPhone 17 Pro
```

如果没有这个模拟器：

```bash
make build SIMULATOR_NAME="iPhone 16 Pro"
```

环境准备见 [docs/setup.md](docs/setup.md)。

## 如何打开 Logs

像看慢放录像一样，Logs 面板让你不用追着 Xcode Console 跑。

操作：

1. 启动 App。
2. 点击右上角 `Learn`。
3. 点击 `Logs`。
4. 用 Filter 选择 `Lifecycle / Delegate / Action / Closure / Snapshot / Cell / NavStack`。
5. 打开 `Only Key Events` 只看关键事件。
6. 点击 `Pause` 暂停自动滚动。
7. 点击 `Copy` 复制当前可见日志给 ChatGPT 分析。

详细说明见 [docs/log-panel.md](docs/log-panel.md)。

## 如何使用 Guide

Guide 是带学模式。每张卡片都有：

- 当前做什么
- 应该看哪里
- 操作前预测
- 预期日志
- 完成后理解问题
- 一句话复盘
- 胜利条件

详细说明见 [docs/guided-learning.md](docs/guided-learning.md)。

## 完整实验目录

入口：`Learn -> Experiments`

| 实验 | 观察重点 |
|---|---|
| Show / Push / Present | 展示方式、navigation stack、pop/dismiss |
| Snapshot Full Apply / Reload / Reconfigure | diffable snapshot 如何刷新列表 |
| Toggle Save | target-action 与 UIAction 的差异 |
| Toggle Closure | weak/strong capture 与 deinit / Memory Graph |
| Load 50 Reuse Items | cell init、updateConfiguration、prepareForReuse |
| String Identity Experiment | 重复 String identifier 的风险 |
| Manual UIViewController Version | 手动创建 collectionView 的对照实验 |

## Xcode Call Stack 验证

Logs 负责看顺序，Call Stack 负责看“是谁调用的”。

建议断点：

- `ReminderListViewController.viewDidLoad`
- `ReminderListViewController.viewWillAppear`
- `ReminderListViewController.collectionView(_:didSelectItemAt:)`
- `ReminderDetailViewController.viewDidLoad`
- `ReminderDetailViewController.saveReminder`

断点命中后，在 LLDB 输入：

```lldb
bt
```

重点找：

- `UIKitCore`
- `UIViewController`
- `UICollectionViewController`
- `UINavigationController`
- `UIApplication sendAction`

详细步骤见 [docs/call-stack-teaching.md](docs/call-stack-teaching.md)。

## 项目结构

```text
UIKitLifecycleDemo.xcodeproj
UIKitLifecycleDemo/
  AppDelegate.swift
  SceneDelegate.swift
  DemoLogStore.swift
  DemoLogPanelViewController.swift
  GuidedExperiment.swift
  GuidedExperimentViewController.swift
  ExperimentSupport.swift
  ReminderListViewController.swift
  ReminderDetailViewController.swift
  ReminderCell.swift
  StringIdentityExperimentViewController.swift
  ManualCollectionViewController.swift
UIKitLifecycleDemoUITests/
  UIKitLifecycleDemoUITests.swift
docs/
Makefile
CHANGELOG.md
LICENSE
```

入口链路：

```text
SceneDelegate
-> UIWindow
-> UINavigationController
-> ReminderListViewController
```

## 学习方法

日常类比：UIKit 像舞台管理员。你写的 view controller 不是自己上台，而是等舞台管理员通知“该加载 view 了”“该出现了”“按钮被点了”“cell 被选中了”。

技术定义：

- 生命周期：UIKit 根据页面状态自动调用。
- delegate：UIKit 把用户操作回调给你。
- target-action：UIKit 根据控件事件调用 selector/action。
- closure：业务代码自己设计的数据回传通道。

Codex 学习流程见：

- [docs/codex-learning-workflow.md](docs/codex-learning-workflow.md)
- [docs/agent-flow.md](docs/agent-flow.md)
- [docs/computer-use-sop.md](docs/computer-use-sop.md)

## 版本范围

- `1.0.0`：基础 UIKit 生命周期、collection view、delegate、target-action、closure。
- `1.1.0`：扩展可观测实验。
- `1.2.0`：App 内 Logs、Guided Learning、慢速 Computer Use SOP。
