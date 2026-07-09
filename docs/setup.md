# 环境准备

这份 Demo 的目标是让你用真实 Xcode 和 Simulator 观察 UIKit 行为，所以环境重点不是装很多库，而是把 Apple 官方工具链跑通。

## 必需工具

### Xcode

从 App Store 或 Apple Developer 下载并安装 Xcode。

安装后检查：

```bash
xcodebuild -version
```

如果第一次运行提示接受协议，可以执行：

```bash
sudo xcodebuild -license
```

### Xcode Command Line Tools

检查：

```bash
xcode-select -p
```

如果没有安装：

```bash
xcode-select --install
```

### iOS Simulator

打开 Xcode 后确认已安装 iOS Simulator runtime。

本项目默认使用：

```text
iPhone 17 Pro
```

如果你的机器没有这个模拟器，可以在运行时指定：

```bash
make build SIMULATOR_NAME="iPhone 16 Pro"
```

## 推荐工具

### Homebrew

Homebrew 用来安装命令行辅助工具。

检查：

```bash
brew --version
```

### xcbeautify

`xcbeautify` 用来让 `xcodebuild` 输出更容易读。

安装：

```bash
brew install xcbeautify
```

检查：

```bash
which xcbeautify
xcbeautify --version
```

如果没有安装，`make build` 仍会退回原始 `xcodebuild` 输出，只是日志没有那么清爽。

### GitHub CLI

如果你想直接发布到 GitHub，可以安装：

```bash
brew install gh
gh auth login
```

本项目不强制使用 `gh`。你也可以在 GitHub 网页上手动创建仓库后 push。

## 常用命令

```bash
make build
make run
make open
make logs
make test-ui
make clean
```

含义：

| 命令 | 用途 |
|---|---|
| `make build` | 命令行构建，验证工程能编译 |
| `make run` | 构建、安装并启动到 Simulator |
| `make open` | 打开 Xcode 工程 |
| `make logs` | 查看最近一次构建日志尾部 |
| `make test-ui` | 启动 Simulator 并运行 UI Test |
| `make clean` | 清理本项目 `.DerivedData` 和构建日志 |

## 常见问题

### 找不到 Simulator

先列出可用设备：

```bash
xcrun simctl list devices available
```

然后指定一个存在的设备：

```bash
make build SIMULATOR_NAME="你的设备名"
```

### xcodebuild 输出太长

安装 `xcbeautify`：

```bash
brew install xcbeautify
```

### 构建通过但我看不到生命周期

命令行构建只证明项目能编译。生命周期、点击和 Call Stack 必须在 Xcode + Simulator 里观察。

下一步看：[xcode-observation-guide.md](xcode-observation-guide.md)。
