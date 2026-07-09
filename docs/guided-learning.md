# Guided Learning

## 日常类比

Guide 像教练手里的训练卡。不是让你一次看完所有器械，而是一张卡只练一个动作：先预测，再操作，再看证据，最后复盘。

## 技术定义

`GuidedExperiment` 描述一次学习路线，`GuidedStep` 描述一个观察步骤。Guide 不伪造日志，它只告诉你应该做什么、看哪里、预期会出现哪些真实日志。

## 5 分钟核心路线

### Step 1：启动生命周期

操作：打开 `Learn -> Guide` 和 `Learn -> Logs`。

看哪里：先选 `Lifecycle` 看生命周期；再切到 `List` 看列表日志；也可以保持 `All` 并搜索 `viewDidLoad`。

预期日志：

```text
init -> loadView -> viewDidLoad -> viewWillAppear -> viewDidAppear
```

胜利条件：能说出 `viewDidLoad` 只在 view 第一次加载后执行。

### Step 2：点击 cell

操作：回到列表，点击 `Buy groceries`。

看哪里：先选 `Delegate` 看 `didSelectItemAt`；再切到 `Detail` 或 `Lifecycle` 看详情页出现顺序。

预期日志：

```text
didSelectItemAt -> Detail init -> Detail viewDidLoad
```

胜利条件：能说出 `didSelectItemAt` 是 UIKit 触发的 delegate 回调。

### Step 3：Save

操作：第一轮教学点击 `Use Example Title`，再点击 `Save`；第二轮再手动输入标题观察键盘相关日志。

看哪里：先选 `Action` 看 `saveReminder`；再切到 `Closure` 看 `onSave` 回传。

预期日志：

```text
useExampleTitle -> saveReminder -> about to call onSave
```

胜利条件：能说出 Save 是 target-action 或 UIAction 触发的。

### Step 4：pop 回 List

操作：Save 后不要立刻继续点。

看哪里：先选 `Closure` 看 `onSave`；再分别切到 `Snapshot`、`NavStack`、`Memory` 看刷新、返回和 `deinit`。

预期日志：

```text
onSave closure -> update -> applyCurrentSnapshot -> pop -> List viewWillAppear -> Detail deinit
```

胜利条件：能说出返回 List 时 `viewDidLoad` 不再出现，但 `viewWillAppear / viewDidAppear` 会出现。

## 高级路线

- Cell reuse：加载 50 条数据并滚动。
- Snapshot：比较 Full Apply、Reload、Reconfigure。
- Show / Push / Present：观察 navigation stack 和返回方式。
- Closure memory：切换 weak/strong capture，看 `deinit` 和 Memory Graph。
- Manual CollectionView：对照手动创建 collectionView 的版本。
