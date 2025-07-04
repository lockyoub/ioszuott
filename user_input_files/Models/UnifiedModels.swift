//
// UnifiedModels.swift
// 统一数据模型 - iOS版本
// 基于Protobuf定义自动生成
// 作者: MiniMax Agent
//

import Foundation
import CoreData

// MARK: - 高精度Decimal处理

extension NSDecimalNumber {
    /// 从字符串安全创建NSDecimalNumber
    static func fromString(_ string: String?) -> NSDecimalNumber {
        guard let string = string, !string.isEmpty else {
            return NSDecimalNumber.zero
        }
        let decimal = NSDecimalNumber(string: string)
        return decimal == NSDecimalNumber.notANumber ? NSDecimalNumber.zero : decimal
    }
    

}

// MARK: - 统一股票模型

@objc(UnifiedStockEntity)
public class UnifiedStockEntity: NSManagedObject {
    
    // MARK: - 基本信息
    @NSManaged public var code: String              // 股票代码
    @NSManaged public var symbol: String            // 兼容字段 (等同于code)
    @NSManaged public var name: String              // 股票名称
    @NSManaged public var market: String            // 市场
    @NSManaged public var exchange: String          // 交易所
    @NSManaged public var industry: String?         // 行业
    @NSManaged public var sector: String?           // 板块
    @NSManaged public var status: String            // 状态
    
    // MARK: - 财务数据 (Decimal类型)
    @NSManaged public var totalShares: NSDecimalNumber?     // 总股本
    @NSManaged public var floatShares: NSDecimalNumber?     // 流通股本
    @NSManaged public var marketCap: NSDecimalNumber?       // 总市值
    @NSManaged public var peRatio: NSDecimalNumber?         // 市盈率
    @NSManaged public var pbRatio: NSDecimalNumber?         // 市净率
    
    // MARK: - 实时价格数据 (Decimal类型)
    @NSManaged public var lastPrice: NSDecimalNumber        // 最新价
    @NSManaged public var change: NSDecimalNumber           // 涨跌额
    @NSManaged public var changePercent: NSDecimalNumber    // 涨跌幅
    @NSManaged public var volume: NSDecimalNumber           // 成交量 (统一为Decimal)
    @NSManaged public var amount: NSDecimalNumber           // 成交额
    
    // MARK: - 时间戳
    @NSManaged public var listDate: Date?           // 上市日期
    @NSManaged public var timestamp: Date           // 价格时间戳
    @NSManaged public var createdAt: Date           // 创建时间
    @NSManaged public var updatedAt: Date           // 更新时间
    @NSManaged public var lastModified: Date        // 最后修改时间
    
    // MARK: - 关系
    @NSManaged public var marketDepths: NSSet?      // 盘口数据
    @NSManaged public var klines: NSSet?            // K线数据
    @NSManaged public var trades: NSSet?            // 交易记录
    @NSManaged public var positions: NSSet?         // 持仓记录
    
    // MARK: - 便利方法
    
    /// 更新基本信息
    func updateBasicInfo(from data: [String: Any]) {
        if let code = data["code"] as? String ?? data["symbol"] as? String {
            self.code = code
            self.symbol = code
        }
        if let name = data["name"] as? String {
            self.name = name
        }
        if let market = data["market"] as? String {
            self.market = market
        }
        if let exchange = data["exchange"] as? String {
            self.exchange = exchange
        }
        if let industry = data["industry"] as? String {
            self.industry = industry
        }
        if let sector = data["sector"] as? String {
            self.sector = sector
        }
        if let status = data["status"] as? String {
            self.status = status
        }
    }
    
    /// 更新财务数据
    func updateFinancialData(from data: [String: Any]) {
        if let totalSharesStr = data["total_shares"] as? String {
            self.totalShares = NSDecimalNumber.fromString(totalSharesStr)
        }
        if let floatSharesStr = data["float_shares"] as? String {
            self.floatShares = NSDecimalNumber.fromString(floatSharesStr)
        }
        if let marketCapStr = data["market_cap"] as? String {
            self.marketCap = NSDecimalNumber.fromString(marketCapStr)
        }
        if let peRatioStr = data["pe_ratio"] as? String {
            self.peRatio = NSDecimalNumber.fromString(peRatioStr)
        }
        if let pbRatioStr = data["pb_ratio"] as? String {
            self.pbRatio = NSDecimalNumber.fromString(pbRatioStr)
        }
    }
    
    /// 更新价格数据 (高精度)
    func updatePriceData(from data: [String: Any]) {
        // 统一的高精度解析
        if let lastPriceStr = data["last_price"] as? String ?? data["lastPrice"] as? String {
            self.lastPrice = NSDecimalNumber.fromString(lastPriceStr)
        }
        if let changeStr = data["change"] as? String {
            self.change = NSDecimalNumber.fromString(changeStr)
        }
        if let changePercentStr = data["change_percent"] as? String ?? data["changePercent"] as? String {
            self.changePercent = NSDecimalNumber.fromString(changePercentStr)
        }
        if let volumeStr = data["volume"] as? String {
            self.volume = NSDecimalNumber.fromString(volumeStr)
        }
        if let amountStr = data["amount"] as? String {
            self.amount = NSDecimalNumber.fromString(amountStr)
        }
        
        self.timestamp = Date()
        self.lastModified = Date()
    }
    
