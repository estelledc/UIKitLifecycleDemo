# UIKitLifecycleDemo 1.2.0 Roadmap

## Vision

把 UIKitLifecycleDemo 从“可观测 UIKit Demo”升级为“Guided UIKit Learning Lab”。

学习节奏：

```text
Predict -> Run -> Pause -> Observe -> Explain -> Verify -> Recap
```

## 1.2.0 已推进方向

- `DemoLogStore`：结构化日志，保留 Console 输出。
- App 内 Log Panel：筛选、暂停、清空、复制、关键事件高亮。
- Guided Experiment Mode：核心四步和高级实验导览。
- `Use Example Title`：减少键盘噪声。
- Computer Use SOP：慢速带看流程。
- Call Stack 教学指南：断点、LLDB `bt`、观察关键词。

## 后续 Roadmap

- 给 Guide 增加完成状态和当前步骤进度。
- 给 Log Panel 增加按 experimentID 分组。
- 给 Call Stack 教学补截图或短 GIF。
- 扩展 UI Test 覆盖所有高级实验入口。
- 增加 Memory Graph 截图教程。
- 发布 `v1.2.0` release notes。

## 非目标

- 不引入 SwiftUI。
- 不引入第三方业务库。
- 不加入网络、持久化、EventKit。
- 不把 Demo 改成生产提醒事项 App。
