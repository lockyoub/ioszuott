//
// SharedModels.swift
// 统一的共享数据结构
// 用于解决项目中重复定义的结构体问题
// 作者: MiniMax Agent
//

import Foundation
import SwiftUI

// MARK: - 通知设置

/// 统一的通知设置结构
struct NotificationSettings: Codable {
    var priceAlerts: Bool = true
    var positionAlerts: Bool = true
    var strategySignals: Bool = true
    var systemNotifications: Bool = true
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var quietHours: DateInterval?
    
    init() {}
    
    init(
        priceAlerts: Bool = true,
        positionAlerts: Bool = true,
        strategySignals: Bool = true,
        systemNotifications: Bool = true,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        quietHours: DateInterval? = nil
    ) {
        self.priceAlerts = priceAlerts
        self.positionAlerts = positionAlerts
        self.strategySignals = strategySignals
        self.systemNotifications = systemNotifications
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.quietHours = quietHours
    }
}

// MARK: - 股票数据

/// 统一的股票数据结构
struct StockData {
    let symbol: String
    let name: String
    let lastPrice: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let amount: Double
    let timestamp: Date
    
    // 盘口数据（可选，用于实时行情）
    let bidPrices: [Double]
    let bidVolumes: [Int64]
    let askPrices: [Double]
    let askVolumes: [Int64]
    
    /// 是否上涨
    var isUp: Bool { changePercent > 0 }
    
    /// 是否下跌
    var isDown: Bool { changePercent < 0 }
    
    /// 是否平盘
    var isFlat: Bool { changePercent == 0 }
    
    /// 格式化价格
    var formattedPrice: String {
        String(format: "%.2f", lastPrice)
    }
    
    /// 格式化涨跌幅
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
    
    /// 最佳买价
    var bestBid: Double? {
        bidPrices.first
    }
    
    /// 最佳卖价
    var bestAsk: Double? {
        askPrices.first
    }
    
    /// 买卖价差
    var spread: Double? {
        guard let bid = bestBid, let ask = bestAsk else { return nil }
        return ask - bid
    }
    
    // 便利初始化方法（不包含盘口数据）
    init(symbol: String, name: String, lastPrice: Double, change: Double, changePercent: Double, volume: Int64, amount: Double, timestamp: Date) {
        self.symbol = symbol
        self.name = name
        self.lastPrice = lastPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.timestamp = timestamp
        self.bidPrices = []
        self.bidVolumes = []
        self.askPrices = []
        self.askVolumes = []
    }
    
    // 完整初始化方法（包含盘口数据）
    init(symbol: String, name: String, lastPrice: Double, change: Double, changePercent: Double, volume: Int64, amount: Double, bidPrices: [Double], bidVolumes: [Int64], askPrices: [Double], askVolumes: [Int64], timestamp: Date) {
        self.symbol = symbol
        self.name = name
        self.lastPrice = lastPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.bidPrices = bidPrices
        self.bidVolumes = bidVolumes
        self.askPrices = askPrices
        self.askVolumes = askVolumes
        self.timestamp = timestamp
    }
}

// MARK: - K线数据

/// 统一的K线数据结构
struct KLineData {
    let symbol: String
    let timeframe: String
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let amount: Double
    
    /// 是否阳线
    var isBullish: Bool { close > open }
    
    /// 是否阴线
    var isBearish: Bool { close < open }
    
    /// 是否十字星
    var isDoji: Bool { abs(close - open) < (high - low) * 0.05 }
    
    /// 实体高度
    var bodyHeight: Double { abs(close - open) }
    
    /// 上影线长度
    var upperShadow: Double { high - max(open, close) }
    
    /// 下影线长度
    var lowerShadow: Double { min(open, close) - low }
    
    /// 格式化价格
    func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
    
    /// 格式化数量
    var formattedVolume: String {
        if volume >= 10000 {
            return String(format: "%.0f万", Double(volume) / 10000)
        } else {
            return "\(volume)"
        }
    }
}

