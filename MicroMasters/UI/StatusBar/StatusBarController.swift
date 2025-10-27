//
//  StatusBarController.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let studyManager: StudyManager
    private let notificationManager: NotificationManager
    private let shortcutManager = ShortcutManager.shared
    
    // 菜单项引用，用于动态更新快捷键
    private var startItem: NSMenuItem?
    private var configItem: NSMenuItem?
    private var selectDeckItem: NSMenuItem?
    private var importItem: NSMenuItem?
    private var exportItem: NSMenuItem?
    private var quizStartItem: NSMenuItem?
    private var helpItem: NSMenuItem?
    
    // MARK: - System Appearance Tracking
    private var appearanceObserver: NSObjectProtocol?
    private var shortcutObserver: NSObjectProtocol?
    
    init(statusItem: NSStatusItem, studyManager: StudyManager, notificationManager: NotificationManager) {
        self.statusItem = statusItem
        self.studyManager = studyManager
        self.notificationManager = notificationManager
        super.init()
        configureStatusItem()
        setupAppearanceObserver()
        setupShortcutObserver()
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = shortcutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// 监听快捷键设置变化
    private func setupShortcutObserver() {
        shortcutObserver = NotificationCenter.default.addObserver(
            forName: .shortcutSettingsChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            NSLog("⌨️ 快捷键设置已变更，重新构建菜单")
            self?.configureStatusItem()
        }
    }
    
    /// 监听系统外观变化（深色模式、强调色等）
    private func setupAppearanceObserver() {
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            NSLog("🎨 系统外观发生变化，自动适配...")
            self?.updateForCurrentAppearance()
        }
        
        // 监听系统外观模式变化
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    @objc private func systemAppearanceChanged() {
        NSLog("🎨 系统主题变化（深色/浅色模式）")
        updateForCurrentAppearance()
    }
    
    /// 根据当前系统外观更新 UI
    private func updateForCurrentAppearance() {
        // 使用系统当前外观
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            NSLog("🎨 当前系统外观: \(appearance == .darkAqua ? "深色模式" : "浅色模式")")
        }
        
        // 刷新状态栏图标（自动适配深色/浅色模式）
        configureStatusItem()
    }

    private func configureStatusItem() {
        NSLog("MicroMasters: 🔧 开始配置状态栏...")
        
        statusItem.isVisible = true
        statusItem.length = NSStatusItem.variableLength
        
        guard let button = statusItem.button else {
            NSLog("MicroMasters: ❌ 无法获取状态栏按钮!")
            return
        }
        
        NSLog("MicroMasters: ✅ 成功获取状态栏按钮")
        
        // 清空标题，只显示图标
        button.title = ""
        button.imagePosition = .imageOnly
        
        // 使用 SF Symbols 系统图标作为菜单栏图标
        if #available(macOS 11.0, *) {
            if let image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: "MicroMasters") {
                image.isTemplate = true
                button.image = image
                button.imageScaling = .scaleProportionallyDown
                NSLog("MicroMasters: ✅ 使用 SF Symbols 图标")
            } else {
                button.title = "MM"
                NSLog("MicroMasters: ⚠️ 使用文本显示")
            }
        } else {
            // macOS 10.x 备选方案
            button.title = "MM"
            NSLog("MicroMasters: ℹ️ macOS 版本较旧，使用文本显示")
        }
        
        button.toolTip = "MicroMasters - 单词记忆助手"
        statusItem.menu = buildMenu()
        
        NSLog("MicroMasters: ✅ 状态栏配置完成")
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        
        // 使用系统原生菜单样式（自动适配系统设置）
        menu.autoenablesItems = true
        menu.allowsContextMenuPlugIns = true
        
        let shortcuts = shortcutManager.current
        
        // 根据 macOS 版本使用适当的 SF Symbols（仅 macOS 11+）
        startItem = NSMenuItem(title: "开始学习",
                                   action: #selector(handleStartStudy),
                                   keyEquivalent: shortcuts.startStudy)
        startItem?.target = self
        
        // macOS 11+ 支持 SF Symbols
        if #available(macOS 11.0, *) {
            startItem?.image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "开始")
        }
        menu.addItem(startItem!)
        
        configItem = NSMenuItem(title: "设置单词个数…",
                                    action: #selector(handleConfigureWordCount),
                                    keyEquivalent: shortcuts.setWordCount)
        configItem?.target = self
        
        if #available(macOS 11.0, *) {
            configItem?.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "设置")
        }
        menu.addItem(configItem!)
        
        // 添加选择词库菜单项
        selectDeckItem = NSMenuItem(title: "选择词库…",
                                        action: #selector(handleSelectDeck),
                                        keyEquivalent: shortcuts.selectDeck)
        selectDeckItem?.target = self
        
        if #available(macOS 11.0, *) {
            selectDeckItem?.image = NSImage(systemSymbolName: "books.vertical.fill", accessibilityDescription: "词库")
        }
        menu.addItem(selectDeckItem!)

        menu.addItem(NSMenuItem.separator())

        // 英语词汇子菜单
        let vocabularyMenu = NSMenu(title: "英语词汇")
        
        importItem = NSMenuItem(title: "导入词库…",
                                    action: #selector(handleImportDeck),
                                    keyEquivalent: shortcuts.importDeck)
        importItem?.target = self
        
        if #available(macOS 11.0, *) {
            importItem?.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "导入")
        }
        vocabularyMenu.addItem(importItem!)
        
        exportItem = NSMenuItem(title: "导出学习记录…",
                                    action: #selector(handleExportRecords),
                                    keyEquivalent: shortcuts.exportRecords)
        exportItem?.target = self
        
        if #available(macOS 11.0, *) {
            exportItem?.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "导出")
        }
        vocabularyMenu.addItem(exportItem!)
        
        let vocabularyItem = NSMenuItem(title: "英语词汇", action: nil, keyEquivalent: "")
        
        if #available(macOS 11.0, *) {
            vocabularyItem.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "词汇")
        }
        vocabularyItem.submenu = vocabularyMenu
        menu.addItem(vocabularyItem)

        // 随机测试子菜单
        let quizMenu = NSMenu(title: "随机测试")
        
        quizStartItem = NSMenuItem(title: "开始随机测试",
                                       action: #selector(handleStandaloneQuiz),
                                       keyEquivalent: shortcuts.startQuiz)
        quizStartItem?.target = self
        
        if #available(macOS 11.0, *) {
            quizStartItem?.image = NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "测试")
        }
        quizMenu.addItem(quizStartItem!)
        
        let quizItem = NSMenuItem(title: "随机测试", action: nil, keyEquivalent: "")
        
        if #available(macOS 11.0, *) {
            quizItem.image = NSImage(systemSymbolName: "checkmark.seal.fill", accessibilityDescription: "测试")
        }
        quizItem.submenu = quizMenu
        menu.addItem(quizItem)

        menu.addItem(NSMenuItem.separator())

        helpItem = NSMenuItem(title: "使用说明",
                                  action: #selector(handleShowHelp),
                                  keyEquivalent: shortcuts.showHelp)
        helpItem?.target = self
        
        if #available(macOS 11.0, *) {
            helpItem?.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "帮助")
        }
        menu.addItem(helpItem!)
        
        // 添加快捷键设置菜单项
        let shortcutSettingsItem = NSMenuItem(title: "快捷键设置…",
                                              action: #selector(handleShortcutSettings),
                                              keyEquivalent: "")
        shortcutSettingsItem.target = self
        
        if #available(macOS 11.0, *) {
            shortcutSettingsItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "快捷键")
        }
        menu.addItem(shortcutSettingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 MicroMasters",
                                  action: #selector(handleQuit),
                                  keyEquivalent: "q")
        quitItem.target = self
        quitItem.keyEquivalentModifierMask = .command
        
        if #available(macOS 11.0, *) {
            quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "退出")
        }
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func handleStartStudy() {
        let config = studyManager.currentSessionConfig()
        NSLog("🎯 开始背单词 - 当前设置数量: \(config.wordCount)")
        let words = studyManager.randomWordsForStudySession()
        NSLog("📚 实际获取单词数量: \(words.count)")
        notificationManager.startStudySession(with: words)
    }

    @objc private func handleConfigureWordCount() {
        let current = studyManager.currentSessionConfig().wordCount
        NSLog("💬 打开设置对话框 - 当前值: \(current)")
        
        // 使用系统原生 NSAlert 样式
        let alert = createSystemAlert(
            title: "设置本次背诵数量",
            message: "选择 10 至 100 之间的数量"
        )
        
        let accessory = WordCountAccessoryView(defaultValue: current)
        alert.accessoryView = accessory
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let selected = accessory.currentValue
            NSLog("✅ 用户确认新数量: \(selected)")
            studyManager.updateWordCount(to: selected)
            
            // 验证保存是否成功
            let saved = studyManager.currentSessionConfig().wordCount
            NSLog("💾 保存后验证: \(saved)")
        } else {
            NSLog("❌ 用户取消设置")
        }
    }

    @objc private func handleImportDeck() {
        NSLog("📂 用户点击了导入词库")
        
        let panel = NSOpenPanel()
        panel.title = "导入词库"
        panel.allowedFileTypes = ["csv", "txt", "xlsx"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        NSLog("📂 准备显示文件选择对话框...")

        panel.begin { [weak self] result in
            NSLog("📂 文件选择对话框结果: \(result == .OK ? "OK" : "Cancel")")
            guard result == .OK, let url = panel.url else {
                NSLog("📂 用户取消或未选择文件")
                return
            }
            
            NSLog("📂 用户选择了文件: \(url.path)")
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    NSLog("📂 开始导入词库...")
                    try self?.studyManager.importDeck(from: url)
                    NSLog("📂 词库导入成功!")
                    
                    DispatchQueue.main.async {
                        self?.presentSystemAlert(
                            title: "导入成功",
                            message: "新词库已导入。\n请在菜单中选择要使用的词库。"
                        )
                    }
                } catch {
                    NSLog("📂 词库导入失败: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        self?.presentSystemAlert(
                            title: "导入失败",
                            message: error.localizedDescription,
                            style: .critical
                        )
                    }
                }
            }
        }
    }

    @objc private func handleExportRecords() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.studyManager.exportRecordsToTemplate()
                DispatchQueue.main.async {
                    // 获取模板文件路径
                    let templatePath = PersistencePaths.exportTemplateURL
                        .deletingPathExtension()
                        .appendingPathExtension("xlsx")
                        .path
                    
                    self?.presentSystemAlert(
                        title: "导出成功",
                        message: "学习记录已自动追加到 Excel 文件:\n\(templatePath)\n\n可直接用 Excel 打开查看完整数据"
                    )
                    
                    // 在 Finder 中显示文件
                    NSWorkspace.shared.activateFileViewerSelecting([templatePath].compactMap { URL(fileURLWithPath: $0) })
                }
            } catch {
                DispatchQueue.main.async {
                    self?.presentSystemAlert(
                        title: "导出失败",
                        message: error.localizedDescription,
                        style: .critical
                    )
                }
            }
        }
    }

    @objc private func handleSelectDeck() {
        let availableDecks = studyManager.listAvailableDecks()
        let currentDeck = studyManager.currentDeckName()
        
        let alert = createSystemAlert(
            title: "选择词库",
            message: "请选择要使用的词库"
        )
        
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        // 创建下拉菜单（使用系统原生 NSPopUpButton）
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        popup.removeAllItems()
        
        for deck in availableDecks {
            popup.addItem(withTitle: deck)
        }
        
        // 选中当前词库
        if let index = availableDecks.firstIndex(of: currentDeck) {
            popup.selectItem(at: index)
        }
        
        alert.accessoryView = popup
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let selectedDeck = popup.titleOfSelectedItem ?? availableDecks[0]
            do {
                try studyManager.switchToDeck(named: selectedDeck)
                presentSystemAlert(title: "切换成功", message: "已切换到词库: \(selectedDeck)")
            } catch {
                presentSystemAlert(title: "切换失败", message: error.localizedDescription, style: .critical)
            }
        }
    }

    @objc private func handleStandaloneQuiz() {
        // 获取已学习的单词(去重后的唯一单词)
        let learnedWords = studyManager.getLearnedWords()
        
        guard !learnedWords.isEmpty else {
            presentSystemAlert(
                title: "没有学习记录",
                message: "请先学习一些单词后再进行测试。",
                style: .informational
            )
            return
        }
        
        // 获取导出的 Excel 记录数（行数 - 表头，包含重复记录）
        let exportedCount = studyManager.getExportedRecordCount()
        
        // 使用已学习的唯一单词数作为最大值
        let maxAvailable = learnedWords.count
        
        // 创建选择测试数量的对话框
        let message: String
        if exportedCount > 0 {
            message = "已学习 \(learnedWords.count) 个不同单词（Excel中共有 \(exportedCount) 条学习记录）\n从中抽取多少个进行测试？"
        } else {
            message = "从已学习的 \(learnedWords.count) 个单词中抽取多少个进行测试？"
        }
        
        let alert = createSystemAlert(
            title: "随机测试",
            message: message
        )
        
        // 创建自定义视图
        let accessoryView = TestCountAccessoryView(
            maxCount: maxAvailable,
            currentValue: min(maxAvailable, 10)
        )
        alert.accessoryView = accessoryView
        
        alert.addButton(withTitle: "开始测试")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        let testCount = accessoryView.currentValue
        NSLog("🎯 随机测试 - 从 \(learnedWords.count) 个已学单词中抽取 \(testCount) 个")
        
        // 随机抽取指定数量的单词
        let shuffled = learnedWords.shuffled()
        let testWords = Array(shuffled.prefix(testCount))
        
        // 开始测试
        notificationManager.startQuizSession(with: testWords)
    }

        @objc private func handleShowHelp() {
        let alert = createSystemAlert(
            title: "使用说明",
            message: """
            欢迎使用 MicroMasters 单词记忆助手！
            
            📚 学习功能：
            • 点击"开始学习"启动本次背诵
            • 系统会推送通知帮助你完成记忆
            • 可在"设置"中调整每轮背诵数量
            
            📖 词库管理：
            • "选择词库"切换不同词库
            • "导入词库"添加自定义词库
            • "导出学习记录"保存学习进度
            
            🎯 随机测试：
            • 完成学习后可进行随机测验
            • 从已学单词中抽取题目
            • 检验学习效果
            
            ⌨️ 快捷键：
            • ⌘S - 开始学习
            • ⌘, - 设置
            • ⌘L - 选择词库
            • ⌘T - 随机测试
            """
        )
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }
    
    @objc private func handleShortcutSettings() {
        NSLog("⌨️ 打开快捷键设置窗口")
        let settingsWindow = ShortcutSettingsWindow()
        settingsWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - System Alert Helpers
    
    /// 创建符合系统规范的 NSAlert
    private func createSystemAlert(title: String, message: String, style: NSAlert.Style = .informational) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        
        // 优先使用自定义图标，如果没有则使用系统图标
        var customIcon: NSImage?
        
        switch style {
        case .informational:
            // 尝试加载自定义信息图标
            if let icon = NSImage(named: "CustomInfoIcon") {
                // 设置图标大小以适配对话框
                icon.size = NSSize(width: 64, height: 64)
                customIcon = icon
            } else if #available(macOS 11.0, *) {
                // 如果没有自定义图标，使用系统图标
                customIcon = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: "信息")
            }
            
        case .warning:
            // 尝试加载自定义警告图标
            if let icon = NSImage(named: "CustomWarningIcon") {
                icon.size = NSSize(width: 64, height: 64)
                customIcon = icon
            } else if #available(macOS 11.0, *) {
                // 如果没有自定义图标，使用系统图标
                customIcon = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "警告")
            }
            
        case .critical:
            // 尝试加载自定义错误图标
            if let icon = NSImage(named: "CustomErrorIcon") {
                icon.size = NSSize(width: 64, height: 64)
                customIcon = icon
            } else if #available(macOS 11.0, *) {
                // 如果没有自定义图标，使用系统图标
                customIcon = NSImage(systemSymbolName: "xmark.octagon.fill", accessibilityDescription: "错误")
            }
            
        @unknown default:
            break
        }
        
        // 设置图标
        if let icon = customIcon {
            alert.icon = icon
        }
        
        return alert
    }
    
    /// 展示系统样式的警告对话框
    private func presentSystemAlert(title: String, message: String, style: NSAlert.Style = .informational) {
        let alert = createSystemAlert(title: title, message: message, style: style)
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @available(*, deprecated, message: "使用 presentSystemAlert 替代")
    private func presentAlert(message: String, info: String) {
        presentSystemAlert(title: message, message: info)
    }
}

