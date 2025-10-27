//
//  ExcelIO.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import Foundation

final class ExcelIO {
    enum ExcelError: Error {
        case unsupportedFormat(String)
        case invalidHeader
        case invalidRow
    }
    
    private let xlsxWriter = XLSXWriter()

    func importDeck(from url: URL) throws -> Deck {
        switch url.pathExtension.lowercased() {
        case "csv", "txt":
            return try importCSVDeck(from: url)
        case "xlsx":
            print("TODO: XLSX 导入暂未实现，请导入 CSV 文件。")
            throw ExcelError.unsupportedFormat("暂不支持 XLSX 导入")
        default:
            throw ExcelError.unsupportedFormat("不支持的文件扩展名：\(url.pathExtension)")
        }
    }

    func exportRecords(_ records: [ReviewRecord], to url: URL) throws {
        switch url.pathExtension.lowercased() {
        case "csv":
            let data = try records.csvData()
            try data.write(to: url, options: .atomic)
        case "xlsx":
            // 简化实现:导出为 CSV 格式 (真正的 xlsx 需要第三方库如 CoreXLSX)
            print("⚠️ 暂将 XLSX 导出为 CSV 格式")
            let csvURL = url.deletingPathExtension().appendingPathExtension("csv")
            let data = try records.csvData()
            try data.write(to: csvURL, options: .atomic)
        default:
            throw ExcelError.unsupportedFormat("不支持的文件扩展名：\(url.pathExtension)")
        }
    }
    
    /// 导出记录到模板文件(追加模式)
    func exportRecordsToTemplate(_ records: [ReviewRecord]) throws {
        let templateURL = PersistencePaths.exportTemplateURL
        let xlsxTemplateURL = templateURL.deletingPathExtension().appendingPathExtension("xlsx")
        
        // 如果用户模板不存在，从 bundle 或原始位置复制
        if !FileManager.default.fileExists(atPath: xlsxTemplateURL.path) {
            try copyTemplateFromBundle(to: xlsxTemplateURL)
        }
        
        // 使用 XLSXWriter 直接追加到 XLSX 文件
        try xlsxWriter.appendRecords(records, to: xlsxTemplateURL)
        
        NSLog("📊 成功追加 \(records.count) 条记录到 Excel: \(xlsxTemplateURL.lastPathComponent)")
    }
    
    /// 从 Bundle 或原始位置复制模板文件
    private func copyTemplateFromBundle(to destinationURL: URL) throws {
        // 优先从 Bundle 查找
        if let bundleURL = Bundle.main.url(forResource: "WordStudyTemplate", withExtension: "xlsx") {
            try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
            NSLog("📊 已从 Bundle 复制模板")
            return
        }
        
        // 从原始位置查找
        let sourceURL = URL(fileURLWithPath: "/Users/shenkeyu/Documents/MicroMasters/WordStudyTemplate.xlsx")
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            NSLog("📊 已从项目目录复制模板")
            return
        }
        