// MARK: - 订单簿数据

/// 统一的订单簿数据结构
struct OrderBookData {
    let symbol: String
    let timestamp: Date
    let bidLevels: [OrderBookLevel]
    let askLevels: [OrderBookLevel]
    
    /// 最佳买价
    var bestBid: Double? {
        bidLevels.first?.price
    }
    
    /// 最佳卖价
    var bestAsk: Double? {
        askLevels.first?.price
    }
    
    /// 买卖价差
    var spread: Double? {
        guard let bid = bestBid, let ask = bestAsk else { return nil }
        return ask - bid
    }
}

/// 订单簿档位
struct OrderBookLevel {
    let level: Int
    let price: Double
    let volume: Int64
    
    /// 格式化价格
    var formattedPrice: String {
        String(format: "%.2f", price)
    }
    
    /// 格式化数量
    var formattedVolume: String {
        if volume >= 10000 {
            return String(format: "%.1f万", Double(volume) / 10000)
        } else {
            return "\(volume)"
        }
    }
}

// MARK: - 技术指标数据

/// 统一的技术指标数据结构
struct TechnicalIndicatorData {
    let symbol: String
    let timeframe: String
    let timestamp: Date
    let indicators: [String: Double]
    
    /// 获取指标值
    func getValue(for indicator: String) -> Double? {
        return indicators[indicator]
    }
    
    /// 获取格式化的指标值
    func getFormattedValue(for indicator: String, fractionDigits: Int = 2) -> String? {
        guard let value = getValue(for: indicator) else { return nil }
        return String(format: "%.\(fractionDigits)f", value)
    }
}

// MARK: - 交易信号

/// 统一的交易信号结构
struct TradingSignal {
    let id: String
    let symbol: String
    let signalType: SignalType
    let direction: SignalDirection
    let price: Double
    let confidence: Double
    let timestamp: Date
    let strategy: String?
    let message: String?
    
    enum SignalType: String, CaseIterable {
        case buy = "buy"
        case sell = "sell"
        case hold = "hold"
        
        var displayName: String {
            switch self {
            case .buy: return "买入"
            case .sell: return "卖出"
            case .hold: return "持有"
            }
        }
        
        var color: Color {
            switch self {
            case .buy: return .red
            case .sell: return .green
            case .hold: return .gray
            }
        }
    }
    
    enum SignalDirection: String, CaseIterable {
        case long = "long"
        case short = "short"
        case close = "close"
        
        var displayName: String {
            switch self {
            case .long: return "做多"
            case .short: return "做空"
            case .close: return "平仓"
            }
        }
    }
    
    /// 格式化置信度
    var formattedConfidence: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

// MARK: - 交易统计

/// 统一的交易统计结构
struct TradingStatistics {
    let totalTrades: Int
    let winTrades: Int
    let lossTrades: Int
    let totalPnL: Double
    let winRate: Double
    let avgWin: Double
    let avgLoss: Double
    let maxWin: Double
    let maxLoss: Double
    let profitFactor: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    
    /// 格式化胜率
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }
    
    /// 格式化总盈亏
    var formattedTotalPnL: String {
        let sign = totalPnL >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", totalPnL))"
    }
    
    /// 格式化夏普比率
    var formattedSharpeRatio: String {
        String(format: "%.2f", sharpeRatio)
    }
    
    /// 格式化最大回撤
    var formattedMaxDrawdown: String {
        String(format: "%.2f%%", maxDrawdown * 100)
    }
}

// MARK: - 时间序列数据点

/// 统一的时间序列数据点
struct TimeSeriesDataPoint {
    let timestamp: Date
    let value: Double
    let label: String?
    
    init(timestamp: Date, value: Double, label: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.label = label
    }
    
    /// 格式化时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: timestamp)
    }
    
    /// 格式化值
    var formattedValue: String {
        String(format: "%.2f", value)
    }
}

// MARK: - 风险评估

