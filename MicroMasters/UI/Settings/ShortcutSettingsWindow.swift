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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "快捷键设置"
        window.center()
        
        super.init(window: window)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "自定义快捷键")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(titleLabel)
        
        // 说明
        let descLabel = NSTextField(labelWithString: "请输入单个字符作为快捷键（按 Cmd + 字符触发）")
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(descLabel)
        
        // 分隔线
        let separator1 = NSBox()
        separator1.boxType = .separator
        separator1.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(separator1)
        
        // 快捷键输入项
        addShortcutRow(to: stackView, label: "开始学习:", field: startStudyField, value: settings.startStudy)
        addShortcutRow(to: stackView, label: "设置单词个数:", field: setWordCountField, value: settings.setWordCount)
        addShortcutRow(to: stackView, label: "选择词库:", field: selectDeckField, value: settings.selectDeck)
        addShortcutRow(to: stackView, label: "导入词库:", field: importDeckField, value: settings.importDeck)
        addShortcutRow(to: stackView, label: "导出学习记录:", field: exportRecordsField, value: settings.exportRecords)
        addShortcutRow(to: stackView, label: "开始随机测试:", field: startQuizField, value: settings.startQuiz)
        addShortcutRow(to: stackView, label: "使用说明:", field: showHelpField, value: settings.showHelp)
        
        // 分隔线
        let separator2 = NSBox()
        separator2.boxType = .separator
        separator2.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(separator2)
        
        // 按钮栏
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        
        let resetButton = NSButton(title: "恢复默认", target: self, action: #selector(resetToDefaults))
        resetButton.bezelStyle = .rounded
        
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // ESC
        
        let saveButton = NSButton(title: "保存", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter
        
        buttonStack.addArrangedSubview(resetButton)
        buttonStack.addArrangedSubview(NSView()) // Spacer
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
        
        stackView.addArrangedSubview(buttonStack)
        
        // 约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separator1.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            separator2.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            buttonStack.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
    
    private func addShortcutRow(to stackView: NSStackView, label: String, field: NSTextField, value: String) {
        let rowStack = NSStackView()
        rowStack.orientation = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .centerY
        
        let labelView = NSTextField(labelWithString: label)
        labelView.alignment = .right
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            labelView.widthAnchor.constraint(equalToConstant: 140)
        ])
        
        field.stringValue = value
        field.placeholderString = "单个字符"
        field.maximumNumberOfLines = 1
        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        let hintLabel = NSTextField(labelWithString: "Cmd + \(value)")
        hintLabel.font = NSFont.systemFont(ofSize: 10)
        hintLabel.textColor = .tertiaryLabelColor
        
        rowStack.addArrangedSubview(labelView)
        rowStack.addArrangedSubview(field)
        rowStack.addArrangedSubview(hintLabel)
        rowStack.addArrangedSubview(NSView()) // Spacer
        
        stackView.addArrangedSubview(rowStack)
        
        NSLayoutConstraint.activate([
            rowStack.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
    
    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "恢复默认快捷键"
        alert.informativeText = "确定要恢复所有快捷键为默认设置吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "恢复")
        alert.addButton(withTitle: "取消")
        
        guard let window = window, alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        
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
        
        window.close()
    }
    
    @objc private func cancel() {
        window?.close()
    }
    
    @objc private func save() {
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
        
        // 验证并保存
        do {
            try shortcutManager.save(newSettings)
            window?.close()
        } catch {
            let alert = NSAlert()
            alert.messageText = "保存失败"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}
