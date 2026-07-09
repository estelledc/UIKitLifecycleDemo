# Computer Use 慢速教学 SOP

## 日常类比

Computer Use 不应该像代驾一脚油门开完全程，而应该像教练车：每一步先说看哪里，再慢慢操作，停下来确认你真的看到了。

## 窗口摆放

推荐：

```text
左侧 65%：Xcode
  - Source editor
  - Debug Navigator / Call Stack
  - Debug Console / LLDB

右侧 35%：iOS Simulator
  - UIKitLifecycleDemo
  - App 内 Logs 优先打开
```

小屏幕时：

1. 第一轮只看 Simulator + App 内 Logs。
2. 第二轮再切到 Xcode + Call Stack。

## 固定节奏

每一步都按这个节奏：

```text
Predict -> Point -> Act -> Pause -> Observe -> Explain -> Ask -> Continue
```

具体要求：

- 操作前先问预测问题。
- 鼠标必须指到要看的区域。
- 点击前停 3 到 5 秒。
- 关键日志出现后停 10 到 20 秒。
- 一次只解释一个结论。
- 不要一开始就打断点打碎完整顺序。

## 第一轮：App 内 Logs

目标：看完整顺序。

步骤：

1. Run App。
2. 打开 `Learn -> Logs`。
3. Filter 选 `Lifecycle`，看启动生命周期。
4. 回到 List，点击 `Buy groceries`。
5. Filter 先选 `Delegate` 看点击回调，再切到 `Detail` 看详情页生命周期。
6. 点击 `Use Example Title`。
7. 点击 `Save`。
8. Filter 先选 `Action`，再分别切到 `Closure`、`Snapshot`、`Memory`。
9. 对比：返回 List 时没有新的 List `viewDidLoad`。

## 第二轮：Xcode Call Stack

目标：看调用来源。

步骤：

1. 设置源码行断点，不用宽泛 regex breakpoint。
2. 命中断点后，鼠标指向当前高亮行。
3. 鼠标指向 Call Stack。
4. 在 LLDB 输入 `bt`。
5. 只找一个关键词。

关键词：

- `UIKitCore`
- `UIViewController`
- `UICollectionViewController`
- `UINavigationController`
- `UIApplication sendAction`

## 避免噪声

- 第一轮优先用 App 内 Logs，不盯 Xcode Console。
- 如必须看 Console，只过滤 `🧭`。
- 教学时优先用 `Use Example Title`，减少键盘和 haptic 系统日志。
- 忽略 `CHHapticPattern`、`UIAccessibilityLoaderWebShared`、`Gesture gate timed out`。

## 胜利条件

学习者能自己说出：

- 这条日志证明了哪个 UIKit 机制。
- 这个断点是谁触发的。
- 这一步下一次如何复现。