/// 统一的风险评估结构
struct RiskAssessment {
    let level: RiskLevel
    let score: Double
    let factors: [RiskFactor]
    let recommendations: [String]
    
    enum RiskLevel: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case veryHigh = "very_high"
        
        var displayName: String {
            switch self {
            case .low: return "低风险"
            case .medium: return "中等风险"
            case .high: return "高风险"
            case .veryHigh: return "极高风险"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            }
        }
    }
    
    struct RiskFactor {
        let name: String
        let value: Double
        let weight: Double
        let description: String
    }
    
    /// 格式化风险分数
    var formattedScore: String {
        String(format: "%.1f", score)
    }
}

// MARK: - 市场深度数据

/// 统一的市场深度数据
struct MarketDepthData {
    let symbol: String
    let timestamp: Date
    let bids: [MarketDepthLevel]
    let asks: [MarketDepthLevel]
    let totalBidVolume: Int64
    let totalAskVolume: Int64
    
    struct MarketDepthLevel {
        let price: Double
        let volume: Int64
        let orderCount: Int
        
        var formattedPrice: String {
            String(format: "%.2f", price)
        }
        
        var formattedVolume: String {
            if volume >= 10000 {
                return String(format: "%.0fK", Double(volume) / 1000)
            } else {
                return "\(volume)"
            }
        }
    }
    
    /// 计算加权平均价格
    func weightedAveragePrice(for side: String) -> Double {
        let levels = side == "bid" ? bids : asks
        let totalValue = levels.reduce(0) { $0 + $1.price * Double($1.volume) }
        let totalVolume = levels.reduce(0) { $0 + $1.volume }
        
        return totalVolume > 0 ? totalValue / Double(totalVolume) : 0
    }
}

// MARK: - 应用主题设置

/// 统一的应用主题设置
struct AppThemeSettings {
    var colorScheme: ColorScheme = .light
    var accentColor: Color = .blue
    var fontSize: FontSize = .medium
    var useSystemSettings: Bool = true
    
    enum FontSize: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        
        var scale: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            }
        }
        
        var displayName: String {
            switch self {
            case .small: return "小"
            case .medium: return "中"
            case .large: return "大"
            }
        }
    }
}

// MARK: - 错误信息

/// 统一的错误信息结构
struct AppError: Error, Identifiable {
    let id = UUID()
    let code: String
    let message: String
    let details: String?
    let timestamp: Date
    let severity: Severity
    
    enum Severity: String, CaseIterable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
        
        var displayName: String {
            switch self {
            case .info: return "信息"
            case .warning: return "警告"
            case .error: return "错误"
            case .critical: return "严重错误"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .orange
            case .critical: return .red
            }
        }
    }
    
    init(code: String, message: String, details: String? = nil, severity: Severity = .error) {
        self.code = code
        self.message = message
        self.details = details
        self.severity = severity
        self.timestamp = Date()
    }
}

// MARK: - 通知相关统一定义

/// 统一的静默时间设置
struct QuietHours: Codable {
    var enabled: Bool = false
    var startTime: String = "22:00"
    var endTime: String = "08:00"
}

// MARK: - 图表相关统一定义

/// 统一的技术指标类型
enum TechnicalIndicatorType: String, CaseIterable {
    case ma
    case ema
    case macd
    case rsi
    case bollinger
    case kdj
    
    var displayName: String {
        switch self {
        case .ma: return "移动平均线"
        case .ema: return "指数移动平均线"
        case .macd: return "MACD"
        case .rsi: return "RSI"
        case .bollinger: return "布林带"
        case .kdj: return "KDJ"
        }
    }
}

/// 统一的蜡烛图数据结构
struct CandlestickData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    /// 是否阳线
    var isBullish: Bool { close > open }
    
    /// 是否阴线
    var isBearish: Bool { close < open }
}

/// 统一的成交量数据结构
struct VolumeData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let volume: Double
    let isGreen: Bool
}
