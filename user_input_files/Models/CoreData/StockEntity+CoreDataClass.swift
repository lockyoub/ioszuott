/*
 StockEntity Core Data类扩展
 股票信息实体类
 作者: MiniMax Agent
 创建时间: 2025-06-24 15:23:57
 */

import Foundation
import CoreData

// MARK: - NSDecimalNumber扩展
extension NSDecimalNumber {
    static func fromString(_ string: String) -> NSDecimalNumber {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanString.isEmpty {
            return NSDecimalNumber.zero
        }
        
        let decimal = NSDecimalNumber(string: cleanString)
        return decimal == NSDecimalNumber.notANumber ? NSDecimalNumber.zero : decimal
    }
}

@objc(StockEntity)
public class StockEntity: NSManagedObject {
    
    // MARK: - 便利属性
    
    /// 买盘价格数组（高精度）
    var bidPricesArray: [NSDecimalNumber] {
        get {
            guard let bidPrices = bidPrices,
                  let data = bidPrices.data(using: .utf8),
                  let stringArray = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return stringArray.map { NSDecimalNumber.fromString($0) }
        }
        set {
            let stringArray = newValue.map { $0.stringValue }
            if let data = try? JSONEncoder().encode(stringArray),
               let string = String(data: data, encoding: .utf8) {
                bidPrices = string
            }
        }
    }
    
    /// 买盘数量数组
    var bidVolumesArray: [Int64] {
        get {
            guard let bidVolumes = bidVolumes,
                  let data = bidVolumes.data(using: .utf8),
                  let array = try? JSONDecoder().decode([Int64].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                bidVolumes = string
            }
        }
    }
    
    /// 卖盘价格数组（高精度）
    var askPricesArray: [NSDecimalNumber] {
        get {
            guard let askPrices = askPrices,
                  let data = askPrices.data(using: .utf8),
                  let stringArray = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return stringArray.map { NSDecimalNumber.fromString($0) }
        }
        set {
            let stringArray = newValue.map { $0.stringValue }
            if let data = try? JSONEncoder().encode(stringArray),
               let string = String(data: data, encoding: .utf8) {
                askPrices = string
            }
        }
    }
    
    /// 卖盘数量数组
    var askVolumesArray: [Int64] {
        get {
            guard let askVolumes = askVolumes,
                  let data = askVolumes.data(using: .utf8),
                  let array = try? JSONDecoder().decode([Int64].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                askVolumes = string
            }
        }
    }
    
    // MARK: - 便利方法
    
    /// 更新股票价格信息（高精度）
    func updatePrice(
        lastPrice: NSDecimalNumber,
        change: NSDecimalNumber,
        changePercent: NSDecimalNumber,
        volume: Int64,
        amount: NSDecimalNumber
    ) {
        self.lastPrice = lastPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.timestamp = Date()
    }
    
    /// 更新盘口数据（高精度）
    func updateOrderBook(
        bidPrices: [NSDecimalNumber],
        bidVolumes: [Int64],
        askPrices: [NSDecimalNumber],
        askVolumes: [Int64]
    ) {
        self.bidPricesArray = bidPrices
        self.bidVolumesArray = bidVolumes
        self.askPricesArray = askPrices
        self.askVolumesArray = askVolumes
        self.timestamp = Date()
    }
    
    /// 格式化价格显示（高精度）
    var formattedPrice: String {
        return formatDecimalPrice(lastPrice)
    }
    
    /// 格式化涨跌幅显示（高精度）
    var formattedChangePercent: String {
        let sign = changePercent.compare(NSDecimalNumber.zero) != .orderedAscending ? "+" : ""
        return "\(sign)\(formatDecimalPrice(changePercent))%"
    }
    
    /// 格式化Decimal价格的辅助方法
    private func formatDecimalPrice(_ decimal: NSDecimalNumber, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter.string(from: decimal) ?? "0.00"
    }
    
    /// 格式化成交量显示
    var formattedVolume: String {
        if volume >= 100_000_000 {
            return String(format: "%.1f亿", Double(volume) / 100_000_000)
        } else if volume >= 10_000 {
            return String(format: "%.1f万", Double(volume) / 10_000)
        } else {
            return "\(volume)"
        }
    }
    
    /// 是否上涨
    var isUp: Bool {
        return changePercent.compare(NSDecimalNumber.zero) == .orderedDescending
    }
    
    /// 是否下跌
    var isDown: Bool {
        return changePercent.compare(NSDecimalNumber.zero) == .orderedAscending
    }
    
    /// 是否平盘
    var isFlat: Bool {
        return changePercent.compare(NSDecimalNumber.zero) == .orderedSame
    }
}

// MARK: - Identifiable
extension StockEntity: Identifiable {
    public var id: String { symbol }
}
