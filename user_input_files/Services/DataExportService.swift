//
//  DataExportService.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  数据导出服务 - 提供股票数据的CSV和Excel格式导出功能
//

import Foundation
import UIKit

/// 数据导出服务
@MainActor
public class DataExportService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // MARK: - 导出格式
    public enum ExportFormat: String, CaseIterable {
        case csv = "csv"
        case excel = "xlsx"
        
        var displayName: String {
            switch self {
            case .csv:
                return "CSV文件"
            case .excel:
                return "Excel文件"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
        
        var mimeType: String {
            switch self {
            case .csv:
                return "text/csv"
            case .excel:
                return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            }
        }
    }
    
    // MARK: - 导出股票K线数据
    
    /// 导出股票K线数据
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - candlestickData: K线数据
    ///   - format: 导出格式
    /// - Returns: 导出文件的URL
    public func exportCandlestickData(
        stockCode: String,
        stockName: String,
        candlestickData: [CandlestickData],
        format: ExportFormat
    ) async -> URL? {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            let fileName = "\(stockName)(\(stockCode))_K线数据_\(formatDate(Date(), format: "yyyyMMdd_HHmmss")).\(format.fileExtension)"
            
            switch format {
            case .csv:
                return try await exportToCSV(
                    fileName: fileName,
                    stockCode: stockCode,
                    stockName: stockName,
                    candlestickData: candlestickData
                )
            case .excel:
                return try await exportToExcel(
                    fileName: fileName,
                    stockCode: stockCode,
                    stockName: stockName,
                    candlestickData: candlestickData
                )
            }
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 导出成交量数据
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - volumeData: 成交量数据
    ///   - format: 导出格式
    /// - Returns: 导出文件的URL
    public func exportVolumeData(
        stockCode: String,
        stockName: String,
        volumeData: [VolumeData],
        format: ExportFormat
    ) async -> URL? {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            let fileName = "\(stockName)(\(stockCode))_成交量数据_\(formatDate(Date(), format: "yyyyMMdd_HHmmss")).\(format.fileExtension)"
            
            let csvContent = generateVolumeCSVContent(
                stockCode: stockCode,
                stockName: stockName,
                volumeData: volumeData
            )
            
            return try await saveToFile(content: csvContent, fileName: fileName)
            
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 导出技术指标数据
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - indicatorData: 技术指标数据
    ///   - format: 导出格式
    /// - Returns: 导出文件的URL
    public func exportIndicatorData(
        stockCode: String,
        stockName: String,
        indicatorData: [IndicatorData],
        format: ExportFormat
    ) async -> URL? {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            let fileName = "\(stockName)(\(stockCode))_技术指标_\(formatDate(Date(), format: "yyyyMMdd_HHmmss")).\(format.fileExtension)"
            
            let csvContent = generateIndicatorCSVContent(
                stockCode: stockCode,
                stockName: stockName,
                indicatorData: indicatorData
            )
            
            return try await saveToFile(content: csvContent, fileName: fileName)
            
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - 私有方法
    
    /// 导出为CSV格式
    private func exportToCSV(
        fileName: String,
        stockCode: String,
        stockName: String,
        candlestickData: [CandlestickData]
    ) async throws -> URL? {
        exportProgress = 0.2
        
        let csvContent = generateCandlestickCSVContent(
            stockCode: stockCode,
            stockName: stockName,
            candlestickData: candlestickData
        )
        
        exportProgress = 0.8
        
        return try await saveToFile(content: csvContent, fileName: fileName)
    }
    
    /// 导出为Excel格式 (这里简化为CSV格式，实际应用中需要使用专门的Excel库)
    private func exportToExcel(
        fileName: String,
        stockCode: String,
        stockName: String,
        candlestickData: [CandlestickData]
    ) async throws -> URL? {
        exportProgress = 0.2
        
        // 注意：这里简化为CSV格式
        // 实际应用中应该使用如 xlsxwriter 或其他Excel库来生成真正的Excel文件
        let csvContent = generateCandlestickCSVContent(
            stockCode: stockCode,
            stockName: stockName,
            candlestickData: candlestickData
        )
        
        exportProgress = 0.8
        
        return try await saveToFile(content: csvContent, fileName: fileName)
    }
    
    /// 生成K线数据的CSV内容
    private func generateCandlestickCSVContent(
        stockCode: String,
        stockName: String,
        candlestickData: [CandlestickData]
    ) -> String {
        var csvContent = ""
        
        // 添加文件头信息
        csvContent += "# \(stockName) (\(stockCode)) K线数据\n"
        csvContent += "# 导出时间: \(formatDate(Date()))\n"
        csvContent += "# 数据条数: \(candlestickData.count)\n"
        csvContent += "\n"
        
        // 添加列标题
        csvContent += "日期,开盘价,最高价,最低价,收盘价,成交量,涨跌幅(%)\n"
        
        // 添加数据行
        for (index, data) in candlestickData.enumerated() {
            let dateString = formatDate(data.timestamp, format: "yyyy-MM-dd HH:mm:ss")
            let changePercent = calculateChangePercent(data, previousData: index > 0 ? candlestickData[index - 1] : nil)
            
            csvContent += "\(dateString),\(data.open),\(data.high),\(data.low),\(data.close),\(data.volume),\(String(format: "%.2f", changePercent))\n"
            
            // 更新进度
            exportProgress = 0.2 + (Double(index) / Double(candlestickData.count)) * 0.6
        }
        
        return csvContent
    }
    
    /// 生成成交量数据的CSV内容
    private func generateVolumeCSVContent(
        stockCode: String,
        stockName: String,
        volumeData: [VolumeData]
    ) -> String {
        var csvContent = ""
        
        // 添加文件头信息
        csvContent += "# \(stockName) (\(stockCode)) 成交量数据\n"
        csvContent += "# 导出时间: \(formatDate(Date()))\n"
        csvContent += "# 数据条数: \(volumeData.count)\n"
        csvContent += "\n"
        
        // 添加列标题
        csvContent += "日期,成交量,成交额\n"
        
        // 添加数据行
        for data in volumeData {
            let dateString = formatDate(data.timestamp, format: "yyyy-MM-dd HH:mm:ss")
            csvContent += "\(dateString),\(data.volume),\(data.amount)\n"
        }
        
        return csvContent
    }
    
    /// 生成技术指标数据的CSV内容
    private func generateIndicatorCSVContent(
        stockCode: String,
        stockName: String,
        indicatorData: [IndicatorData]
    ) -> String {
        var csvContent = ""
        
        // 添加文件头信息
        csvContent += "# \(stockName) (\(stockCode)) 技术指标数据\n"
        csvContent += "# 导出时间: \(formatDate(Date()))\n"
        csvContent += "# 数据条数: \(indicatorData.count)\n"
        csvContent += "\n"
        
        // 添加列标题
        csvContent += "日期,指标类型,指标值\n"
        
        // 添加数据行
        for data in indicatorData {
            let dateString = formatDate(data.timestamp, format: "yyyy-MM-dd HH:mm:ss")
            csvContent += "\(dateString),\(data.indicatorType),\(data.value)\n"
        }
        
        return csvContent
    }
    
    /// 保存内容到文件
    private func saveToFile(content: String, fileName: String) async throws -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        exportProgress = 1.0
        
        return fileURL
    }
    
    /// 计算涨跌幅
    private func calculateChangePercent(_ data: CandlestickData, previousData: CandlestickData?) -> Double {
        guard let previousData = previousData else { return 0.0 }
        return ((data.close - previousData.close) / previousData.close) * 100
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // MARK: - 分享导出的文件
    
    /// 分享导出的文件
    /// - Parameters:
    ///   - fileURL: 文件URL
    ///   - sourceView: 源视图（用于iPad的弹出框定位）
    public func shareExportedFile(fileURL: URL, sourceView: UIView? = nil) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // iPad适配
        if let popover = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popover.sourceView = window.rootViewController?.view
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
        }
        
        // 呈现分享界面
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - 数据模型扩展 (如果不存在的话)

// 这些模型可能已经在其他地方定义了，这里只是为了确保编译通过
// CandlestickData 和 VolumeData 已移至 SharedModels.swift 统一管理

#if !INDICATOR_DATA_DEFINED
public struct IndicatorData {
    public let timestamp: Date
    public let indicatorType: String
    public let value: Double
}
#endif
