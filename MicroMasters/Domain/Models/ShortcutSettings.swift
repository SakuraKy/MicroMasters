//
//  ShortcutSettings.swift
//  MicroMasters
//
//  Created by AI Assistant
//

import Foundation

/// 快捷键配置
struct ShortcutSettings: Codable {
    var startStudy: String          // 开始学习
    var setWordCount: String         // 设置单词个数
    var selectDeck: String           // 选择词库
    var importDeck: String           // 导入词库
    var exportRecords: String        // 导出学习记录
    var startQuiz: String            // 开始随机测试
    var showHelp: String             // 使用说明
    
    static let `default` = ShortcutSettings(
        startStudy: "s",
        setWordCount: ",",
        selectDeck: "l",
        importDeck: "i",
        exportRecords: "e",
        startQuiz: "t",
        showHelp: "?"
    )
    
    /// 验证快捷键是否有效（单个字符）
    func isValid() -> Bool {
        let shortcuts = [startStudy, setWordCount, selectDeck, importDeck, exportRecords, startQuiz, showHelp]
        return shortcuts.allSatisfy { $0.count == 1 }
    }
    
    /// 检查是否有重复的快捷键
    func hasDuplicates() -> Bool {
        let shortcuts = [startStudy, setWordCount, selectDeck, importDeck, exportRecords, startQuiz, showHelp]
        let uniqueShortcuts = Set(shortcuts)
        return shortcuts.count != uniqueShortcuts.count
    }
}

/// 快捷键管理器
final class ShortcutManager {
    static let shared = ShortcutManager()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ShortcutSettings"
    
    private(set) var current: ShortcutSettings
    
    private init() {
        // 加载保存的设置，如果没有则使用默认值
        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(ShortcutSettings.self, from: data) {
            self.current = settings
        } else {
            self.current = .default
        }
    }
    
    /// 保存快捷键设置
    func save(_ settings: ShortcutSettings) throws {
        guard settings.isValid() else {
            throw ShortcutError.invalidShortcut
        }
        
        guard !settings.hasDuplicates() else {
            throw ShortcutError.duplicateShortcut
        }
        
        let data = try JSONEncoder().encode(settings)
        userDefaults.set(data, forKey: settingsKey)
        self.current = settings
        
        // 发送通知，让 UI 更新快捷键
        NotificationCenter.default.post(name: .shortcutSettingsChanged, object: settings)
    }
    
    /// 重置为默认快捷键
    func reset() {
        try? save(.default)
    }
}

/// 快捷键错误
enum ShortcutError: LocalizedError {
    case invalidShortcut
    case duplicateShortcut
    
    var errorDescription: String? {
        switch self {
        case .invalidShortcut:
            return "快捷键必须是单个字符"
        case .duplicateShortcut:
            return "存在重复的快捷键"
        }
    }
}

/// 快捷键设置变更通知
extension Notification.Name {
    static let shortcutSettingsChanged = Notification.Name("ShortcutSettingsChanged")
}