// MARK: - Word Count Accessory

private final class WordCountAccessoryView: NSView {
    private let slider: NSSlider
    private let textField: NSTextField
    private let minLabel: NSTextField
    private let maxLabel: NSTextField
    private let minimum = 10
    private let maximum = 100
    private let step = 5

    var currentValue: Int {
        get {
            let sliderValue = slider.adjustedValue(step: step, minimum: minimum, maximum: maximum)
            return sliderValue
        }
        set {
            let adjusted = max(minimum, min(maximum, newValue))
            slider.doubleValue = Double(adjusted)
            textField.stringValue = "\(adjusted)"
        }
    }

    init(defaultValue: Int) {
        let adjusted = max(minimum, min(maximum, defaultValue))
        
        // 使用系统原生滑条样式（自动适配系统外观）
        slider = NSSlider(value: Double(adjusted),
                          minValue: Double(minimum),
                          maxValue: Double(maximum),
                          target: nil,
                          action: nil)
        slider.sliderType = .linear
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        
        // 使用系统默认滑块样式（自动适配深色模式和系统强调色）
        slider.controlSize = .regular
        
        // 创建标签（使用系统字体和颜色）
        minLabel = NSTextField(labelWithString: "\(minimum)")
        minLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        minLabel.textColor = .secondaryLabelColor
        minLabel.alignment = .right
        
        maxLabel = NSTextField(labelWithString: "\(maximum)")
        maxLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        maxLabel.textColor = .secondaryLabelColor
        maxLabel.alignment = .left
        
        // 创建数值显示文本框（只读，使用系统样式）
        textField = NSTextField(labelWithString: "\(adjusted)")
        textField.font = .systemFont(ofSize: 24, weight: .medium)
        textField.alignment = .center
        textField.textColor = .labelColor
        
        super.init(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        setupLayout(adjustedValue: adjusted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout(adjustedValue: Int) {
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        
        addSubview(minLabel)
        addSubview(slider)
        addSubview(maxLabel)
        addSubview(textField)
        
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 数值显示在顶部
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textField.widthAnchor.constraint(equalToConstant: 80),
            
            // 滑条在中间
            slider.centerXAnchor.constraint(equalTo: centerXAnchor),
            slider.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 15),
            slider.widthAnchor.constraint(equalToConstant: 280),
            
            // 最小值标签
            minLabel.trailingAnchor.constraint(equalTo: slider.leadingAnchor, constant: -8),
            minLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            minLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // 最大值标签
            maxLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 8),
            maxLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            maxLabel.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        slider.doubleValue = Double(adjustedValue)
        textField.stringValue = "\(adjustedValue)"
        
        NSLog("📏 WordCountAccessoryView: 使用系统原生样式")
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let rawValue = Int(round(sender.doubleValue))
        let offset = rawValue - minimum
        let stepped = (offset / step) * step + minimum
        let newValue = max(minimum, min(maximum, stepped))
        
        sender.doubleValue = Double(newValue)
        textField.stringValue = "\(newValue)"
    }
}

private extension NSSlider {
    func adjustedValue(step: Int, minimum: Int, maximum: Int) -> Int {
        let raw = Int(round(doubleValue))
        let clamped = Swift.max(minimum, Swift.min(maximum, raw))
        let offset = clamped - minimum
        let stepped = (offset / step) * step + minimum
        return stepped
    }
}

// MARK: - Test Count Accessory

private final class TestCountAccessoryView: NSView {
    private let slider: NSSlider
    private let textField: NSTextField
    private let minLabel: NSTextField
    private let maxLabel: NSTextField
    private let minimum: Int
    private let maximum: Int
    private let step = 5