    /// 获取盘口数据
    var marketDepthData: [String: Any] {
        guard let depths = marketDepths?.allObjects as? [UnifiedMarketDepthEntity] else {
            return [:]
        }
        
        let bidLevels = depths.filter { $0.side == "bid" }.sorted { $0.level < $1.level }
        let askLevels = depths.filter { $0.side == "ask" }.sorted { $0.level < $1.level }
        
        return [
            "bid_levels": bidLevels.map { ["level": $0.level, "price": $0.price.stringValue, "volume": $0.volume] },
            "ask_levels": askLevels.map { ["level": $0.level, "price": $0.price.stringValue, "volume": $0.volume] },
            "timestamp": timestamp.iso8601String(),
            // 向后兼容
            "bidPrices": bidLevels.map { $0.price.stringValue },
            "bidVolumes": bidLevels.map { $0.volume },
            "askPrices": askLevels.map { $0.price.stringValue },
            "askVolumes": askLevels.map { $0.volume }
        ]
    }
}

// MARK: - 统一盘口数据模型

@objc(UnifiedMarketDepthEntity)
public class UnifiedMarketDepthEntity: NSManagedObject {
    @NSManaged public var price: NSDecimalNumber     // 价格
    @NSManaged public var volume: Int64              // 数量
    @NSManaged public var side: String               // 方向 (bid/ask)
    @NSManaged public var level: Int32               // 档位
    @NSManaged public var timestamp: Date            // 时间戳
    @NSManaged public var stock: UnifiedStockEntity? // 关联股票
}

// MARK: - 统一K线模型

@objc(UnifiedKLineEntity)
public class UnifiedKLineEntity: NSManagedObject {
    @NSManaged public var stockCode: String          // 股票代码
    @NSManaged public var symbol: String             // 兼容字段
    @NSManaged public var datetime: Date             // 时间
    @NSManaged public var timestamp: Date            // 兼容字段
    @NSManaged public var period: String             // 周期
    @NSManaged public var timeframe: String          // 兼容字段
    
    // OHLC数据 (Decimal类型)
    @NSManaged public var openPrice: NSDecimalNumber  // 开盘价
    @NSManaged public var open: NSDecimalNumber       // 兼容字段
    @NSManaged public var highPrice: NSDecimalNumber  // 最高价
    @NSManaged public var high: NSDecimalNumber       // 兼容字段
    @NSManaged public var lowPrice: NSDecimalNumber   // 最低价
    @NSManaged public var low: NSDecimalNumber        // 兼容字段
    @NSManaged public var closePrice: NSDecimalNumber // 收盘价
    @NSManaged public var close: NSDecimalNumber      // 兼容字段
    
    // 成交信息 (Decimal类型)
    @NSManaged public var volume: NSDecimalNumber     // 成交量
    @NSManaged public var amount: NSDecimalNumber     // 成交额
    
    @NSManaged public var stock: UnifiedStockEntity?  // 关联股票
    
    /// 从数据字典更新
    func updateFromData(_ data: [String: Any]) {
        if let stockCode = data["stock_code"] as? String ?? data["symbol"] as? String {
            self.stockCode = stockCode
            self.symbol = stockCode
        }
        
        if let datetimeStr = data["datetime"] as? String ?? data["timestamp"] as? String {
            self.datetime = ISO8601DateFormatter().date(from: datetimeStr) ?? Date()
            self.timestamp = self.datetime
        }
        
        if let period = data["period"] as? String ?? data["timeframe"] as? String {
            self.period = period
            self.timeframe = period
        }
        
        // 高精度OHLC数据
        if let openStr = data["open_price"] as? String ?? data["open"] as? String {
            self.openPrice = NSDecimalNumber.fromString(openStr)
            self.open = self.openPrice
        }
        if let highStr = data["high_price"] as? String ?? data["high"] as? String {
            self.highPrice = NSDecimalNumber.fromString(highStr)
            self.high = self.highPrice
        }
        if let lowStr = data["low_price"] as? String ?? data["low"] as? String {
            self.lowPrice = NSDecimalNumber.fromString(lowStr)
            self.low = self.lowPrice
        }
        if let closeStr = data["close_price"] as? String ?? data["close"] as? String {
            self.closePrice = NSDecimalNumber.fromString(closeStr)
            self.close = self.closePrice
        }
        
        if let volumeStr = data["volume"] as? String {
            self.volume = NSDecimalNumber.fromString(volumeStr)
        }
        if let amountStr = data["amount"] as? String {
            self.amount = NSDecimalNumber.fromString(amountStr)
        }
    }
}

// MARK: - 辅助扩展

extension Date {
    func iso8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
}

// 继续定义其他统一模型...
// (由于长度限制，这里只展示核心模型)
