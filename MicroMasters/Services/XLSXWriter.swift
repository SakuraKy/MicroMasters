//
//  XLSXWriter.swift
//  MicroMasters
//
//  Created for XLSX file manipulation
//

import Foundation

final class XLSXWriter {
    
    enum XLSXError: Error {
        case templateNotFound
        case invalidZipStructure
        case readError(String)
        case writeError(String)
    }
    
    /// 向 XLSX 文件追加数据
    func appendRecords(_ records: [ReviewRecord], to xlsxURL: URL) throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 1. 解压 XLSX 文件
        try unzipXLSX(from: xlsxURL, to: tempDir)
        
        // 2. 读取并修改 sheet1.xml
        let sheetURL = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard FileManager.default.fileExists(atPath: sheetURL.path) else {
            throw XLSXError.invalidZipStructure
        }
        
        var sheetContent = try String(contentsOf: sheetURL, encoding: .utf8)
        
        // 3. 查找最后一行
        let lastRowNumber = findLastRowNumber(in: sheetContent)
        
        // 4. 插入新行
        sheetContent = try insertNewRows(records, startingFrom: lastRowNumber + 1, into: sheetContent)
        
        // 5. 写回修改后的内容
        try sheetContent.write(to: sheetURL, atomically: true, encoding: .utf8)
        
        // 6. 重新打包成 XLSX
        try zipXLSX(from: tempDir, to: xlsxURL)
        
        NSLog("📊 成功追加 \(records.count) 条记录到 Excel")
    }
    
    /// 创建新的 XLSX 文件（基于模板）
    func createXLSX(with records: [ReviewRecord], at xlsxURL: URL, templateURL: URL) throws {
        // 复制模板
        if FileManager.default.fileExists(atPath: xlsxURL.path) {
            try FileManager.default.removeItem(at: xlsxURL)
        }
        try FileManager.default.copyItem(at: templateURL, to: xlsxURL)
        
        // 追加记录
        if !records.isEmpty {
            try appendRecords(records, to: xlsxURL)
        }
    }
    
    /// 获取 XLSX 文件中的记录数（行数 - 表头行）
    func getRecordCount(from xlsxURL: URL) throws -> Int {
        guard FileManager.default.fileExists(atPath: xlsxURL.path) else {
            return 0
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 解压 XLSX 文件
        try unzipXLSX(from: xlsxURL, to: tempDir)
        
        // 读取 sheet1.xml
        let sheetURL = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard FileManager.default.fileExists(atPath: sheetURL.path) else {
            return 0
        }
        
        let sheetContent = try String(contentsOf: sheetURL, encoding: .utf8)
        let lastRowNumber = findLastRowNumber(in: sheetContent)
        
        // 减去表头行（第1行）
        return max(0, lastRowNumber - 1)
    }
    
    // MARK: - Private Methods
    
    private func unzipXLSX(from source: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", "-o", source.path, "-d", destination.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw XLSXError.readError("解压失败")
        }
    }
    
    private func zipXLSX(from source: URL, to destination: URL) throws {
        // 删除旧文件
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", destination.path, "."]
        process.currentDirectoryURL = source
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw XLSXError.writeError("压缩失败")
        }
    }
    
    private func findLastRowNumber(in sheetXML: String) -> Int {
        // 查找所有 <row r="数字"> 标签
        let pattern = #"<row r="(\d+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return 1 // 默认从第2行开始（第1行是表头）
        }
        
        let nsString = sheetXML as NSString
        let matches = regex.matches(in: sheetXML, range: NSRange(location: 0, length: nsString.length))
        
        var maxRow = 1
        for match in matches {
            if match.numberOfRanges > 1 {
                let rowNumberRange = match.range(at: 1)
                if let rowNumber = Int(nsString.substring(with: rowNumberRange)) {
                    maxRow = max(maxRow, rowNumber)
                }
            }
        }
        
        return maxRow
    }
    
    private func insertNewRows(_ records: [ReviewRecord], startingFrom startRow: Int, into sheetXML: String) throws -> String {
        // 找到 </sheetData> 标签的位置
        guard let sheetDataEndRange = sheetXML.range(of: "</sheetData>") else {
            throw XLSXError.invalidZipStructure
        }
        
        var newContent = String(sheetXML[..<sheetDataEndRange.lowerBound])
        
        // 创建中文日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        // 为每条记录生成行：单词、意思、词性、时间
        for (index, record) in records.enumerated() {
            let rowNumber = startRow + index
            let timestamp = dateFormatter.string(from: record.timestamp)
            
            let rowXML = """
<row r="\(rowNumber)">
<c r="A\(rowNumber)" t="inlineStr"><is><t>\(xmlEscape(record.term))</t></is></c>
<c r="B\(rowNumber)" t="inlineStr"><is><t>\(xmlEscape(record.meaning))</t></is></c>
<c r="C\(rowNumber)" t="inlineStr"><is><t>\(xmlEscape(record.partOfSpeech))</t></is></c>
<c r="D\(rowNumber)" t="inlineStr"><is><t>\(timestamp)</t></is></c>
</row>
"""
            newContent += rowXML
        }
        
        newContent += String(sheetXML[sheetDataEndRange.lowerBound...])
        return newContent
    }
    
    private func xmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
