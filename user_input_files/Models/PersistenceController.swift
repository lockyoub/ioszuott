/*
 Core Data持久化控制器
 作者: MiniMax Agent
 */

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建预览数据
        createPreviewData(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("预览数据创建失败: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TradingDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 配置持久化存储
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // --- 关键修复：启用自动轻量级迁移 ---
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            
            // --- 关键修复P0-4：为Core Data文件添加加密保护 ---
            // 设置文件保护级别为完整保护，设备锁定时数据不可访问
            storeDescription.setOption(FileProtectionType.complete as NSObject, 
                                     forKey: NSPersistentStoreFileProtectionKey)
            
            // 可选：启用WAL模式以提高性能和安全性
            storeDescription.setOption("WAL" as NSObject, forKey: "journal_mode")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data迁移或加载失败: \(error), \(error.userInfo)")
                
                // 如果是迁移错误，可以考虑重置数据库（谨慎使用）
                if error.code == NSPersistentStoreIncompatibleVersionHashError ||
                   error.code == NSMigrationMissingSourceModelError {
                    print("数据库版本不兼容，需要手动处理迁移")
                    // 在生产环境中，应该提供用户选择：备份数据或重置
                    fatalError("数据库迁移失败，请联系技术支持")
                } else {
                    fatalError("Core Data加载失败: \(error), \(error.userInfo)")
                }
            } else {
                print("Core Data迁移和加载成功完成")
            }
        })
        
        // 配置视图上下文
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// 保存上下文
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// 创建后台上下文
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// 批量删除实体
    func batchDelete<T: NSManagedObject>(_ entity: T.Type) throws {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}

// MARK: - 预览数据创建
extension PersistenceController {
    static func createPreviewData(in context: NSManagedObjectContext) {
        // 创建样本股票数据 - 使用NSDecimalNumber
        let sampleStock = StockEntity(context: context)
        sampleStock.symbol = "000001.SZ"
        sampleStock.name = "平安银行"
        sampleStock.exchange = "SZ"
        sampleStock.lastPrice = NSDecimalNumber(string: "12.50")
        sampleStock.change = NSDecimalNumber(string: "0.28")
        sampleStock.changePercent = NSDecimalNumber(string: "2.35")
        sampleStock.volume = 1000000
        sampleStock.amount = NSDecimalNumber(string: "12500000.00")
        sampleStock.timestamp = Date()
        
        // 创建样本K线数据 - 使用NSDecimalNumber
        let sampleKLine = KLineEntity(context: context)
        sampleKLine.symbol = "000001.SZ"
        sampleKLine.timeframe = "1m"
        sampleKLine.timestamp = Date()
        sampleKLine.open = NSDecimalNumber(string: "12.30")
        sampleKLine.high = NSDecimalNumber(string: "12.55")
        sampleKLine.low = NSDecimalNumber(string: "12.25")
        sampleKLine.close = NSDecimalNumber(string: "12.50")
        sampleKLine.volume = 50000
        sampleKLine.amount = NSDecimalNumber(string: "620000.00")
        
        // 创建样本交易记录 - 使用NSDecimalNumber
        let sampleTrade = TradeEntity(context: context)
        sampleTrade.id = UUID().uuidString
        sampleTrade.symbol = "000001.SZ"
        sampleTrade.direction = "buy"
        sampleTrade.quantity = 1000
        sampleTrade.price = NSDecimalNumber(string: "12.30")
        sampleTrade.amount = NSDecimalNumber(string: "12300.00")
        sampleTrade.commission = NSDecimalNumber(string: "5.00")
        sampleTrade.timestamp = Date()
        sampleTrade.strategy = "高频策略"
        sampleTrade.pnl = NSDecimalNumber(string: "200.00")
        
        // 创建样本持仓 - 使用NSDecimalNumber
        let samplePosition = PositionEntity(context: context)
        samplePosition.symbol = "000001.SZ"
        samplePosition.quantity = 1000
        samplePosition.avgCost = NSDecimalNumber(string: "12.30")
        samplePosition.currentPrice = NSDecimalNumber(string: "12.50")
        samplePosition.marketValue = NSDecimalNumber(string: "12500.00")
        samplePosition.pnl = NSDecimalNumber(string: "200.00")
        samplePosition.pnlPercent = NSDecimalNumber(string: "1.63")
        samplePosition.lastUpdate = Date()
    }
}
