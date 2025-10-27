<div align="center">

<img src="assets/app-icon.png" width="200" alt="MicroMasters 图标"/>

# MicroMasters

轻量级 macOS 菜单栏背单词应用

</div>

---

## 特性

- **简单易用**：专为轻松背单词设计。只需启动应用即可开始学习。
- **功能完善**：支持 CSV 词库导入、系统通知、随机测验和学习记录。
- **原生 UI**：基于 AppKit 构建，采用 macOS 原生设计风格。
- **菜单栏常驻**：轻量级菜单栏应用，不占用 Dock 空间。
- **发音支持**：集成系统语音引擎，支持单词发音。
- **学习记录**：自动追踪您的学习进度和正确率。
- **快捷键自定义**：支持自定义所有功能的快捷键（Cmd+Ctrl+字符）。

## 🚀 快速开始

### 安装使用

从 [Releases](https://github.com/SakuraKy/MicroMasters/releases) 页面下载最新版本的 DMG 文件，双击安装即可。

### macOS 安装可能遇到的问题

你在 macOS 上安装的时候可能会遇到 **"MicroMasters.app" 已损坏，无法打开。你应该将它移到废纸篓。** 的问题，一般情况下这并非文件损坏。事实上，如果要完全避免这个问题，我们需要每年向苹果支付 99 美元以生成可信任的证书。我们并没有能力支付这些金额。如果你要使用此软件，可能需要一些额外的操作去完成这件事情。

1. 下载并拖动到 Application 目录。
2. 打开你的终端，然后运行：

```bash
xattr -d com.apple.quarantine /Applications/MicroMasters.app
```

3. 打开应用程序并开始使用。

### 从源码构建

#### 环境要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- Swift 5

#### 构建步骤

1. 克隆项目到本地：

```bash
git clone https://github.com/SakuraKy/MicroMasters.git
cd MicroMasters
```

2. 打开 Xcode 项目：

```bash
open MicroMasters.xcodeproj
```

3. 选择 `MicroMasters` scheme，然后构建运行（⌘R）

首次运行会请求通知权限，并将默认词库复制到 `~/Library/Application Support/MicroMasters`。

## �� 使用说明

### 菜单栏功能

- **开始学习**：按照配置数量推送学习通知（快捷键：⌘⌃S）
- **设置单词个数…**：配置每轮学习数量（10-100，步长 5）（快捷键：⌘⌃,）
- **选择词库…**：切换不同的词库（快捷键：⌘⌃L）
- **导入词库…**：导入 CSV 格式词库（格式：term,phonetic,pos,meaning,example）（快捷键：⌘⌃I）
- **导出学习记录…**：导出学习记录为 Excel 格式（快捷键：⌘⌃E）
- **开始随机测试**：开始三选一测验，可选择测试单词数量（快捷键：⌘⌃T）
- **使用说明**：查看操作提示（快捷键：⌘⌃?）
- **快捷键设置…**：自定义所有功能的快捷键
- **退出**：退出应用（快捷键：⌘Q）

### 词库格式

CSV 文件格式（UTF-8 编码）：

```csv
term,phonetic,pos,meaning,example
abandon,/əˈbændən/,v.,放弃；抛弃,They had to abandon the car.
```

### 数据存储

所有数据存储在：`~/Library/Application Support/MicroMasters/`

- `ReviewRecord.json` - 学习记录
- `学习记录_YYYYMMDD_HHMMSS.xlsx` - 导出的 Excel 学习记录
- `default_words.csv` - 默认词库
- 其他导入的词库文件

## 🛠️ 开发脚本

项目包含以下实用脚本（位于 `Scripts/` 目录）：

- **build.sh** - 完整的构建和打包脚本，生成 DMG 文件
- **generate_app_icon.sh** - 从 PNG 图标生成所有尺寸的 app 图标
- **rebuild.sh** - 快速清理并重新构建应用

使用方法：

```bash
cd Scripts
./build.sh     # 构建完整的 Release 版本并打包 DMG
./rebuild.sh   # 快速重新构建 Debug 版本
```

## 💻 技术栈

- **语言**：Swift 5
- **框架**：AppKit（原生 macOS）
- **最低系统**：macOS 12.0+
- **UI 设计**：原生系统组件（NSAlert, NSWindow, NSMenu）
- **数据持久化**：JSON 本地存储 + Excel 导出
- **图标**：SF Symbols + 自定义 Assets
- **通知系统**：UserNotifications 框架

## 📄 开源协议

本项目采用 MIT 协议开源，详见 LICENSE 文件。

---

<div align="center">

**MicroMasters** - 轻量级单词学习助手，让背单词更简单 ✨

</div>
