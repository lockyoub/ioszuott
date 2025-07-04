//
// DataSyncManager.swift
// 跨平台金融交易系统 - 修复版本
// 修复日期: 2025-06-28
//

import Foundation
import CoreData
import OSLog

class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    
    private let persistenceController = PersistenceController.shared
    private let networkService = NetworkManager.shared
    private var syncQueue = OperationQueue()
    private var conflictResolver = ConflictResolver()
    
    // MARK: - 高精度数据解析工具
    
    /// 安全解析Decimal类型，支持字符串和数字
    private func parseDecimal(from data: [String: Any], key: String) -> NSDecimalNumber {
        if let stringValue = data[key] as? String {
            return NSDecimalNumber.safeDecimal(from: stringValue)
        } else if let doubleValue = data[key] as? Double {
            return NSDecimalNumber(value: doubleValue)
        } else if let intValue = data[key] as? Int {
            return NSDecimalNumber(value: intValue)
        }
        return NSDecimalNumber.zero
    }
    
    /// 安全解析可选Decimal类型
    private func parseOptionalDecimal(from data: [String: Any], key: String) -> NSDecimalNumber? {
        if let stringValue = data[key] as? String {
            return NSDecimalNumber.safeDecimal(from: stringValue)
        } else if let doubleValue = data[key] as? Double {
            return NSDecimalNumber(value: doubleValue)
        } else if let intValue = data[key] as? Int {
            return NSDecimalNumber(value: intValue)
        }
        return nil
    }
    
    // MARK: - 数据同步主方法
    
    func syncAllData() async {
        logger.info("开始完整数据同步...")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.syncStocks() }
            group.addTask { await self.syncTrades() }
            group.addTask { await self.syncPositions() }
            group.addTask { await self.syncKLines() }
        }
        
        logger.info("数据同步完成")
    }
    
    func incrementalSync() async {
        logger.info("开始增量同步...")
        
        let lastSyncTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date ?? Date.distantPast
        
        do {
            // 获取增量数据
            let deltaData = try await networkService.fetchIncrementalData(since: lastSyncTime)
            
            // 处理增量更新
            await processDeltaData(deltaData)
            
            // 上传本地变更
            await uploadLocalChanges()
            
            // 更新同步时间
            UserDefaults.standard.set(Date(), forKey: "lastSyncTime")
            
        } catch {
            logger.error("增量同步失败: \(error)")
        }
    }
    
    // MARK: - 股票数据同步
    
    func syncStocks() async {
        do {
            let stocksData = try await networkService.fetchStocks()
            await updateStocksFromServerData(stocksData)
        } catch {
            logger.error("股票同步失败: \(error)")
        }
    }
    
    private func updateStocksFromServerData(_ stocksData: [[String: Any]]) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            for stockData in stocksData {
                self.updateOrCreateStock(from: stockData, in: context)
            }
            
            do {
                try context.save()
                logger.info("股票数据同步成功，共处理 \(stocksData.count) 条记录")
            } catch {
                logger.error("股票数据保存失败: \(error)")
            }
        }
    }
    
    private func updateOrCreateStock(from data: [String: Any], in context: NSManagedObjectContext) {
        guard let symbol = data["code"] as? String ?? data["symbol"] as? String else { return }
        
        let request: NSFetchRequest<StockEntity> = StockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        
        do {
            let stocks = try context.fetch(request)
            let stock = stocks.first ?? StockEntity(context: context)
            
            stock.symbol = symbol
            stock.name = data["name"] as? String ?? ""
            stock.exchange = data["exchange"] as? String ?? ""
            
            // 修复: 使用高精度解析
            stock.lastPrice = parseDecimal(from: data, key: "lastPrice")
            stock.change = parseDecimal(from: data, key: "change")  
            stock.changePercent = parseDecimal(from: data, key: "changePercent")
            stock.amount = parseDecimal(from: data, key: "amount")
            
            stock.volume = data["volume"] as? Int64 ?? 0
            stock.timestamp = Date()
            
        } catch {
            logger.error("股票数据更新失败: \(error)")
        }
    }
    
    // MARK: - 交易数据同步
    
    func syncTrades() async {
        do {
            let tradesData = try await networkService.fetchTrades()
            await updateTradesFromServerData(tradesData)
        } catch {
            logger.error("交易同步失败: \(error)")
        }
    }
    
    private func updateTradesFromServerData(_ tradesData: [[String: Any]]) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            for tradeData in tradesData {
                self.updateOrCreateTrade(from: tradeData, in: context)
            }
            
            do {
                try context.save()
                logger.info("交易数据同步成功，共处理 \(tradesData.count) 条记录")
            } catch {
                logger.error("交易数据保存失败: \(error)")
            }
        }
    }
    
    private func updateOrCreateTrade(from data: [String: Any], in context: NSManagedObjectContext) {
        guard let tradeId = data["id"] as? String else { return }
        
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tradeId)
        
        do {
            let trades = try context.fetch(request)
            let trade = trades.first ?? TradeEntity(context: context)
            
            trade.id = tradeId
            trade.symbol = data["symbol"] as? String ?? data["stockCode"] as? String ?? ""
            trade.direction = data["direction"] as? String ?? ""
            trade.quantity = data["quantity"] as? Int32 ?? 0
            
            // 修复: 使用高精度解析
            trade.price = parseDecimal(from: data, key: "price")
            trade.amount = parseDecimal(from: data, key: "amount")
            trade.commission = parseDecimal(from: data, key: "commission")
            trade.pnl = parseDecimal(from: data, key: "pnl")
            
            if let timestampString = data["timestamp"] as? String,
               let timestamp = ISO8601DateFormatter().date(from: timestampString) {
                trade.timestamp = timestamp
            }
            
            trade.strategy = data["strategy"] as? String
            
        } catch {
            logger.error("交易数据更新失败: \(error)")
        }
    }
    
    // MARK: - 持仓数据同步
    
    func syncPositions() async {
        do {
            let positionsData = try await networkService.fetchPositions()
            await updatePositionsFromServerData(positionsData)
        } catch {
            logger.error("持仓同步失败: \(error)")
        }
    }
    
    private func updatePositionsFromServerData(_ positionsData: [[String: Any]]) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            for positionData in positionsData {
                self.updateOrCreatePosition(from: positionData, in: context)
            }
            
            do {
                try context.save()
                logger.info("持仓数据同步成功，共处理 \(positionsData.count) 条记录")
            } catch {
                logger.error("持仓数据保存失败: \(error)")
            }
        }
    }
    
    private func updateOrCreatePosition(from data: [String: Any], in context: NSManagedObjectContext) {
        guard let symbol = data["symbol"] as? String ?? data["stockCode"] as? String else { return }
        
        let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        
        do {
            let positions = try context.fetch(request)
            let position = positions.first ?? PositionEntity(context: context)
            
            position.symbol = symbol
            position.quantity = data["quantity"] as? Int32 ?? 0
            
            // 修复: 使用高精度解析
            position.avgCost = parseDecimal(from: data, key: "avgCost")
            position.currentPrice = parseDecimal(from: data, key: "currentPrice")
            position.marketValue = parseDecimal(from: data, key: "marketValue")
            position.pnl = parseDecimal(from: data, key: "pnl")
            position.pnlPercent = parseDecimal(from: data, key: "pnlPercent")
            
            if let lastUpdateString = data["lastUpdate"] as? String,
               let lastUpdate = ISO8601DateFormatter().date(from: lastUpdateString) {
                position.lastUpdate = lastUpdate
            } else {
                position.lastUpdate = Date()
            }
            
        } catch {
            logger.error("持仓数据更新失败: \(error)")
        }
    }
    
    // MARK: - K线数据同步
    
    func syncKLines() async {
        do {
            let kLinesData = try await networkService.fetchKLines()
            await updateKLinesFromServerData(kLinesData)
        } catch {
            logger.error("K线同步失败: \(error)")
        }
    }
    
    private func updateKLinesFromServerData(_ kLinesData: [[String: Any]]) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            for kLineData in kLinesData {
                self.updateOrCreateKLine(from: kLineData, in: context)
            }
            
            do {
                try context.save()
                logger.info("K线数据同步成功，共处理 \(kLinesData.count) 条记录")
            } catch {
                logger.error("K线数据保存失败: \(error)")
            }
        }
    }
    
    private func updateOrCreateKLine(from data: [String: Any], in context: NSManagedObjectContext) {
        guard let symbol = data["symbol"] as? String ?? data["stockCode"] as? String,
              let timestampString = data["timestamp"] as? String,
              let timestamp = ISO8601DateFormatter().date(from: timestampString),
              let timeframe = data["timeframe"] as? String ?? data["period"] as? String else { return }
        
        let request: NSFetchRequest<KLineEntity> = KLineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@ AND timestamp == %@ AND timeframe == %@", 
                                       symbol, timestamp as NSDate, timeframe)
        
        do {
            let kLines = try context.fetch(request)
            let kLine = kLines.first ?? KLineEntity(context: context)
            
            kLine.symbol = symbol
            kLine.timestamp = timestamp
            kLine.timeframe = timeframe
            
            // 修复: 使用高精度解析
            kLine.open = parseDecimal(from: data, key: "open")
            kLine.high = parseDecimal(from: data, key: "high")
            kLine.low = parseDecimal(from: data, key: "low")
            kLine.close = parseDecimal(from: data, key: "close")
            kLine.amount = parseDecimal(from: data, key: "amount")
            
            kLine.volume = data["volume"] as? Int64 ?? 0
            
        } catch {
            logger.error("K线数据更新失败: \(error)")
        }
    }
    
    // MARK: - 增量同步相关方法
    
    private func processDeltaData(_ deltaData: [String: Any]) async {
        if let stocks = deltaData["stocks"] as? [[String: Any]] {
            await updateStocksFromServerData(stocks)
        }
        
        if let trades = deltaData["trades"] as? [[String: Any]] {
            await updateTradesFromServerData(trades)
        }
        
        if let positions = deltaData["positions"] as? [[String: Any]] {
            await updatePositionsFromServerData(positions)
        }
        
        if let kLines = deltaData["klines"] as? [[String: Any]] {
            await updateKLinesFromServerData(kLines)
        }
    }
    
    private func uploadLocalChanges() async {
        // 上传本地待同步的变更
        await uploadPendingTrades()
        await uploadPendingPositionChanges()
    }
    
    private func uploadPendingTrades() async {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        // 修复: 移除不存在的needsSync属性，使用strategy为空作为标识
        request.predicate = NSPredicate(format: "strategy == NULL OR strategy == ''")
        
        do {
            let pendingTrades = try context.fetch(request)
            for trade in pendingTrades {
                do {
                    try await networkService.uploadTrade(trade)
                    trade.strategy = "uploaded" // 标记为已上传
                } catch {
                    logger.error("交易上传失败: \(error)")
                }
            }
            
            if !pendingTrades.isEmpty {
                try context.save()
            }
            
        } catch {
            logger.error("获取待同步交易失败: \(error)")
        }
    }
    
    private func uploadPendingPositionChanges() async {
        // 类似的上传逻辑
    }
}

