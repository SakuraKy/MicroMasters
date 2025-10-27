//
//  StudyManager.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import Foundation

final class StudyManager {
    private let storageQueue = DispatchQueue(label: "com.micromasters.studymanager.queue")
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder = JSONDecoder()
    private let excelIO = ExcelIO()
    private var deck: Deck
    private var reviewRecords: [ReviewRecord]
    private var sessionConfig: SessionConfig
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        do {
            try fileManager.createDirectory(at: PersistencePaths.applicationSupportDirectory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            // 创建词库目录
            try fileManager.createDirectory(at: PersistencePaths.decksDirectory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            NSLog("创建目录失败: \(error)")
        }

        deck = Deck()
        reviewRecords = []
        sessionConfig = SessionConfig()

        storageQueue.sync {
            self.deck = (try? self.loadDeck()) ?? Deck()
            self.reviewRecords = (try? self.loadReviewRecords()) ?? []
            self.sessionConfig = (try? self.loadSessionConfig()) ?? SessionConfig()
        }

        ensureDefaultDeckIfNeeded()
    }

    // MARK: - Public accessors

    func currentSessionConfig() -> SessionConfig {
        storageQueue.sync { sessionConfig }
    }

    func updateWordCount(to newValue: Int) {
        storageQueue.sync {
            sessionConfig.wordCount = newValue
            do {
                try saveSessionConfig()
            } catch {
                NSLog("保存 SessionConfig 失败: \(error)")
            }
        }
    }

    func randomWordsForStudySession() -> [Word] {
        storageQueue.sync {
            guard !deck.words.isEmpty else { return [] }
            
            // 获取已学习过的单词(去重)
            let learnedTerms = Set(reviewRecords.map { $0.term })
            
            // 过滤出未学习的单词
            let unlearnedWords = deck.words.filter { !learnedTerms.contains($0.term) }
            
            // 如果还有未学习的单词,优先从中选择
            let candidateWords: [Word]
            if !unlearnedWords.isEmpty {
                candidateWords = unlearnedWords
                NSLog("📚 优先从 \(unlearnedWords.count) 个未学习的单词中选择")
            } else {
                // 如果所有单词都学过了,则从全部单词中选择
                candidateWords = deck.words
                NSLog("📚 所有单词都已学习,从全部 \(deck.words.count) 个单词中选择")
            }
            
            let count = min(max(sessionConfig.wordCount, 1), candidateWords.count)
            return Array(candidateWords.shuffled().prefix(count))
        }
    }

    func randomQuizQuestion(sourceWords: [Word]? = nil) -> (prompt: Word, options: [Word])? {
        storageQueue.sync {
            let baseWords: [Word]
            if let provided = sourceWords, !provided.isEmpty {
                baseWords = provided
            } else {
                baseWords = deck.words
            }
            guard !baseWords.isEmpty else { return nil }
            let prompt = baseWords.randomElement()!
            let distractors = randomDistractors(excluding: prompt, count: 2, within: deck.words)
            let options = ([prompt] + distractors).shuffled()
            return (prompt, options)
        }
    }

    func recordResult(for word: Word, correct: Bool) {
        storageQueue.sync {
            let record = ReviewRecord(
                term: word.term,
                meaning: word.meaning,
                partOfSpeech: word.partOfSpeech,
                correct: correct,
                timestamp: Date()
            )
            reviewRecords.append(record)
            do {
                try saveReviewRecords()
            } catch {
                NSLog("保存 ReviewRecord 失败: \(error)")
            }
        }
    }

    func importDeck(from url: URL) throws {
        let newDeck = try excelIO.importDeck(from: url)
        guard !newDeck.words.isEmpty else {
            throw NSError(domain: "MicroMasters.StudyManager",
                          code: -20,
                          userInfo: [NSLocalizedDescriptionKey: "导入的词库为空"])
        }

        try storageQueue.sync {
            // 提取文件名作为词库名称
            let fileName = url.deletingPathExtension().lastPathComponent
            let deckURL = PersistencePaths.decksDirectory.appendingPathComponent("\(fileName).json")
            
            // 保存到 Decks 目录
            let data = try encoder.encode(newDeck)
            try data.write(to: deckURL, options: .atomic)
            
            NSLog("📥 导入词库成功: \(fileName), 共 \(newDeck.words.count) 个单词")
        }
    }

    func exportRecords(to url: URL) throws {
        let recordsCopy = storageQueue.sync { reviewRecords }
        try excelIO.exportRecords(recordsCopy, to: url)
    }
    
    /// 导出学习记录到模板文件(累积追加) - 已去重
    func exportRecordsToTemplate() throws {
        let recordsCopy = storageQueue.sync { reviewRecords }
        guard !recordsCopy.isEmpty else {
            throw NSError(domain: "MicroMasters.StudyManager",
                          code: -40,
                          userInfo: [NSLocalizedDescriptionKey: "没有学习记录可导出"])
        }
        
        // 去重：对于同一个单词，保留最新的学习记录
        var uniqueRecords: [String: ReviewRecord] = [:]
        for record in recordsCopy {
            if let existing = uniqueRecords[record.term] {
                // 比较时间戳，保留更新的记录
                if record.timestamp > existing.timestamp {
                    uniqueRecords[record.term] = record
                }
            } else {
                uniqueRecords[record.term] = record
            }
        }
        
        let deduplicatedRecords = Array(uniqueRecords.values)
        NSLog("📤 导出学习记录: 原始 \(recordsCopy.count) 条, 去重后 \(deduplicatedRecords.count) 条")
        
        try excelIO.exportRecordsToTemplate(deduplicatedRecords)
    }

    func allWords() -> [Word] {
        storageQueue.sync { deck.words }
    }
    
    /// 获取已学习的单词列表（去重）
    func getLearnedWords() -> [Word] {
        return storageQueue.sync {
            // 从 reviewRecords 中提取唯一的单词
            let uniqueTerms = Set(reviewRecords.map { $0.term })
            
            // 构建完整的 Word 对象
            var learnedWords: [Word] = []
            for term in uniqueTerms {
                // 查找该单词的第一条记录（包含完整信息）
                if let record = reviewRecords.first(where: { $0.term == term }) {
                    let word = Word(
                        term: record.term,
                        phonetic: "",  // ReviewRecord 中没有音标
                        partOfSpeech: record.partOfSpeech,
                        meaning: record.meaning,
                        example: nil
                    )
                    learnedWords.append(word)
                }
            }
            
            return learnedWords
        }
    }
    
    /// 获取导出的 Excel 记录数（行数 - 表头）
    func getExportedRecordCount() -> Int {
        let templateURL = PersistencePaths.exportTemplateURL
        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            return 0
        }
        
        do {
            let xlsxWriter = XLSXWriter()
            return try xlsxWriter.getRecordCount(from: templateURL)
        } catch {
            NSLog("⚠️ 读取导出记录数失败: \(error)")
            return 0
        }
    }

