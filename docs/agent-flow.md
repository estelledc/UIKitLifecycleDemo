# Agent 协作流程

这份文档记录如何让 Codex / Agent 帮你学习 iOS，而不是只替你写代码。

## 角色分工

| 角色 | 负责什么 |
|---|---|
| 你 | 提出学习目标、观察现象、判断自己是否理解 |
| Codex | 创建项目、写代码、修构建、整理文档 |
| Xcode | 展示源码、Console、断点、Call Stack |
| Simulator | 模拟真实用户操作 |
| Computer Use | 让 Agent 像人一样操作 Xcode 和 Simulator |
| 笔记 | 保存事实、证据、机制和下次 SOP |

## 一次完整学习任务

```text
1. 定义学习目标
2. Codex 创建最小 Demo
3. Codex 加日志和 README
4. make build 验证
5. Xcode 打开工程
6. 第一轮禁用断点看 Console
7. 第二轮启用断点看 Call Stack
8. Simulator 做真实点击和输入
9. Codex 修复发现的问题
10. 沉淀 daily / lesson / learning
```

## 给 Agent 的任务要怎么写

好的任务描述应该包含：

- 项目名
- 技术栈
- 不要做什么
- 页面结构
- 必须观察的日志
- 必须打的断点
- 构建验证方式
- 最终讲解格式

示例：

```text
请创建一个纯 UIKit Demo，不使用 SwiftUI。
页面包括列表页和详情页。
列表页用 UICollectionViewController、diffable data source 和 CellRegistration。
点击 cell push 详情页。
详情页 Save 用 target-action 调用 saveReminder，再通过 closure 回传数据。
每个生命周期方法都打印日志。
完成后运行 make build，并告诉我在 Xcode 里怎么观察 Console 和 Call Stack。
```

## Agent 执行阶段

### 阶段 1：建项目

Codex 负责：

- 创建 Xcode 工程。
- 写 `SceneDelegate` 入口。
- 保证 root 是 `UINavigationController`。
- 写 `Makefile`。

你要看：

- App 是否能启动。
- 首屏是否是目标页面。

### 阶段 2：写可观察代码

Codex 负责：

- 生命周期日志。
- 用户操作日志。
- 数据变化日志。
- README 里的预期顺序。

你要看：

- 日志是否能解释流程。
- 有没有关键信息，比如 indexPath、title、snapshot。

### 阶段 3：构建验证

Codex 负责：

```bash
make build
```

如果失败，先修第一个真实错误。

你要看：

- 构建是否通过。
- 修复是否只改相关问题。

### 阶段 4：Computer Use 演示

Codex 负责操作：

- 打开 Xcode。
- 打开源码。
- 设置断点。
- 运行 App。
- 操作 Simulator。
- 回到 Xcode 展示 Console 和 Call Stack。

你要看：

- 是不是亲眼看到了日志。
- 断点是否停在预期方法。
- Call Stack 是否有 UIKit 相关栈帧。

### 阶段 5：学习沉淀

Codex 负责整理：

- 事实记录：今天跑通什么。
- 证据卡：日志、断点、Call Stack。
- 知识笔记：机制、类比、误区。
- SOP：下次怎么复现。

你要看：

- 下次能否照文档复现。
- 是否把“我觉得”变成了“我看到”。

## Agent 使用注意

1. 不要只让 Agent 写完代码就结束。
2. 要求 Agent 运行构建验证。
3. 要求 Agent 解释 Console 日志。
4. 要求 Agent 展示 Call Stack，而不是只说“这是 UIKit 调的”。
5. 遇到 Simulator 抢焦点，先调整窗口布局。
6. 遇到断点太多，先回到“第一轮只看 Console”。
7. 学习结束必须沉淀，不然下次还会从零开始。

## 验收标准

一次 Agent 辅助 iOS 学习任务完成时，应该同时有：

- 可运行 Demo。
- 构建通过记录。
- README。
- Console 日志预期顺序。
- 断点位置。
- Call Stack 观察结论。
- 一段学习总结。
- 下一次实验建议。