        // 如果都找不到，创建一个简单的模板
        try createDefaultTemplate(at: destinationURL)
        NSLog("📊 已创建默认模板")
    }
    
    /// 创建默认 XLSX 模板
    private func createDefaultTemplate(at url: URL) throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 创建基本的 XLSX 结构
        try createXLSXStructure(at: tempDir)
        
        // 打包成 XLSX
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", url.path, "."]
        process.currentDirectoryURL = tempDir
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw ExcelError.unsupportedFormat("创建模板失败")
        }
    }
    
    /// 创建 XLSX 文件结构
    private func createXLSXStructure(at baseURL: URL) throws {
        let fm = FileManager.default
        
        // 创建目录结构
        try fm.createDirectory(at: baseURL.appendingPathComponent("_rels"), withIntermediateDirectories: true)
        try fm.createDirectory(at: baseURL.appendingPathComponent("docProps"), withIntermediateDirectories: true)
        try fm.createDirectory(at: baseURL.appendingPathComponent("xl/worksheets"), withIntermediateDirectories: true)
        try fm.createDirectory(at: baseURL.appendingPathComponent("xl/_rels"), withIntermediateDirectories: true)
        
        // [Content_Types].xml
        let contentTypes = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"""
        try contentTypes.write(to: baseURL.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        
        // _rels/.rels
        let rels = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"""
        try rels.write(to: baseURL.appendingPathComponent("_rels/.rels"), atomically: true, encoding: .utf8)
        
        // xl/workbook.xml
        let workbook = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
<sheet name="学习记录" sheetId="1" r:id="rId1"/>
</sheets>
</workbook>
"""
        try workbook.write(to: baseURL.appendingPathComponent("xl/workbook.xml"), atomically: true, encoding: .utf8)
        
        // xl/_rels/workbook.xml.rels
        let workbookRels = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>
"""
        try workbookRels.write(to: baseURL.appendingPathComponent("xl/_rels/workbook.xml.rels"), atomically: true, encoding: .utf8)
        
        // xl/worksheets/sheet1.xml (带表头)
        let sheet1 = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>
<row r="1">
<c r="A1" t="inlineStr"><is><t>单词</t></is></c>
<c r="B1" t="inlineStr"><is><t>翻译</t></is></c>
<c r="C1" t="inlineStr"><is><t>词性</t></is></c>
<c r="D1" t="inlineStr"><is><t>导出日期</t></is></c>
</row>
</sheetData>
</worksheet>
"""
        try sheet1.write(to: baseURL.appendingPathComponent("xl/worksheets/sheet1.xml"), atomically: true, encoding: .utf8)
        
        // docProps/core.xml
        let core = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:creator>MicroMasters</dc:creator>
<cp:lastModifiedBy>MicroMasters</cp:lastModifiedBy>
<dcterms:created xsi:type="dcterms:W3CDTF">2024-01-01T00:00:00Z</dcterms:created>
<dcterms:modified xsi:type="dcterms:W3CDTF">2024-01-01T00:00:00Z</dcterms:modified>
</cp:coreProperties>
"""
        try core.write(to: baseURL.appendingPathComponent("docProps/core.xml"), atomically: true, encoding: .utf8)
        
        // docProps/app.xml
        let app = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
<Application>MicroMasters</Application>
</Properties>
"""
        try app.write(to: baseURL.appendingPathComponent("docProps/app.xml"), atomically: true, encoding: .utf8)
    }

    // MARK: - CSV

    private func importCSVDeck(from url: URL) throws -> Deck {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ExcelError.invalidRow
        }

        let rows = parseCSV(content)
        guard !rows.isEmpty else {
            throw ExcelError.invalidHeader
        }

        // 检查第一行是否为标准头部
        let expectedHeader = ["term", "phonetic", "pos", "meaning", "example"]
        var dataRows: ArraySlice<[String]>
        
        if let firstRow = rows.first, firstRow.count >= 5 {
            let normalizedHeader = firstRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let isStandardHeader = normalizedHeader.prefix(expectedHeader.count) == expectedHeader[0..<expectedHeader.count]
            
            if isStandardHeader {
                // 有标准头部,跳过第一行
                dataRows = rows.dropFirst()
            } else {
                // 没有标准头部,从第一行开始解析
                dataRows = rows[...]
            }
        } else {
            // 第一行列数不足,作为数据行处理
            dataRows = rows[...]
        }

        var words: [Word] = []

        for row in dataRows {
            if row.isEmpty || row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            
            // 至少需要单词列
            guard row.count >= 1 else {
                continue
            }

            let term = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if term.isEmpty { continue }
            
            // 根据列数灵活解析
            let phonetic: String
            let pos: String
            let meaning: String
            let example: String?
            
            if row.count >= 5 {
                // 完整格式: term, phonetic, pos, meaning, example
                phonetic = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
                pos = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
                meaning = row[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let exampleValue = row[4].trimmingCharacters(in: .whitespacesAndNewlines)
                example = exampleValue.isEmpty ? nil : exampleValue
            } else if row.count >= 4 {
                // 4列: term, phonetic, pos, meaning
                phonetic = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
                pos = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
                meaning = row[3].trimmingCharacters(in: .whitespacesAndNewlines)
                example = nil
            } else if row.count >= 3 {
                // 3列: term, pos, meaning
                phonetic = ""
                pos = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
                meaning = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
                example = nil
            } else if row.count >= 2 {
                // 2列: term, meaning (可能包含词性)
                phonetic = ""
                let rawMeaning = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 尝试提取词性(如: "v./n.放弃；放纵" -> pos="v./n.", meaning="放弃；放纵")
                let pattern = "^([a-z]+(?:\\.[/\\s]*[a-z]+)*\\.?)\\s*(.+)$"
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: rawMeaning, range: NSRange(rawMeaning.startIndex..., in: rawMeaning)) {
                    if let posRange = Range(match.range(at: 1), in: rawMeaning),
                       let meaningRange = Range(match.range(at: 2), in: rawMeaning) {
                        pos = String(rawMeaning[posRange])
                        meaning = String(rawMeaning[meaningRange])
                    } else {
                        pos = ""
                        meaning = rawMeaning
                    }
                } else {
                    pos = ""
                    meaning = rawMeaning
                }
                example = nil
            } else {
                // 只有1列: term (跳过没有释义的单词)
                continue
            }

            let word = Word(term: term,
                            phonetic: phonetic,
                            partOfSpeech: pos,
                            meaning: meaning,
                            example: example)
            words.append(word)
        }

        return Deck(words: words)
    }

    private func parseCSV(_ string: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        let scalars = Array(string.unicodeScalars)
        var index = 0

        while index < scalars.count {
            let scalar = scalars[index]
            switch scalar {
            case "\"":
                if insideQuotes {
                    let nextIndex = index + 1
                    if nextIndex < scalars.count && scalars[nextIndex] == "\"" {
                        currentField.unicodeScalars.append("\"")
                        index += 1
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            case ",":
                if insideQuotes {
                    currentField.unicodeScalars.append(scalar)
                } else {
                    currentRow.append(currentField)
                    currentField = ""
                }
            case "\n":
                if insideQuotes {
                    currentField.unicodeScalars.append(scalar)
                } else {
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                }
            case "\r":
                break
            default:
                currentField.unicodeScalars.append(scalar)
            }
            index += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }
}
