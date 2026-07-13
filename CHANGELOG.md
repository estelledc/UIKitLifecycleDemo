# Changelog

## 1.2.0 - Unreleased

升级为 Guided UIKit Learning Lab。

### Added

- `DemoLogStore`：把教学日志保存为结构化事件，同时保留 Xcode Console 输出。
- App 内 `Logs` 面板：支持分类筛选、暂停自动滚动、清空、复制可见日志、只看关键事件。
- `GuidedExperimentViewController`：提供 5 分钟核心导览和高级实验导览。
- Detail 页 `Use Example Title` 按钮，减少第一轮教学中的键盘和 haptic 噪声。
- `docs/log-panel.md`、`docs/guided-learning.md`、`docs/call-stack-teaching.md`、`docs/computer-use-sop.md`、`docs/uikit-lifecycle-demo-1.2.0-roadmap.md`。
- GitHub Pages 公开案例页，展示 List、Logs、Guide 三张真实 Simulator 截图和可验证证据。

### Changed

- 导航栏实验入口改为 `Learn` 菜单，集中放置 Guide、Logs 和 Experiments。
- README 改成课程入口，优先引导 App 内 Logs 和 Guided Tour。
- 日志重新保持 `🧭 [Owner] method - message` 前缀，方便 Console 过滤。
- Pages 工作流同时验证 generic iOS Simulator 构建、公开边界与完整 SHA Action 固定。
- GitHub Pages 接入与个人主站一致的 Jason DS 2.2.0 vendor copy、证据标签、返回主站入口与编辑式社交预览。

### Fixed

- 修复 GitHub Pages 指标栏绕过共享容器、在桌面视口向左错位的问题，并增加结构审计防止同类回归。
- 修复 Simulator 截图在三列布局中保留 `2622px` 固定高度、导致画面纵向拉伸的问题。

## 1.1.0 - 2026-07-09

扩展可观测实验版。

### Added

- 12 组可观测实验：Call Stack、`loadView`、布局生命周期、Navigation Stack、show/push/present、Diffable identity、snapshot 更新、cell 复用、target-action vs UIAction、closure 捕获、手动 collection view、UI Test。
- 统一 `[ClassName] method - message` 教学日志前缀。
- `ReminderCell` 自定义 cell，打印 `init / updateConfiguration(using:) / prepareForReuse / deinit`。
- `StringIdentityExperimentViewController`，安全展示重复 `String` identifier 风险。
- `ManualCollectionViewController`，对比 `UICollectionViewController` 和手动 `UIViewController + UICollectionView`。
- UI Test target，自动验证点击、编辑、Save 后列表更新。
- `make test-ui` 命令。

### Changed

- Detail 支持 show、push、present 三种展示方式，并根据展示方式选择 pop 或 dismiss。
- Save 支持 target-action 和 UIAction 两种写法。
- Snapshot 更新实验支持 full apply、reload item、reconfigure item。
- README 和 Xcode 观察指南扩展为 1.1.0 实验手册。

## 1.0.0 - 2026-07-09

首个公开学习版。

### Added

- 纯 UIKit、纯代码 iOS Demo。
- `UINavigationController -> ReminderListViewController -> ReminderDetailViewController` 页面链路。
- `UICollectionViewController` + `UICollectionViewCompositionalLayout.list` 列表。
- `UICollectionViewDiffableDataSource`、snapshot、`CellRegistration`。
- 生命周期、delegate、target-action、closure 回传日志。
- Add、Delete、All / Today / Future filter、Same 重名实验。
- 自定义 `ReminderProgressView`，用于观察 `layoutSubviews`、`draw(_:)`、`UIStackView`、AutoLayout、accessibility 和动画终态。
- `Makefile`：`make build / make run / make open / make logs / make clean`。
- 中文 README、环境准备、Codex 学习流程、Xcode 观察指南、Agent 协作流程。

### Fixed

- 补齐 `ReminderListViewController.viewWillAppear(_:)` 中的 `super.viewWillAppear(animated)` 调用。

### Notes

- 1.0.0 面向中文 iOS 新手，重点是用 Console、断点和 Call Stack 观察 UIKit 自动调用链。
