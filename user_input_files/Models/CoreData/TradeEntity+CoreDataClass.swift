/*
 TradeEntity Core Data类扩展
 交易记录实体类
 作者: MiniMax Agent
 创建时间: 2025-06-24 15:23:57
 */

import Foundation
import CoreData

@objc(TradeEntity)
public class TradeEntity: NSManagedObject {
    
    // MARK: - 枚举定义
    
    /// 交易方向
    enum Direction: String, CaseIterable {
        case buy = "buy"
        case sell = "sell"
        
        var displayName: String {
            switch self {
            case .buy: return "买入"
            case .sell: return "卖出"
            }
        }
        
        var color: String {
            switch self {
            case .buy: return "red"
            case .sell: return "green"
            }
        }
    }
    
    // MARK: - 便利属性
    
    /// 交易方向类型
    var directionType: Direction? {
        return Direction(rawValue: direction)
    }
    
    /// 是否买入
    var isBuy: Bool {
        return direction == Direction.buy.rawValue
    }
    
    /// 是否卖出
    var isSell: Bool {
        return direction == Direction.sell.rawValue
    }
    
    /// 净收益（扣除手续费）- 使用高精度计算
    var netPnl: NSDecimalNumber {
        let pnlDecimal = self.pnl as? NSDecimalNumber ?? NSDecimalNumber.zero
        let commissionDecimal = self.commission as? NSDecimalNumber ?? NSDecimalNumber.zero
        return pnlDecimal.subtracting(commissionDecimal)
    }
    
    /// 成交金额（含手续费）- 使用高精度计算
    var totalAmount: NSDecimalNumber {
        let amountDecimal = self.amount as? NSDecimalNumber ?? NSDecimalNumber.zero
        let commissionDecimal = self.commission as? NSDecimalNumber ?? NSDecimalNumber.zero
        return amountDecimal.adding(commissionDecimal)
    }
    
    /// 收益率 - 使用高精度计算
    var returnRate: NSDecimalNumber {
        let amountDecimal = self.amount as? NSDecimalNumber ?? NSDecimalNumber.zero
        guard amountDecimal.compare(NSDecimalNumber.zero) == .orderedDescending else { 
            return NSDecimalNumber.zero 
        }
        
        let netPnlDecimal = netPnl
        let rate = netPnlDecimal.dividing(by: amountDecimal)
        let hundred = NSDecimalNumber(value: 100)
        return rate.multiplying(by: hundred)
    }
    
    // MARK: - 格式化方法
    
    /// 格式化交易金额
    var formattedAmount: String {
        let amountDecimal = self.amount as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(amountDecimal, fractionDigits: 2)
    }
    
    /// 格式化成交价格
    var formattedPrice: String {
        let priceDecimal = self.price as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(priceDecimal, fractionDigits: 2)
    }
    
    /// 格式化盈亏
    var formattedPnl: String {
        let pnlDecimal = self.pnl as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(pnlDecimal, fractionDigits: 2, showSign: true)
    }
    
    /// 格式化净盈亏
    var formattedNetPnl: String {
        return formatDecimal(netPnl, fractionDigits: 2, showSign: true)
    }
    
    /// 格式化手续费
    var formattedCommission: String {
        let commissionDecimal = self.commission as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(commissionDecimal, fractionDigits: 2)
    }
    
    /// 格式化收益率
    var formattedReturnRate: String {
        return formatDecimal(returnRate, fractionDigits: 2, showSign: true, suffix: "%")
    }
    
    // MARK: - 私有格式化辅助方法
    private func formatDecimal(_ decimal: NSDecimalNumber, 
                              fractionDigits: Int = 2, 
                              showSign: Bool = false,
                              suffix: String = "") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        
        if showSign {
            formatter.positivePrefix = "+"
        }
        
        let result = formatter.string(from: decimal) ?? "0.00"
        return result + suffix
    }
    
    /// 格式化交易时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    /// 格式化交易日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
    
    // MARK: - 便利方法
    
    /// 更新盈亏信息
    func updatePnl(_ newPnl: Double) {
        self.pnl = newPnl
    }
    
    /// 设置交易策略
    func setStrategy(_ strategyName: String?) {
        self.strategy = strategyName
    }
    
    /// 是否盈利
    var isProfitable: Bool {
        return netPnl > 0
    }
    
    /// 是否亏损
    var isLoss: Bool {
        return netPnl < 0
    }
    
    /// 是否保本
    var isBreakEven: Bool {
        return netPnl == 0
    }
    
    /// 交易描述
    var tradeDescription: String {
        let directionName = directionType?.displayName ?? direction
        return "\(directionName) \(quantity)股 @\(formattedPrice)"
    }
    
    /// 完整描述
    var fullDescription: String {
        return "\(formattedTime) \(tradeDescription) 盈亏:\(formattedNetPnl)"
    }
    
    // MARK: - 查询方法
    
    /// 根据日期范围获取交易记录
    static func fetchTrades(
        from startDate: Date,
        to endDate: Date,
        in context: NSManagedObjectContext
    ) -> [TradeEntity] {
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TradeEntity.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取交易记录失败: \(error)")
            return []
        }
    }
    
    /// 根据股票代码获取交易记录
    static func fetchTrades(
        for symbol: String,
        in context: NSManagedObjectContext
    ) -> [TradeEntity] {
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TradeEntity.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取股票交易记录失败: \(error)")
            return []
        }
    }
    
    /// 根据策略获取交易记录
    static func fetchTrades(
        for strategy: String,
        in context: NSManagedObjectContext
    ) -> [TradeEntity] {
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "strategy == %@", strategy)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TradeEntity.timestamp, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取策略交易记录失败: \(error)")
            return []
        }
    }
}

// MARK: - Identifiable
extension TradeEntity: Identifiable {
    // id属性已在Core Data模型中定义
}
