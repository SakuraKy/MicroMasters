# MicroMasters

MicroMasters 是一个基于 AppKit 的 macOS 菜单栏背单词应用，支持词库导入、学习通知与随机测验。

## ✨ 特性

- 📚 **词库管理**：支持 CSV 格式词库导入，内置默认词库
- 🔔 **学习提醒**：通过系统通知推送单词学习
- 📝 **随机测验**：三选一测验模式，强化记忆
- 🎯 **学习记录**：自动记录学习进度和正确率
- 🔊 **发音功能**：集成系统语音引擎
- 🎨 **原生 UI**：采用 macOS 原生设计风格
- ⚙️ **菜单栏常驻**：轻量级菜单栏应用，不占用 Dock

## 🚀 快速开始

### 环境要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- Swift 5

### 构建步骤

1. 克隆项目到本地：
```bash
git clone https://github.com/yourusername/MicroMasters.git
cd MicroMasters
```

2. 打开 Xcode 项目：
```bash
open MicroMasters.xcodeproj
```

3. 选择 `MicroMasters` scheme，然后构建运行（⌘R）

首次运行会请求通知权限，并将默认词库复制到 `~/Library/Application Support/MicroMasters`。

## 📖 使用说明

### 菜单栏功能

- **开始！**：按照配置数量推送学习通知
- **设置单词个数…**：配置每轮学习数量（10-100，步长 5）
- **选择词库**：切换不同的词库
- **导入词库…**：导入 CSV 格式词库（格式：term,phonetic,pos,meaning,example）
- **导出学习记录…**：导出学习记录为 CSV 格式
- **随机测试**：开始三选一测验，无需学习流程
- **使用说明**：查看操作提示
- **退出**：退出应用

### 词库格式

CSV 文件格式（UTF-8 编码）：
```csv
term,phonetic,pos,meaning,example
abandon,/əˈbændən/,v.,放弃；抛弃,They had to abandon the car.
```

### 数据存储

所有数据存储在：`~/Library/Application Support/MicroMasters/`
- `ReviewRecord.json` - 学习记录
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
- **数据持久化**：JSON 本地存储
- **图标**：SF Symbols + 自定义 Assets

## 📄 开源协议

本项目采用 MIT 协议开源，详见 LICENSE 文件。

---

**MicroMasters** - 轻量级单词学习助手，让背单词更简单 ✨
