/*
 PositionEntity Core Data类扩展
 持仓信息实体类
 作者: MiniMax Agent
 创建时间: 2025-06-24 15:23:57
 */

import Foundation
import CoreData

@objc(PositionEntity)
public class PositionEntity: NSManagedObject {
    
    // MARK: - 便利属性
    
    /// 是否持仓
    var hasPosition: Bool {
        return quantity != 0
    }
    
    /// 是否多头持仓
    var isLongPosition: Bool {
        return quantity > 0
    }
    
    /// 是否空头持仓
    var isShortPosition: Bool {
        return quantity < 0
    }
    
    /// 绝对持仓数量
    var absoluteQuantity: Int32 {
        return abs(quantity)
    }
    
    /// 是否盈利
    var isProfitable: Bool {
        return pnl > 0
    }
    
    /// 是否亏损
    var isLoss: Bool {
        return pnl < 0
    }
    
    /// 持仓成本 - 使用高精度计算
    var totalCost: NSDecimalNumber {
        let avgCostDecimal = self.avgCost as? NSDecimalNumber ?? NSDecimalNumber.zero
        let quantityDecimal = NSDecimalNumber(value: absoluteQuantity)
        return avgCostDecimal.multiplying(by: quantityDecimal)
    }
    
    /// 浮动盈亏金额 - 使用高精度计算
    var unrealizedPnl: NSDecimalNumber {
        let currentPriceDecimal = self.currentPrice as? NSDecimalNumber ?? NSDecimalNumber.zero
        let avgCostDecimal = self.avgCost as? NSDecimalNumber ?? NSDecimalNumber.zero
        let quantityDecimal = NSDecimalNumber(value: self.quantity)
        
        let priceDiff = currentPriceDecimal.subtracting(avgCostDecimal)
        return priceDiff.multiplying(by: quantityDecimal)
    }
    
    /// 浮动盈亏率 - 使用高精度计算
    var unrealizedPnlPercent: NSDecimalNumber {
        let avgCostDecimal = self.avgCost as? NSDecimalNumber ?? NSDecimalNumber.zero
        guard avgCostDecimal.compare(NSDecimalNumber.zero) == .orderedDescending else { 
            return NSDecimalNumber.zero 
        }
        
        let currentPriceDecimal = self.currentPrice as? NSDecimalNumber ?? NSDecimalNumber.zero
        let priceDiff = currentPriceDecimal.subtracting(avgCostDecimal)
        let rate = priceDiff.dividing(by: avgCostDecimal)
        let hundred = NSDecimalNumber(value: 100)
        return rate.multiplying(by: hundred)
    }
    
    // MARK: - 格式化方法
    
    /// 格式化持仓数量
    var formattedQuantity: String {
        let sign = quantity >= 0 ? "" : "-"
        return "\(sign)\(absoluteQuantity)"
    }
    
    /// 格式化平均成本
    var formattedAvgCost: String {
        let avgCostDecimal = self.avgCost as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(avgCostDecimal, fractionDigits: 2)
    }
    
    /// 格式化当前价格
    var formattedCurrentPrice: String {
        let currentPriceDecimal = self.currentPrice as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(currentPriceDecimal, fractionDigits: 2)
    }
    
    /// 格式化市值
    var formattedMarketValue: String {
        let marketValueDecimal = self.marketValue as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(marketValueDecimal, fractionDigits: 2)
    }
    
    /// 格式化盈亏
    var formattedPnl: String {
        let pnlDecimal = self.pnl as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(pnlDecimal, fractionDigits: 2, showSign: true)
    }
    
    /// 格式化盈亏率
    var formattedPnlPercent: String {
        let pnlPercentDecimal = self.pnlPercent as? NSDecimalNumber ?? NSDecimalNumber.zero
        return formatDecimal(pnlPercentDecimal, fractionDigits: 2, showSign: true, suffix: "%")
    }
    
    /// 格式化浮动盈亏
    var formattedUnrealizedPnl: String {
        return formatDecimal(unrealizedPnl, fractionDigits: 2, showSign: true)
    }
    
