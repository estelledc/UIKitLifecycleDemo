# Xcode 观察指南

这份指南帮你亲眼看到 UIKit 什么时候调用生命周期、delegate、target-action、layout、navigation stack 和 closure。

## 核心方法：两轮观察

第一轮像看监控录像：不暂停，先看完整顺序。

第二轮像按暂停键：打断点，看是谁把方法调起来。

## 第一轮：只看 Console

1. 打开 Xcode：

   ```bash
   make open
   ```

2. 选择：

   ```text
   Scheme: UIKitLifecycleDemo
   Simulator: iPhone 17 Pro
   ```

3. 禁用所有断点。
4. 点击 Run。
5. 打开 Debug Console。
6. 观察首次启动日志。
7. 在 Simulator 点击第一行 `Buy groceries`。
8. 修改文本，例如 `Buy groceries today`。
9. 点击 Save。
10. 回到 Console 看完整日志顺序。

观察时先抓以 `🧭` 开头的日志。其他系统日志通常不是这个 Demo 的教学重点。

### 首次启动重点

你应该看到：

```text
init
loadView
viewDidLoad
setupCollectionView
listLayout
configureDataSource
applyInitialSnapshot
applyCurrentSnapshot
viewWillAppear
CellRegistration
viewDidAppear
```

理解：

- `loadView` 是 UIKit 创建 root view 的入口。
- `viewDidLoad` 是 view 第一次加载完成。
- `viewWillAppear` 是页面即将出现。
- `CellRegistration` 是 item 变成 cell 的配置点。

### 点击 cell 重点

你应该看到：

```text
collectionView(_:didSelectItemAt:)
ReminderDetailViewController init
Detail loadView
Detail viewDidLoad
List viewWillDisappear
Detail viewWillAppear
List viewDidDisappear
Detail viewDidAppear
```

理解：

- `didSelectItemAt` 不是你手动调用的。
- UIKit 收到点击后，通过 collection view delegate 回调给你。
- push/show 过程中，旧页面消失，新页面出现。

### 点击 Save 重点

你应该看到：

```text
saveReminder
about to call onSave
onSave closure
update(_:with:)
applyCurrentSnapshot
about to popViewController
Detail viewWillDisappear
List viewWillAppear
Detail viewDidDisappear
List viewDidAppear
Detail deinit
```

理解：

- Save 按钮通过 target-action 或 UIAction 调用 `saveReminder`。
- `onSave` closure 把 edited title 回传给 List。
- List 更新数据后重新 apply snapshot。
- pop 回 List 时，没有新的 List `viewDidLoad`。

## 第二轮：断点 + Call Stack

建议断点：

1. `ReminderListViewController.viewDidLoad`
2. `ReminderListViewController.viewWillAppear`
3. `ReminderListViewController.collectionView(_:didSelectItemAt:)`
4. `ReminderDetailViewController.viewDidLoad`
5. `ReminderDetailViewController.saveReminder`

每次断点命中后，看左侧 Debug Navigator 的 Call Stack。

也可以在 LLDB 输入：

```lldb
bt
```

把输出贴进这个模板：

```text
断点位置：
触发操作：
UIKit 关键词：
最靠近当前方法的业务代码：
我的结论：
```

## Call Stack 怎么读

### `viewDidLoad`

找这些关键词：

```text
UIViewController loadViewIfRequired
UIViewController _sendViewDidLoad
UINavigationController
UIApplicationMain
```

结论：UIKit / 导航控制器在加载页面 view，不是业务代码手动调用 `viewDidLoad()`。

### `viewWillAppear`

找这些关键词：

```text
UIViewController _setViewAppearState
UICollectionViewController __viewWillAppear
UINavigationController transition
```

结论：页面即将出现时，UIKit 通知 ViewController。

### `didSelectItemAt`

找这些关键词：

```text
UICollectionView _userSelectItemAtIndexPath
UICollectionView touchesEnded
UIWindow sendEvent
UIApplication sendEvent
```

结论：用户触摸被 UIKit 转成 collection view 的 delegate 回调。

### `saveReminder`

找这些关键词：

```text
UIBarButtonItem _triggerActionForEvent
UIApplication sendAction
UIControl sendAction
```

结论：Save 按钮点击通过 target-action 或 UIAction 调用了你的代码。

## 第三轮：实验菜单

打开 App 后点右上角 `Experiments`。

| 菜单 | 操作 | 看什么 |
|---|---|---|
| Show / Push / Present | 用三种方式打开第一条 reminder | navigation stack、presentingViewController、pop/dismiss |
| Full Apply / Reload / Reconfigure | 修改第一条 title | `applyCurrentSnapshot` 和 `CellRegistration` 配置次数 |
| Toggle Save | 切换后进入详情页点击 Save | target-action 或 UIAction 日志 |
| Toggle Closure | 切换后 Save | `weakSelf` 或 `strongSelf` 捕获日志、`deinit` |
| Load 50 Reuse Items | 滚动列表 | `ReminderCell init / prepareForReuse / updateConfiguration` |
| String Identity Experiment | 打开对照页 | 重复 String identifier 的风险日志 |
| Manual UIViewController Version | 打开手动版本 | 手动创建 collectionView、layout、dataSource、delegate |

## Memory Graph 观察

1. Xcode 运行 App。
2. 打开 Detail，点击 Save 返回。
3. 看 Console 是否出现 `🧭 [ReminderDetailViewController] deinit`。
4. 点击 Xcode Debug Bar 里的 Memory Graph。
5. 搜索 `ReminderDetailViewController`。

理解：

- 出现 `deinit`：这个 Detail 实例已经释放。
- closure 默认强捕获对象。
- `[weak self]` 可以避免 closure 把对象强留住。
- 不是所有强捕获都会泄漏，要看对象之间是否形成无法断开的引用链。

## UI Test

命令行运行：

```bash
make test-ui
```

测试会自动执行：

```text
启动 App -> 点击 Buy groceries -> 输入 Buy groceries today -> Save -> 断言列表更新
```

## 新手常见误区

| 误区 | 正确理解 |
|---|---|
| `viewDidLoad` 每次页面出现都会走 | 同一个 VC 实例通常只加载一次 view |
| 点击 cell 是自己调用 `didSelectItemAt` | UIKit 收到点击后回调 delegate |
| Save 是 List 调用 Detail 的方法 | UIKit 通过按钮事件调用 Detail 的 `saveReminder` |
| closure 是 UIKit 自动调用 | closure 是业务代码主动调用的数据回传通道 |
| 数据变了 cell 就一定变 | diffable data source 需要 apply snapshot |
| `viewDidLoad` 后尺寸就稳定 | 最终尺寸更适合在 `viewDidLayoutSubviews` 观察 |
| cell 数量等于数据数量 | collection view 会复用 cell |

## 操作建议

- Xcode 放左边，Simulator 放右边。
- 第一轮禁用断点，只看完整顺序。
- 第二轮再启用断点。
- Console 里 haptic、accessibility、gesture timeout 等日志多数是 Simulator 噪声。
- 如果 LLDB 临时断点重复命中，说明符号匹配太宽，不等于源码坏了。
