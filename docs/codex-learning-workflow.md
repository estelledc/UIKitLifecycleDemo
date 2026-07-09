# 用 Codex 学 iOS 的方法

这个项目不只是一个 UIKit Demo，也是一套学习方法。目标是把“我看教程”变成“我能让 Demo 跑起来，并用日志和断点证明自己懂了”。

## 一句话流程

```text
提出学习目标
-> 让 Codex 建最小 Demo
-> 加日志和断点观察点
-> make build 验证
-> Xcode + Simulator 演示
-> Console 看顺序
-> Call Stack 看调用来源
-> 写学习沉淀
```

## 为什么这样学

UIKit 对新手难，不是因为方法名多，而是因为很多方法不是你直接调用的。

例如：

- `viewDidLoad` 是 UIKit 在加载 view 时调用。
- `didSelectItemAt` 是 UIKit 在用户点击 cell 后回调。
- `saveReminder` 是 UIKit 通过 target-action 调用。
- `onSave` closure 是业务代码主动调用。

只读文字很容易混。用 Codex 搭 Demo，再用 Xcode 断点和 Call Stack 观察，能把“背概念”变成“看证据”。

## 推荐工作流

### 1. 先写清学习目标

不要只说“帮我学 UIKit”。要说清楚你想观察什么。

示例：

```text
请创建一个纯 UIKit Demo，让我观察：
1. viewDidLoad / viewWillAppear / viewDidAppear 的调用顺序；
2. UICollectionViewController 自带 collectionView；
3. 点击 cell 后 didSelectItemAt 如何被 UIKit 回调；
4. Save 按钮如何通过 target-action 调用方法；
5. 详情页如何用 closure 把数据回传列表页。
```

### 2. 要求 Codex 写可观察代码

学习 Demo 不是业务 App，日志就是教学材料。

要求：

- 每个生命周期方法都打印日志。
- 每个用户动作都打印关键数据。
- 每个数据刷新点都打印当前数组或 snapshot。
- 日志里写 class、method 和 message。

### 3. 用 Makefile 固化命令

不要每次重新想 `xcodebuild` 参数。

推荐项目内提供：

```bash
make build
make run
make open
make logs
make clean
```

这样 Codex、你自己、后续读者都用同一套入口。

### 4. 第一轮只看 Console

先别打断点。

原因：断点会暂停流程，新手容易忘记完整顺序。

第一轮目标是回答：

- App 启动时先发生什么？
- 点击 cell 后发生什么？
- Save 后发生什么？
- pop 回列表时 `viewDidLoad` 有没有再次出现？

### 5. 第二轮看断点和 Call Stack

第二轮目标是回答：

- 谁调用了 `viewDidLoad`？
- 谁调用了 `didSelectItemAt`？
- 谁调用了 `saveReminder`？
- 哪些栈帧来自 UIKit？

如果 Call Stack 里看到 `UIViewController`、`UICollectionView`、`UINavigationController`、`UIApplication sendAction`，就说明这些调用来自 UIKit 框架链路。

### 6. 用 Computer Use 做真实演示

让 Agent 真的操作 Xcode 和 Simulator：

- 打开工程。
- 展示源码。
- 设置断点。
- 点击 Run。
- 点击 Simulator 里的 cell。
- 输入新标题。
- 点击 Save。
- 回到 Xcode 看 Console 和 Call Stack。

这比只看终端输出更接近真实 iOS 学习场景。

### 7. 最后写沉淀

一次练习结束后，至少写三件事：

1. 我看到了什么日志。
2. 这些日志说明什么机制。
3. 下次如何复现。

## 可复制 Prompt

### 创建 Demo

```text
你是我的 iOS UIKit 学习教练 + Codex 编程助手。
请创建一个纯 UIKit Demo，不使用 SwiftUI。
目标是通过 Xcode Console、断点和 Call Stack 观察 <填你的主题>。
请写清 README、Makefile、预期日志顺序和断点位置。
完成后运行 make build 验证。
```

### 修复构建失败

```text
请读取当前 Xcode build 日志，先定位第一个真正的 Swift 编译错误。
只修复导致构建失败的最小问题，不做无关重构。
修复后重新运行 make build。
```

### 解释 Console 日志

```text
下面是 Xcode Console 日志。
请按时间顺序解释每一段发生了什么，并指出哪些是 UIKit 自动调用，哪些是我的业务代码主动调用。
```

### 断点和 Call Stack 讲解

```text
我在 <方法名> 断点停住了。
请根据 Call Stack 解释是谁把这个方法调起来的。
重点帮我区分 UIKit 自动回调、delegate、target-action 和 closure。
```

### 学习沉淀

```text
请把这次练习沉淀成：
1. 一段 daily 事实记录；
2. 一张练习证据卡；
3. 一篇可复用学习笔记；
4. 下一次实验建议。
要求中文、新手友好、用日常类比解释。
```

## 判断自己是否真的学会

不是“看完 README”就算学会。

至少要能做到：

- 不看代码说出启动、点击、Save、pop 的日志顺序。
- 能在 Call Stack 里指出 UIKit 相关栈帧。
- 能解释 delegate、target-action、closure 的区别。
- 能说出为什么 pop 回 List 时 `viewDidLoad` 不再次执行。
- 能自己设计一个小实验验证一个新概念。