    /// 格式化浮动盈亏率
    var formattedUnrealizedPnlPercent: String {
        return formatDecimal(unrealizedPnlPercent, fractionDigits: 2, showSign: true, suffix: "%")
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
    
    /// 格式化更新时间
    var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: lastUpdate)
    }
    
    // MARK: - 便利方法
    
    /// 更新持仓信息 - 使用高精度计算
    func updatePosition(
        quantity: Int32,
        avgCost: NSDecimalNumber,
        currentPrice: NSDecimalNumber
    ) {
        self.quantity = quantity
        self.avgCost = avgCost
        self.currentPrice = currentPrice
        
        // 重新计算衍生字段
        let quantityDecimal = NSDecimalNumber(value: quantity)
        self.marketValue = currentPrice.multiplying(by: quantityDecimal)
        self.pnl = unrealizedPnl
        self.pnlPercent = unrealizedPnlPercent
        self.lastUpdate = Date()
    }
    
    /// 更新当前价格 - 使用高精度计算
    func updateCurrentPrice(_ price: NSDecimalNumber) {
        self.currentPrice = price
        let quantityDecimal = NSDecimalNumber(value: quantity)
        self.marketValue = price.multiplying(by: quantityDecimal)
        self.pnl = unrealizedPnl
        self.pnlPercent = unrealizedPnlPercent
        self.lastUpdate = Date()
    }
    
    /// 加仓操作 - 使用高精度计算
    func addPosition(quantity addQuantity: Int32, price: NSDecimalNumber) {
        let currentQuantityDecimal = NSDecimalNumber(value: self.quantity)
        let addQuantityDecimal = NSDecimalNumber(value: addQuantity)
        let currentAvgCostDecimal = self.avgCost as? NSDecimalNumber ?? NSDecimalNumber.zero
        
        let newTotalQuantity = currentQuantityDecimal.adding(addQuantityDecimal)
        
        // 计算新的平均成本
        let currentTotalCost = currentQuantityDecimal.multiplying(by: currentAvgCostDecimal)
        let addedCost = addQuantityDecimal.multiplying(by: price)
        let newTotalCost = currentTotalCost.adding(addedCost)
        
        if newTotalQuantity.compare(NSDecimalNumber.zero) != .orderedSame {
            let newAvgCost = newTotalCost.dividing(by: newTotalQuantity)
            
            self.quantity = newTotalQuantity.int32Value
            self.avgCost = newAvgCost
            self.lastUpdate = Date()
            
            // 重新计算衍生字段
            updateDerivedFields()
        }
    }
    
    /// 减仓操作 - 安全处理
    func reducePosition(quantity reduceQuantity: Int32) {
        guard self.quantity != 0 else { return }
        
        let newQuantity = self.quantity - reduceQuantity
        self.quantity = max(0, newQuantity) // 不允许数量为负
        self.lastUpdate = Date()
        
        // 重新计算衍生字段
        updateDerivedFields()
    }
    
    /// 平仓操作
    func closePosition() {
        self.quantity = 0
        self.marketValue = NSDecimalNumber.zero
        self.pnl = NSDecimalNumber.zero
        self.pnlPercent = NSDecimalNumber.zero
        self.lastUpdate = Date()
    }
    
    /// 更新衍生字段
    private func updateDerivedFields() {
        let currentPriceDecimal = self.currentPrice as? NSDecimalNumber ?? NSDecimalNumber.zero
        let quantityDecimal = NSDecimalNumber(value: self.quantity)
        
        self.marketValue = currentPriceDecimal.multiplying(by: quantityDecimal)
        self.pnl = unrealizedPnl
        self.pnlPercent = unrealizedPnlPercent
    }
    
    /// 持仓状态描述
    var positionStatus: String {
        if !hasPosition {
            return "无持仓"
        } else if isLongPosition {
            return "多头持仓"
        } else {
            return "空头持仓"
        }
    }
    
    /// 风险等级
    var riskLevel: RiskLevel {
        let riskPercent = abs(pnlPercent)
        
        if riskPercent < 2 {
            return .low
        } else if riskPercent < 5 {
            return .medium
        } else if riskPercent < 10 {
            return .high
        } else {
            return .veryHigh
        }
    }
    
    // RiskLevel 已移至 SharedModels.swift 统一管理
    
    // MARK: - 查询方法
    
    /// 获取所有持仓
    static func fetchAllPositions(in context: NSManagedObjectContext) -> [PositionEntity] {
        let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "quantity != 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PositionEntity.marketValue, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取持仓数据失败: \(error)")
            return []
        }
    }
    
    /// 获取盈利持仓
    static func fetchProfitablePositions(in context: NSManagedObjectContext) -> [PositionEntity] {
        let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "quantity != 0 AND pnl > 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PositionEntity.pnl, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取盈利持仓失败: \(error)")
            return []
        }
    }
    
    /// 获取亏损持仓
    static func fetchLossPositions(in context: NSManagedObjectContext) -> [PositionEntity] {
        let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "quantity != 0 AND pnl < 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PositionEntity.pnl, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("获取亏损持仓失败: \(error)")
            return []
        }
    }
    
    /// 计算总市值
    static func totalMarketValue(in context: NSManagedObjectContext) -> Double {
        let positions = fetchAllPositions(in: context)
        return positions.reduce(0) { $0 + $1.marketValue }
    }
    
    /// 计算总盈亏
    static func totalPnl(in context: NSManagedObjectContext) -> Double {
        let positions = fetchAllPositions(in: context)
        return positions.reduce(0) { $0 + $1.pnl }
    }
}

// MARK: - Identifiable
extension PositionEntity: Identifiable {
    public var id: String { symbol }
}