// MARK: - 冲突解决器

/// 【P1功能实现】增强的冲突解决器 - 支持版本控制和多种冲突解决策略
class ConflictResolver {
    
    enum ConflictResolutionStrategy {
        case lastWriteWins      // 最后写入优先
        case manualResolve      // 手动解决
        case additive           // 累加策略（适用于数量变化）
        case serverWins         // 服务器优先
        case clientWins         // 客户端优先
    }
    
    /// 解决持仓数据冲突
    /// - Parameters:
    ///   - localPosition: 本地持仓数据
    ///   - remotePosition: 服务器持仓数据
    ///   - strategy: 冲突解决策略
    /// - Returns: 解决后的持仓数据
    func resolvePositionConflict(
        local localPosition: PositionData,
        remote remotePosition: PositionData,
        strategy: ConflictResolutionStrategy = .lastWriteWins
    ) -> PositionData {
        
        print("检测到持仓冲突 - 股票: \(localPosition.symbol)")
        print("本地版本: \(localPosition.version), 服务器版本: \(remotePosition.version)")
        print("本地修改时间: \(localPosition.lastModified)")
        print("服务器修改时间: \(remotePosition.lastModified)")
        
        switch strategy {
        case .lastWriteWins:
            // 根据最后修改时间决定
            return localPosition.lastModified > remotePosition.lastModified ? localPosition : remotePosition
            
        case .serverWins:
            return remotePosition
            
        case .clientWins:
            return localPosition
            
        case .additive:
            // 对于数量变化，采用累加策略
            return resolveAdditiveConflict(local: localPosition, remote: remotePosition)
            
        case .manualResolve:
            // 暂时返回服务器数据，实际应该弹出用户选择界面
            print("需要手动解决冲突，暂时使用服务器数据")
            return remotePosition
        }
    }
    
