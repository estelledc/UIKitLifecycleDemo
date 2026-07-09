# App 内 Log Panel

## 日常类比

Xcode Console 像一条滚得很快的直播弹幕。Log Panel 像把弹幕存进可暂停的笔记本：你可以只看生命周期，只看点击事件，也可以停下来慢慢读。

## 技术定义

`DemoLogStore` 会把 `DemoLog.print` 记录成结构化 `DemoLogEvent`。每条日志包含序号、时间、分类、owner、method、message、是否关键事件。Xcode Console 仍然会输出 `🧭 [Owner] method - message`，App 内 Logs 则读取同一份事件列表。

## 操作步骤

1. 启动 App。
2. 点击右上角 `Learn`。
3. 点击 `Logs`。
4. 用 `Filter` 选择分类。
5. 打开 `Only Key Events` 只看关键事件。
6. 点击 `Pause Scroll` 暂停自动滚动；再次点击 `Resume Scroll` 恢复自动滚动。
7. 点击 `Copy` 复制当前可见日志。
8. 点击 `Clear` 清空当前存储日志。

注意：当前 Log Panel 的 Filter 一次只能选择一个分类。需要组合观察时，可以保持 `All` 并使用 Search，或分别切换 `Lifecycle`、`Delegate`、`Action`、`Closure`、`Snapshot`、`Cell`、`NavStack` 等分类。

## 推荐筛选

| 学习目标 | 推荐 Filter |
|---|---|
| 首次启动 | 先选 Lifecycle；再切到 List |
| 点击 cell | 先选 Delegate；再切到 Detail 或 Lifecycle |
| Save | 先选 Action；再切到 Closure |
| 列表刷新 | 先选 Snapshot；再切到 Cell |
| push / pop | 先选 NavStack；再切到 Lifecycle |
| 内存释放 | Memory |

## 预期日志

启动时重点看：

```text
init
loadView
viewDidLoad
viewWillAppear
viewDidAppear
```

点击 cell 重点看：

```text
collectionView(_:didSelectItemAt:)
ReminderDetailViewController init
ReminderDetailViewController viewDidLoad
```

Save 重点看：

```text
saveReminder
about to call onSave
onSave closure
applyCurrentSnapshot
deinit
```

## 胜利条件

你能暂停 Logs，并用自己的话说出：哪几条证明生命周期，哪几条证明 delegate，哪几条证明 target-action，哪几条证明 closure。
