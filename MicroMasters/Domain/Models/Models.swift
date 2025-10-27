//
//  Models.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import Foundation

/// Represents a single vocabulary entry.
struct Word: Codable, Hashable {
    let term: String
    let phonetic: String
    let partOfSpeech: String
    let meaning: String
    let example: String?

    var displayTitle: String {
        phonetic.isEmpty ? term : "\(term) \(phonetic)"
    }
}

/// Persisted review attempt for a word.
struct ReviewRecord: Codable {
    let term: String
    let meaning: String
    let partOfSpeech: String
    let correct: Bool
    let timestamp: Date
}

/// Session configuration persisted on disk.
struct SessionConfig: Codable {
    static let defaultCount: Int = 20
    var wordCount: Int = SessionConfig.defaultCount
    var currentDeckName: String = "默认词库"  // 当前使用的词库名称
}

/// Mutable container for all available words.
struct Deck: Codable {
    var words: [Word]

    init(words: [Word] = []) {
        self.words = words
    }
}

/// Convenience helpers for persistence.
enum PersistencePaths {
    static let baseDirectoryName = "MicroMasters"

    static var applicationSupportDirectory: URL {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(baseDirectoryName, isDirectory: true)
    }

    static var deckURL: URL {
        applicationSupportDirectory.appendingPathComponent("Deck.json", isDirectory: false)
    }

    static var reviewURL: URL {
        applicationSupportDirectory.appendingPathComponent("ReviewRecord.json", isDirectory: false)
    }

    static var sessionConfigURL: URL {
        applicationSupportDirectory.appendingPathComponent("SessionConfig.json", isDirectory: false)
    }
    
    // 词库存放目录
    static var decksDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Decks", isDirectory: true)
    }
    
    // 导出模板目录
    static var exportTemplateURL: URL {
        applicationSupportDirectory.appendingPathComponent("ExportTemplate.xlsx", isDirectory: false)
    }
}

extension Array where Element == ReviewRecord {
    func csvData() throws -> Data {
        let header = "term,meaning,partOfSpeech,timestamp\n"
        let isoFormatter = ISO8601DateFormatter()
        let rows = map { record -> String in
            let timestamp = isoFormatter.string(from: record.timestamp)
            return "\(record.term.csvEscaped),\(record.meaning.csvEscaped),\(record.partOfSpeech.csvEscaped),\(timestamp.csvEscaped)"
        }
        let csvString = header + rows.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw NSError(domain: "MicroMasters.CSV", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法编码 CSV 数据"])
        }
        return data
    }
}

extension String {
    /// Escapes CSV value according to RFC 4180.
    var csvEscaped: String {
        if contains(",") || contains("\"") || contains("\n") {
            let escaped = replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return self
    }
}