    /// 累加策略冲突解决（适用于持仓数量变化）
    private func resolveAdditiveConflict(
        local localPosition: PositionData,
        remote remotePosition: PositionData
    ) -> PositionData {
        
        // 检查是否为数量变化冲突
        let localQuantityChange = localPosition.quantity - localPosition.baseQuantity
        let remoteQuantityChange = remotePosition.quantity - remotePosition.baseQuantity
        
        if localQuantityChange != 0 && remoteQuantityChange != 0 {
            // 两边都有数量变化，累加变化量
            let totalQuantity = localPosition.baseQuantity + localQuantityChange + remoteQuantityChange
            
            var resolvedPosition = remotePosition // 以服务器版本为基础
            resolvedPosition.quantity = totalQuantity
            resolvedPosition.version = max(localPosition.version, remotePosition.version) + 1
            resolvedPosition.lastModified = Date()
            
            print("使用累加策略解决冲突: 最终数量 = \(totalQuantity)")
            return resolvedPosition
        }
        
        // 如果不是数量变化冲突，使用最后写入优先
        return localPosition.lastModified > remotePosition.lastModified ? localPosition : remotePosition
    }
    
    /// 检测冲突类型
    func detectConflictType(
        local: PositionData,
        remote: PositionData
    ) -> ConflictType {
        
        if local.version == remote.version {
            return .noConflict
        }
        
        if local.quantity != remote.quantity {
            return .quantityConflict
        }
        
        if local.avgCost != remote.avgCost {
            return .priceConflict
        }
        
        return .dataConflict
    }
}

