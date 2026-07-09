# Call Stack 教学指南

## 日常类比

Console 像监控录像，只告诉你发生了什么。Call Stack 像来电记录，告诉你这个方法是谁一路打电话叫起来的。

## 技术定义

断点命中时，Call Stack 会显示当前方法的调用链。UIKit 方法不是你手动调用的证据，通常就在栈里的 `UIKitCore`、`UIViewController`、`UICollectionViewController`、`UINavigationController`、`UIApplication sendAction`。

## 断点位置

在源码 gutter 设置 5 个断点：

- `ReminderListViewController.viewDidLoad`
- `ReminderListViewController.viewWillAppear`
- `ReminderListViewController.collectionView(_:didSelectItemAt:)`
- `ReminderDetailViewController.viewDidLoad`
- `ReminderDetailViewController.saveReminder`

## 固定观察动作

每次断点命中：

1. 鼠标指向当前高亮代码行。
2. 鼠标指向左侧 Call Stack。
3. 鼠标指向底部 LLDB。
4. 输入：

   ```lldb
   bt
   ```

5. 只找一个关键词，不要一次解释所有概念。

## 每个断点问什么

| 断点 | 触发动作 | 关注关键词 | 教学问题 |
|---|---|---|---|
| List `viewDidLoad` | Run App | `UIViewController loadViewIfRequired` | 是谁第一次需要 List 的 view？ |
| List `viewWillAppear` | Run 或 pop 回 List | `UIViewController` / `UINavigationController` | 返回时它会不会再次命中？ |
| `didSelectItemAt` | 点击 cell | `UICollectionView` | 是业务代码手动调用，还是 UIKit 点击回调？ |
| Detail `viewDidLoad` | push Detail | `UINavigationController` | Detail 的 view 是什么时候加载的？ |
| `saveReminder` | 点击 Save | `UIApplication sendAction` | Save 是什么机制触发的？ |

## 胜利条件

你能说出：

- 生命周期：UIKit 根据页面状态调用。
- delegate：UIKit 根据用户点击回调。
- target-action：UIKit 根据按钮事件调用。
- closure：业务代码主动调用，用来传数据。
