# UIKit Lifecycle Lab

一个纯 UIKit、纯代码的中文学习实验室。它不是提醒事项业务 App，而是一台“UIKit 显微镜”：用 Guided Steps、结构化日志、Xcode Call Stack 和 UI Test，观察 UIKit 什么时候自动调用生命周期、delegate、target-action、closure 回传、snapshot 刷新和 cell 复用。

> **English summary:** A code-first UIKit learning lab that makes framework-driven behavior observable through guided experiments, structured logs, call stacks, and UI tests.

[公开案例页](https://estelledc.github.io/UIKitLifecycleDemo/) · [Guided Learning](docs/guided-learning.md) · [Call Stack 教学](docs/call-stack-teaching.md)

案例页使用 List、Logs、Guide 三张真实 iPhone Simulator 截图；网页只解释系统，运行证据仍来自 UIKit App、Call Stack 与 XCTest。

## 公开案例

### Problem

UIKit 的很多关键方法不是业务代码直接调用的。只读 `viewDidLoad`、`didSelectItemAt` 或 `saveReminder` 的定义，很容易把框架生命周期、delegate 回调、按钮事件和业务 closure 混在一起。

### Role

- **Jason**：定义学习目标、选择观察机制、编排验证路线，并用真实 Xcode / Simulator 结果验收。
- **Codex / AI**：辅助搭建 Demo、实现结构化日志与文档、迭代自动化测试。
- **Xcode / Simulator / XCTest**：提供最终运行证据；README 中的预期顺序不替代真实构建与观察。

### System

```text
Predict -> Run -> Observe -> Verify -> Recap
  Guide     App      Logs     Stack/Test   复盘
```

1. `GuidedStep` 把操作、观察位置、预测问题、预期日志和胜利条件放在同一张训练卡里。
2. `DemoLogStore` 同时保存结构化事件并输出 Xcode Console。
3. App 内 Log Panel 支持分类、搜索、关键事件、暂停滚动与复制。
4. Call Stack 回答“谁触发”，UI Test 检查关键用户流程。

### Evidence

| 可核验事实 | 当前仓库依据 |
|---|---|
| 9 个引导步骤 | `UIKitLifecycleDemo/GuidedExperiment.swift` |
| 14 类结构化日志 | `UIKitLifecycleDemo/DemoLogStore.swift` |
| 2 条 UI Test 流程 | `UIKitLifecycleDemoUITests/UIKitLifecycleDemoUITests.swift` |
| 纯 UIKit、纯代码入口 | `SceneDelegate -> UINavigationController -> ReminderListViewController` |
| 可重复构建 | `Makefile` 中的 `build / run / test-ui` |

这些数字描述当前实现范围，不代表学习效果。

### Limitations

- 这是学习实验室，不是生产级提醒事项 App。
- 不包含网络、持久化、EventKit 或真实业务状态。
- Guide 描述预期观察，不会生成或伪造日志。
- 两条 UI Test 只覆盖核心编辑流程和 Guide / Logs 入口，尚未覆盖全部高级实验。
- 项目不声称仅凭阅读或运行 Demo 就能掌握 UIKit。

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
- `viewWillAppear / viewDidAppear` 在页面重新出现时再次执行。
- `didSelectItemAt` 是 UIKit 收到 cell 点击后的 delegate 回调。
- `saveReminder` 由 target-action 或 UIAction 触发。
- `onSave closure` 是 Detail 把编辑结果交回 List 的业务通道。
- Detail pop 后出现 `deinit`，说明该详情页实例释放。

完整说明见 [docs/guided-learning.md](docs/guided-learning.md)。

## 本地运行

```bash
make build
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
make run SIMULATOR_NAME="iPhone 16 Pro"
```

环境准备见 [docs/setup.md](docs/setup.md)。

## 如何观察

### App 内 Logs

1. 点击 `Learn -> Logs`。
2. 用 Filter 分别观察 `Lifecycle`、`Delegate`、`Action`、`Closure`、`Snapshot`、`Cell`、`NavStack`。
3. 打开 `Only Key Events` 只看关键事件。
4. 用 `Pause Scroll / Resume Scroll` 控制自动滚动。
5. 点击 `Copy` 复制当前可见日志。

详细说明见 [docs/log-panel.md](docs/log-panel.md)。

### Xcode Call Stack

Logs 负责看顺序，Call Stack 负责看“是谁调用的”。建议断点：

- `ReminderListViewController.viewDidLoad`
- `ReminderListViewController.viewWillAppear`
- `ReminderListViewController.collectionView(_:didSelectItemAt:)`
- `ReminderDetailViewController.viewDidLoad`
- `ReminderDetailViewController.saveReminder`

断点命中后在 LLDB 输入 `bt`，寻找 `UIKitCore`、`UIViewController`、`UICollectionViewController`、`UINavigationController` 与 `UIApplication sendAction`。完整步骤见 [docs/call-stack-teaching.md](docs/call-stack-teaching.md)。

## 实验入口

入口：`Learn -> Experiments`

| 实验 | 观察重点 |
|---|---|
| Show / Push / Present | 展示方式、navigation stack、pop / dismiss |
| Snapshot Full Apply / Reload / Reconfigure | diffable snapshot 如何刷新列表 |
| Toggle Save | target-action 与 UIAction 的差异 |
| Toggle Closure | weak / strong capture 与 `deinit` / Memory Graph |
| Load 50 Reuse Items | cell init、updateConfiguration、prepareForReuse |
| String Identity Experiment | 重复 String identifier 的风险 |
| Manual UIViewController Version | 手动创建 collection view 的对照实验 |

## 公开展示验证

GitHub Pages 源文件位于 `docs/`，不改动核心 UIKit 演示代码。执行：

```bash
make check
make test-ui
git diff --check
```

其中 `make verify-showcase` 会检查：

- 学习系统、真实界面、调用链、验证证据与公开边界。
- canonical、Open Graph、Twitter Card、JSON-LD 和分享图片尺寸。
- 站内链接、锚点、图片 alt 与尺寸属性。
- 9 / 14 / 2 三项展示数字是否仍与 Swift 源码一致。
- 与 Jason Xun 主站一致的 Jason DS 2.2.0 vendor copy、纸白/墨黑双主题、响应式导航、证据来源标签和返回主站入口。
- 所有第三方 GitHub Actions 是否固定到完整 40 位 commit SHA。
- List、Logs、Guide 三张 Simulator 截图及其尺寸。
- PR 与 `main` 均执行 generic iOS Simulator 构建和网页审计；只有 `main` 两类检查通过后才部署 Pages。

App 图标变更后，可先安装 Pillow，再运行 `python3 scripts/generate-showcase-assets.py` 重建 favicon 并校验已跟踪的分享图尺寸。

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
docs/
  index.html                 # 公开案例页
  assets/                    # 统一页面样式、项目图标、真实模拟器截图与分享图
scripts/
  audit-showcase.py
  public-scan.sh
  verify-actions-pinned.py
Makefile
CHANGELOG.md
LICENSE
```

## 版本范围

- `1.0.0`：基础 UIKit 生命周期、collection view、delegate、target-action、closure。
- `1.1.0`：扩展可观察实验。
- `1.2.0`（Building）：App 内 Logs、Guided Learning 与 Computer Use SOP；尚未正式发布。

项目代码使用 MIT License。课程式说明和运行结论以仓库当前源码及本地验证为准。