    // MARK: - Private helpers

    private func randomDistractors(excluding word: Word, count: Int, within candidates: [Word]) -> [Word] {
        let filtered = candidates.filter { $0 != word }
        guard filtered.count >= count else { return filtered }
        return Array(filtered.shuffled().prefix(count))
    }

    private func ensureDefaultDeckIfNeeded() {
        storageQueue.sync {
            guard deck.words.isEmpty else { return }
            guard let csvURL = bundle.url(forResource: "default_words", withExtension: "csv") else {
                NSLog("默认词库缺失 default_words.csv")
                return
            }
            do {
                let newDeck = try excelIO.importDeck(from: csvURL)
                deck = newDeck
                try saveDeck()
            } catch {
                NSLog("导入默认词库失败: \(error)")
            }
        }
    }

    private func loadDeck() throws -> Deck {
        if !fileManager.fileExists(atPath: PersistencePaths.deckURL.path) {
            return Deck()
        }
        let data = try Data(contentsOf: PersistencePaths.deckURL)
        return try decoder.decode(Deck.self, from: data)
    }

    private func loadReviewRecords() throws -> [ReviewRecord] {
        guard fileManager.fileExists(atPath: PersistencePaths.reviewURL.path) else {
            return []
        }
        let data = try Data(contentsOf: PersistencePaths.reviewURL)
        return try decoder.decode([ReviewRecord].self, from: data)
    }

