//
//  ShortcutSettingsWindow.swift
//  MicroMasters
//
//  Created by AI Assistant
//

import AppKit

/// 快捷键设置窗口
final class ShortcutSettingsWindow: NSWindowController {
    
    private var settings: ShortcutSettings
    private let shortcutManager = ShortcutManager.shared
    
    // 文本框
    private let startStudyField = NSTextField()
    private let setWordCountField = NSTextField()
    private let selectDeckField = NSTextField()
    private let importDeckField = NSTextField()
    private let exportRecordsField = NSTextField()
    private let startQuizField = NSTextField()
    private let showHelpField = NSTextField()
    
    init() {
        self.settings = shortcutManager.current
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "快捷键设置"
        window.center()
        
        super.init(window: window)
        
        NSLog("⌨️ ShortcutSettingsWindow 初始化，当前设置: \(settings)")
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { 
            NSLog("❌ 无法获取 contentView")
            return 
        }
        
        // 主容器
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 20
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "自定义快捷键")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .labelColor
        mainStack.addArrangedSubview(titleLabel)
        
        // 说明
        let descLabel = NSTextField(labelWithString: "请输入单个字符作为快捷键（按 Cmd + Ctrl + 字符触发）")
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor
        mainStack.addArrangedSubview(descLabel)
        
        // 分隔线
        let separator1 = createSeparator()
        mainStack.addArrangedSubview(separator1)
        
        // 快捷键输入项
        let fieldsStack = NSStackView()
        fieldsStack.orientation = .vertical
        fieldsStack.alignment = .leading
        fieldsStack.spacing = 12
        
        fieldsStack.addArrangedSubview(createShortcutRow(label: "开始学习:", field: startStudyField, value: settings.startStudy))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "设置单词个数:", field: setWordCountField, value: settings.setWordCount))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "选择词库:", field: selectDeckField, value: settings.selectDeck))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "导入词库:", field: importDeckField, value: settings.importDeck))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "导出学习记录:", field: exportRecordsField, value: settings.exportRecords))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "开始随机测试:", field: startQuizField, value: settings.startQuiz))
        fieldsStack.addArrangedSubview(createShortcutRow(label: "使用说明:", field: showHelpField, value: settings.showHelp))
        
        mainStack.addArrangedSubview(fieldsStack)
        
        // 分隔线
        let separator2 = createSeparator()
        mainStack.addArrangedSubview(separator2)
        
        // 按钮栏
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .gravityAreas
        
        let resetButton = NSButton(title: "恢复默认", target: self, action: #selector(resetToDefaults))
        resetButton.bezelStyle = .rounded
        resetButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // ESC
        cancelButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let saveButton = NSButton(title: "保存", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter
        saveButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        buttonStack.addArrangedSubview(resetButton)
        buttonStack.addArrangedSubview(spacer)
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
        
        mainStack.addArrangedSubview(buttonStack)
        
        // 约束
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            separator1.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -40),
            separator2.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -40),
            buttonStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -40),
            fieldsStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -40)
        ])
        
        NSLog("✅ ShortcutSettingsWindow UI 设置完成")
    }
    
    private func createSeparator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }
    
    private func createShortcutRow(label: String, field: NSTextField, value: String) -> NSView {
        let rowStack = NSStackView()
        rowStack.orientation = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .centerY
        rowStack.distribution = .gravityAreas
        
        let labelView = NSTextField(labelWithString: label)
        labelView.alignment = .right
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = .labelColor
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelView.widthAnchor.constraint(equalToConstant: 140)
        ])
        
        field.stringValue = value
        field.placeholderString = "单个字符"
        field.maximumNumberOfLines = 1
        field.font = .systemFont(ofSize: 13)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        let hintLabel = NSTextField(labelWithString: "Cmd + Ctrl + \(value)")
        hintLabel.font = NSFont.systemFont(ofSize: 10)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        rowStack.addArrangedSubview(labelView)
        rowStack.addArrangedSubview(field)
        rowStack.addArrangedSubview(hintLabel)
        
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rowStack.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return rowStack
    }
    
    @objc private func resetToDefaults() {
        NSLog("🔄 点击了恢复默认按钮")
        
        let alert = NSAlert()
        alert.messageText = "恢复默认快捷键"
        alert.informativeText = "确定要恢复所有快捷键为默认设置吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "恢复")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        NSLog("🔄 用户选择: \(response == .alertFirstButtonReturn ? "恢复" : "取消")")
        
        guard response == .alertFirstButtonReturn else {
            return
        }
        
        NSLog("🔄 重置快捷键为默认值")
        shortcutManager.reset()
        self.settings = shortcutManager.current
        
        // 更新 UI
        startStudyField.stringValue = settings.startStudy
        setWordCountField.stringValue = settings.setWordCount
        selectDeckField.stringValue = settings.selectDeck
        importDeckField.stringValue = settings.importDeck
        exportRecordsField.stringValue = settings.exportRecords
        startQuizField.stringValue = settings.startQuiz
        showHelpField.stringValue = settings.showHelp
        
        NSLog("✅ 快捷键已重置，窗口即将关闭")
        close()
    }
    
    @objc private func cancel() {
        NSLog("❌ 点击了取消按钮")
        close()
    }
    
    @objc private func save() {
        NSLog("💾 点击了保存按钮")
        
        // 读取输入的快捷键
        let newSettings = ShortcutSettings(
            startStudy: startStudyField.stringValue.trimmingCharacters(in: .whitespaces),
            setWordCount: setWordCountField.stringValue.trimmingCharacters(in: .whitespaces),
            selectDeck: selectDeckField.stringValue.trimmingCharacters(in: .whitespaces),
            importDeck: importDeckField.stringValue.trimmingCharacters(in: .whitespaces),
            exportRecords: exportRecordsField.stringValue.trimmingCharacters(in: .whitespaces),
            startQuiz: startQuizField.stringValue.trimmingCharacters(in: .whitespaces),
            showHelp: showHelpField.stringValue.trimmingCharacters(in: .whitespaces)
        )
        
        NSLog("📝 新快捷键设置:")
        NSLog("  - startStudy: '\(newSettings.startStudy)'")
        NSLog("  - setWordCount: '\(newSettings.setWordCount)'")
        NSLog("  - selectDeck: '\(newSettings.selectDeck)'")
        NSLog("  - importDeck: '\(newSettings.importDeck)'")
        NSLog("  - exportRecords: '\(newSettings.exportRecords)'")
        NSLog("  - startQuiz: '\(newSettings.startQuiz)'")
        NSLog("  - showHelp: '\(newSettings.showHelp)'")
        
        // 验证并保存
        do {
            try shortcutManager.save(newSettings)
            NSLog("✅ 快捷键保存成功!")
            
            // 显示成功提示
            let successAlert = NSAlert()
            successAlert.messageText = "保存成功"
            successAlert.informativeText = "快捷键设置已更新，菜单栏快捷键将立即生效。"
            successAlert.alertStyle = .informational
            successAlert.addButton(withTitle: "确定")
            successAlert.runModal()
            
            NSLog("✅ 关闭设置窗口")
            close()
        } catch {
            NSLog("❌ 保存快捷键失败: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "保存失败"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}