    var currentValue: Int {
        get {
            return Int(slider.intValue)
        }
        set {
            slider.intValue = Int32(newValue)
            textField.stringValue = "\(newValue)"
        }
    }

    init(maxCount: Int, currentValue: Int) {
        self.minimum = 5
        self.maximum = max(5, maxCount)
        
        // 使用系统原生滑条样式（自动适配系统外观）
        slider = NSSlider(value: Double(currentValue), minValue: Double(minimum), maxValue: Double(maximum), target: nil, action: nil)
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        slider.isContinuous = true
        slider.controlSize = .regular
        
        // 使用系统标签（自动适配系统字体和颜色）
        textField = NSTextField(labelWithString: "\(currentValue)")
        textField.alignment = .center
        textField.font = .systemFont(ofSize: 24, weight: .medium)
        textField.textColor = .labelColor
        
        minLabel = NSTextField(labelWithString: "\(minimum)")
        minLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        minLabel.textColor = .secondaryLabelColor
        
        maxLabel = NSTextField(labelWithString: "\(maximum)")
        maxLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        maxLabel.textColor = .secondaryLabelColor
        
        super.init(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubview(slider)
        addSubview(textField)
        addSubview(minLabel)
        addSubview(maxLabel)
        
        slider.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 数值显示在顶部
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textField.widthAnchor.constraint(equalToConstant: 80),
            
            // 滑条在中间
            slider.centerXAnchor.constraint(equalTo: centerXAnchor),
            slider.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 15),
            slider.widthAnchor.constraint(equalToConstant: 280),
            
            // 最小值标签
            minLabel.trailingAnchor.constraint(equalTo: slider.leadingAnchor, constant: -8),
            minLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            minLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // 最大值标签
            maxLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 8),
            maxLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            maxLabel.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupActions() {
        slider.target = self
        slider.action = #selector(sliderChanged)
    }
    
    @objc private func sliderChanged() {
        let rawValue = Int(round(slider.doubleValue))
        let steppedValue = ((rawValue - minimum + step / 2) / step) * step + minimum
        let clampedValue = max(minimum, min(maximum, steppedValue))
        
        slider.intValue = Int32(clampedValue)
        textField.stringValue = "\(clampedValue)"
    }
}
