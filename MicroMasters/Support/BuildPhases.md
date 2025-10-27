# MicroMasters Build Phases

- **Compile Sources**: `AppDelegate.swift`, `StatusBarController.swift`, `StudyManager.swift`, `NotificationManager.swift`, `ExcelIO.swift`, `Models.swift`.
- **Copy Bundle Resources**: `Resources/default_words.csv`, `Assets.xcassets`（包含 `MenuIcon` 图标)。
- **Process Entitlements**: `MicroMasters.entitlements` 赋予最小化沙盒权限。
- **Link Frameworks**: 默认的 AppKit、UserNotifications、Foundation。
- **Embed App Extensions**: 无。

目标在构建后生成无 Dock 图标的菜单栏应用。
