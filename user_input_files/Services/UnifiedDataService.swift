//
// UnifiedDataService.swift
// 统一数据服务 - iOS端适配器
// 作者: MiniMax Agent
//

import Foundation
import CoreData

class UnifiedDataService: ObservableObject {
    static let shared = UnifiedDataService()
    
    private let networkService = NetworkService.shared
    private let persistenceController = PersistenceController.shared
    
    // MARK: - 统一数据同步
    
    /// 统一增量同步
    func performUnifiedIncrementalSync() async throws {
        let lastSyncTime = UserDefaults.standard.object(forKey: "lastUnifiedSyncTime") as? Date ?? Date.distantPast
        
        // 调用统一API
        let response = try await networkService.fetchUnifiedIncrementalData(since: lastSyncTime)
        
        // 处理统一格式数据
        await processUnifiedSyncResponse(response)
        
        // 更新同步时间
        UserDefaults.standard.set(Date(), forKey: "lastUnifiedSyncTime")
    }
    
    private func processUnifiedSyncResponse(_ response: [String: Any]) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            // 处理股票数据
            if let stocks = response["stocks"] as? [[String: Any]] {
                for stockData in stocks {
                    self.updateOrCreateUnifiedStock(from: stockData, in: context)
                }
            }
            
            // 处理K线数据
            if let klines = response["klines"] as? [[String: Any]] {
                for klineData in klines {
                    self.updateOrCreateUnifiedKLine(from: klineData, in: context)
                }
            }
            
            do {
                try context.save()
                logger.info("统一数据同步成功")
            } catch {
                logger.error("统一数据同步失败: \(error)")
            }
        }
    }
    
    // MARK: - 统一数据更新方法
    
    private func updateOrCreateUnifiedStock(from data: [String: Any], in context: NSManagedObjectContext) {
        guard let code = data["code"] as? String ?? data["symbol"] as? String else { return }
        
        let request: NSFetchRequest<UnifiedStockEntity> = UnifiedStockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "code == %@", code)
        
        do {
            let stocks = try context.fetch(request)
            let stock = stocks.first ?? UnifiedStockEntity(context: context)
            
            // 使用统一更新方法
            stock.updateBasicInfo(from: data)
            stock.updateFinancialData(from: data)
            stock.updatePriceData(from: data)
            
            // 更新盘口数据
            if let marketDepthData = data["market_depth"] as? [String: Any] {
                updateMarketDepthData(for: stock, from: marketDepthData, in: context)
            }
            
        } catch {
            logger.error("统一股票数据更新失败: \(error)")
        }
    }
    
    private func updateMarketDepthData(for stock: UnifiedStockEntity, from data: [String: Any], in context: NSManagedObjectContext) {
        // 清除旧的盘口数据
        if let oldDepths = stock.marketDepths?.allObjects as? [UnifiedMarketDepthEntity] {
            for depth in oldDepths {
                context.delete(depth)
            }
        }
        
        // 创建新的买盘数据
        if let bidLevels = data["bid_levels"] as? [[String: Any]] {
            for bidLevel in bidLevels {
                let depthEntity = UnifiedMarketDepthEntity(context: context)
                depthEntity.stock = stock
                depthEntity.side = "bid"
                
                if let level = bidLevel["level"] as? Int32 {
                    depthEntity.level = level
                }
                if let priceStr = bidLevel["price"] as? String {
                    depthEntity.price = NSDecimalNumber.fromString(priceStr)
                }
                if let volume = bidLevel["volume"] as? Int64 {
                    depthEntity.volume = volume
                }
                depthEntity.timestamp = Date()
            }
        }
        
        // 创建新的卖盘数据
        if let askLevels = data["ask_levels"] as? [[String: Any]] {
            for askLevel in askLevels {
                let depthEntity = UnifiedMarketDepthEntity(context: context)
                depthEntity.stock = stock
                depthEntity.side = "ask"
                
                if let level = askLevel["level"] as? Int32 {
                    depthEntity.level = level
                }
                if let priceStr = askLevel["price"] as? String {
                    depthEntity.price = NSDecimalNumber.fromString(priceStr)
                }
                if let volume = askLevel["volume"] as? Int64 {
                    depthEntity.volume = volume
                }
                depthEntity.timestamp = Date()
            }
        }
    }
    
    // MARK: - 向后兼容方法
    
    /// 获取传统格式的股票数据（向后兼容）
    func getLegacyStockData(symbol: String) -> [String: Any]? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UnifiedStockEntity> = UnifiedStockEntity.fetchRequest()
        request.predicate = NSPredicate(format: "code == %@", symbol)
        
        do {
            if let stock = try context.fetch(request).first {
                // 转换为传统iOS格式
                return [
                    "symbol": stock.symbol,
                    "name": stock.name,
                    "lastPrice": stock.lastPrice.doubleValue,  // 向后兼容Double
                    "change": stock.change.doubleValue,
                    "changePercent": stock.changePercent.doubleValue,
                    "volume": stock.volume.int64Value,
                    "amount": stock.amount.doubleValue,
                    "timestamp": stock.timestamp,
                    // 传统JSON字符串格式盘口数据
                    "bidPrices": stock.marketDepthData["bidPrices"] as? [String] ?? [],
                    "bidVolumes": stock.marketDepthData["bidVolumes"] as? [Int64] ?? []
                ]
            }
        } catch {
            logger.error("获取传统格式股票数据失败: \(error)")
        }
        
        return nil
    }
}

private let logger = Logger(subsystem: "TradingSystem", category: "UnifiedData")
