//
//  CoreDataExtensions.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  Core Data 扩展 - 支持新增的功能模块
//

import Foundation
import CoreData

// MARK: - 自选股实体扩展

@objc(WatchlistStockEntity)
public class WatchlistStockEntity: NSManagedObject {
    
}

extension WatchlistStockEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchlistStockEntity> {
        return NSFetchRequest<WatchlistStockEntity>(entityName: "WatchlistStockEntity")
    }
    
    @NSManaged public var stockCode: String?
    @NSManaged public var stockName: String?
    @NSManaged public var addedDate: Date?
    @NSManaged public var sortOrder: Int32
}

// MARK: - 价格提醒实体扩展

@objc(PriceAlertEntity)
public class PriceAlertEntity: NSManagedObject {
    
}

extension PriceAlertEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PriceAlertEntity> {
        return NSFetchRequest<PriceAlertEntity>(entityName: "PriceAlertEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var stockCode: String?
    @NSManaged public var stockName: String?
    @NSManaged public var targetPrice: Double
    @NSManaged public var alertType: String?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var createdDate: Date?
    @NSManaged public var isTriggered: Bool
    @NSManaged public var triggeredDate: Date?
    @NSManaged public var triggeredPrice: Double
}

// MARK: - 图表数据实体扩展

@objc(ChartDataEntity)
public class ChartDataEntity: NSManagedObject {
    
}

extension ChartDataEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChartDataEntity> {
        return NSFetchRequest<ChartDataEntity>(entityName: "ChartDataEntity")
    }
    
    @NSManaged public var stockCode: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var open: Double
    @NSManaged public var high: Double
    @NSManaged public var low: Double
    @NSManaged public var close: Double
    @NSManaged public var volume: Double
    @NSManaged public var dataType: String? // candlestick, volume, indicator
}

// MARK: - 通知历史实体扩展

@objc(NotificationHistoryEntity)
public class NotificationHistoryEntity: NSManagedObject {
    
}

extension NotificationHistoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationHistoryEntity> {
        return NSFetchRequest<NotificationHistoryEntity>(entityName: "NotificationHistoryEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var title: String?
    @NSManaged public var message: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var isRead: Bool
    @NSManaged public var stockCode: String?
    @NSManaged public var stockName: String?
    @NSManaged public var actionTaken: String?
}

// MARK: - 用户设置实体扩展

@objc(UserSettingsEntity)
public class UserSettingsEntity: NSManagedObject {
    
}

extension UserSettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettingsEntity> {
        return NSFetchRequest<UserSettingsEntity>(entityName: "UserSettingsEntity")
    }
    
    @NSManaged public var settingKey: String?
    @NSManaged public var settingValue: String?
    @NSManaged public var lastUpdated: Date?
}

// MARK: - Core Data 辅助方法

extension NSManagedObjectContext {
    
    /// 保存上下文，带错误处理
    func saveWithErrorHandling() {
        do {
            if hasChanges {
                try save()
            }
        } catch {
            print("Core Data 保存失败: \(error.localizedDescription)")
            
            // 可以在这里添加更详细的错误处理
            if let nsError = error as NSError? {
                print("错误详情: \(nsError.localizedDescription)")
                if let detailedErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in detailedErrors {
                        print("详细错误: \(detailedError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 批量删除指定实体的所有对象
    func deleteAllObjects<T: NSManagedObject>(ofType type: T.Type) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try execute(deleteRequest)
            try save()
        } catch {
            print("批量删除失败: \(error.localizedDescription)")
        }
    }
    
    /// 统计指定实体的对象数量
    func count<T: NSManagedObject>(for type: T.Type, predicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<T> = T.fetchRequest()
        request.predicate = predicate
        
        do {
            return try count(for: request)
        } catch {
            print("统计对象数量失败: \(error.localizedDescription)")
            return 0
        }
    }
}

// MARK: - Core Data 模型版本管理

extension PersistenceController {
    
    /// 检查是否需要数据迁移
    func checkForMigration() -> Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            guard let currentModel = container.managedObjectModel else {
                return false
            }
            
            return !currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            print("检查迁移状态失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 清理过期数据
    func cleanupOldData() {
        let context = container.viewContext
        
        // 清理30天前的通知历史
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let predicate = NSPredicate(format: "timestamp < %@", thirtyDaysAgo as NSDate)
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NotificationHistoryEntity.fetchRequest()
        fetchRequest.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("清理了30天前的通知历史")
        } catch {
            print("清理过期数据失败: \(error.localizedDescription)")
        }
    }
}