    private func loadSessionConfig() throws -> SessionConfig {
        guard fileManager.fileExists(atPath: PersistencePaths.sessionConfigURL.path) else {
            return SessionConfig()
        }
        let data = try Data(contentsOf: PersistencePaths.sessionConfigURL)
        return try decoder.decode(SessionConfig.self, from: data)
    }

    private func saveDeck() throws {
        let data = try encoder.encode(deck)
        try data.write(to: PersistencePaths.deckURL, options: .atomic)
    }

    private func saveReviewRecords() throws {
        let data = try encoder.encode(reviewRecords)
        try data.write(to: PersistencePaths.reviewURL, options: .atomic)
    }

    private func saveSessionConfig() throws {
        let data = try encoder.encode(sessionConfig)
        try data.write(to: PersistencePaths.sessionConfigURL, options: .atomic)
    }
    
    // MARK: - Multi-Deck Management
    
    /// 列出所有可用的词库
    func listAvailableDecks() -> [String] {
        var decks = ["默认词库"]
        
        do {
            let deckFiles = try fileManager.contentsOfDirectory(at: PersistencePaths.decksDirectory,
                                                                includingPropertiesForKeys: nil,
                                                                options: .skipsHiddenFiles)
            for fileURL in deckFiles where fileURL.pathExtension == "json" {
                let deckName = fileURL.deletingPathExtension().lastPathComponent
                decks.append(deckName)
            }
        } catch {
            NSLog("📚 读取词库目录失败: \(error)")
        }
        
        return decks
    }
    
    /// 返回当前激活的词库名称
    func currentDeckName() -> String {
        return storageQueue.sync { sessionConfig.currentDeckName }
    }
    
    /// 切换到指定的词库
    func switchToDeck(named deckName: String) throws {
        try storageQueue.sync {
            let newDeck: Deck
            
            if deckName == "默认词库" {
                // 加载默认词库(从 Deck.json)
                newDeck = try loadDeck()
                if newDeck.words.isEmpty {
                    // 如果默认词库为空,从 CSV 加载
                    guard let csvURL = bundle.url(forResource: "default_words", withExtension: "csv") else {
                        throw NSError(domain: "MicroMasters.StudyManager",
                                      code: -30,
                                      userInfo: [NSLocalizedDescriptionKey: "默认词库文件不存在"])
                    }
                    let csvDeck = try excelIO.importDeck(from: csvURL)
                    try saveDeck()
                    deck = csvDeck
                } else {
                    deck = newDeck
                }
            } else {
                // 加载导入的词库(从 Decks/{name}.json)
                let deckURL = PersistencePaths.decksDirectory.appendingPathComponent("\(deckName).json")
                guard fileManager.fileExists(atPath: deckURL.path) else {
                    throw NSError(domain: "MicroMasters.StudyManager",
                                  code: -31,
                                  userInfo: [NSLocalizedDescriptionKey: "词库文件不存在: \(deckName)"])
                }
                let data = try Data(contentsOf: deckURL)
                newDeck = try decoder.decode(Deck.self, from: data)
                deck = newDeck
            }
            
            // 更新当前词库名称并保存配置
            sessionConfig.currentDeckName = deckName
            try saveSessionConfig()
            
            NSLog("📚 已切换到词库: \(deckName), 共 \(deck.words.count) 个单词")
        }
    }
}
