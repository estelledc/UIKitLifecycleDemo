# Changelog

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