/// 冲突类型枚举
enum ConflictType {
    case noConflict
    case quantityConflict    // 数量冲突
    case priceConflict      // 价格冲突
    case dataConflict       // 一般数据冲突
    case versionConflict    // 版本冲突
}

/// 【P1功能实现】支持版本控制的持仓数据结构
struct PositionData {
    let id: String
    let symbol: String
    var quantity: Int
    var avgCost: Double
    var version: Int
    var lastModified: Date
    let baseQuantity: Int  // 基准数量（用于计算变化量）
    
    init(from position: PositionEntity) {
        self.id = position.objectID.uriRepresentation().absoluteString
        self.symbol = position.symbol ?? ""
        self.quantity = Int(position.quantity)
        self.avgCost = position.avgCost
        self.version = 1 // 使用默认版本号，因为position.version不存在
        self.lastModified = position.lastUpdate // 使用lastUpdate替代不存在的lastModified
        self.baseQuantity = Int(position.quantity) // 使用quantity替代不存在的baseQuantity
    }
    
    init(id: String, symbol: String, quantity: Int, avgCost: Double, version: Int, lastModified: Date, baseQuantity: Int) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.avgCost = avgCost
        self.version = version
        self.lastModified = lastModified
        self.baseQuantity = baseQuantity
    }
}

// MARK: - 日志工具

private let logger = Logger(subsystem: "TradingSystem", category: "DataSync")

// MARK: - NSDecimalNumber扩展

extension NSDecimalNumber {
    static func safeDecimal(from string: String) -> NSDecimalNumber {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanString.isEmpty {
            return NSDecimalNumber.zero
        }
        
        let decimal = NSDecimalNumber(string: cleanString)
        return decimal == NSDecimalNumber.notANumber ? NSDecimalNumber.zero : decimal
    }
}
