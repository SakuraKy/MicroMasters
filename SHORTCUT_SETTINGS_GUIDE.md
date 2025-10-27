# 快捷键设置功能 - 手动完成步骤

## ✅ 已完成的工作

1. **创建了快捷键设置模型** (`ShortcutSettings.swift`)

   - 位置：`MicroMasters/Domain/Models/ShortcutSettings.swift`
   - 包含快捷键配置、验证逻辑和管理器

2. **创建了设置窗口** (`ShortcutSettingsWindow.swift`)

   - 位置：`MicroMasters/UI/Settings/ShortcutSettingsWindow.swift`
   - 提供图形化界面来自定义快捷键

3. **更新了 StatusBarController**
   - 集成了快捷键管理器
   - 添加了"快捷键设置…"菜单项
   - 支持动态更新快捷键

## ⚠️ 需要手动完成的步骤

由于 Xcode 项目文件的复杂性，需要你手动将新文件添加到项目中：

### 步骤 1：打开 Xcode 项目

```bash
open MicroMasters.xcodeproj
```

### 步骤 2：添加 ShortcutSettings.swift

1. 在 Xcode 左侧项目导航器中，右键点击 `MicroMasters/Domain/Models` 文件夹
2. 选择"Add Files to 'MicroMasters'..."
3. 导航到 `MicroMasters/Domain/Models/ShortcutSettings.swift`
4. 确保勾选"Copy items if needed"和"Add to targets: MicroMasters"
5. 点击"Add"

### 步骤 3：添加 ShortcutSettingsWindow.swift

1. 创建 UI/Settings 文件夹（如果不存在）

   - 右键点击 `MicroMasters/UI` 文件夹
   - 选择"New Group"
   - 命名为"Settings"

2. 添加文件到项目
   - 右键点击刚创建的 `Settings` 文件夹
   - 选择"Add Files to 'MicroMasters'..."
   - 导航到 `MicroMasters/UI/Settings/ShortcutSettingsWindow.swift`
   - 确保勾选"Add to targets: MicroMasters"
   - 点击"Add"

### 步骤 4：构建项目

按 `⌘B` 或选择 Product → Build

### 步骤 5：运行并测试

1. 按 `⌘R` 运行应用
2. 点击菜单栏图标
3. 应该能看到新的"快捷键设置…"菜单项
4. 点击打开设置窗口
5. 尝试修改快捷键并保存

## 📝 功能说明

### 默认快捷键

- **⌘⌃S** - 开始学习
- **⌘⌃,** - 设置单词个数
- **⌘⌃L** - 选择词库
- **⌘⌃I** - 导入词库
- **⌘⌃E** - 导出学习记录
- **⌘⌃T** - 开始随机测试
- **⌘⌃?** - 使用说明

### 设置窗口功能

- 为每个功能自定义单个字符作为快捷键
- 验证输入（必须是单个字符）
- 检测重复的快捷键
- 恢复默认设置按钮
- 实时预览快捷键效果（Cmd + Ctrl + 字符）

### 数据持久化

- 设置自动保存到 UserDefaults
- 应用重启后保留自定义快捷键
- 可随时恢复默认值

## 🎯 下一步

完成上述步骤后，你的应用就有了完整的快捷键自定义功能！

如果遇到编译错误，请检查：

1. 文件是否正确添加到项目 target
2. 文件路径是否正确
3. 是否有语法错误

祝你使用愉快！✨
