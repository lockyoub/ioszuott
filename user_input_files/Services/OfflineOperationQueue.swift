//
// OfflineOperationQueue.swift
// 离线操作队列管理器
//

import Foundation
import CoreData

class OfflineOperationQueue: ObservableObject {
    static let shared = OfflineOperationQueue()
    
    private let persistenceController = PersistenceController.shared
    private let networkService = NetworkService.shared
    private var isProcessing = false
    
    // MARK: - 队列操作
    
    func addOperation(_ operation: OfflineOperation) {
        let context = persistenceController.container.viewContext
        
        let queueItem = OfflineQueueEntity(context: context)
        queueItem.id = UUID().uuidString
        queueItem.operationType = operation.type.rawValue
        queueItem.data = try? JSONSerialization.data(withJSONObject: operation.data)
        queueItem.timestamp = Date()
        queueItem.retryCount = 0
        queueItem.status = "pending"
        
        do {
            try context.save()
            logger.info("离线操作已加入队列: \(operation.type)")
        } catch {
            logger.error("离线操作入队失败: \(error)")
        }
    }
    
    func processQueue() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<OfflineQueueEntity> = OfflineQueueEntity.fetchRequest()
            request.predicate = NSPredicate(format: "status == %@", "pending")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \OfflineQueueEntity.timestamp, ascending: true)]
            
            do {
                let queueItems = try context.fetch(request)
                
                for item in queueItems {
                    await self.processQueueItem(item, context: context)
                }
                
                try context.save()
                
            } catch {
                logger.error("队列处理失败: \(error)")
            }
        }
    }
    
    private func processQueueItem(_ item: OfflineQueueEntity, context: NSManagedObjectContext) async {
        guard let operationType = OfflineOperationType(rawValue: item.operationType ?? ""),
              let data = item.data,
              let operationData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            item.status = "failed"
            item.errorMessage = "无效的操作数据"
            return
        }
        
        do {
            switch operationType {
            case .createTrade:
                try await networkService.createTrade(operationData)
            case .updateTrade:
                try await networkService.updateTrade(operationData)
            case .deleteTrade:
                try await networkService.deleteTrade(operationData["id"] as? String ?? "")
            case .updatePosition:
                try await networkService.updatePosition(operationData)
            }
            
            item.status = "completed"
            item.processedAt = Date()
            
        } catch {
            item.retryCount += 1
            if item.retryCount >= 3 {
                item.status = "failed"
                item.errorMessage = error.localizedDescription
            } else {
                // 重试逻辑：延迟处理
                item.nextRetryAt = Date().addingTimeInterval(TimeInterval(item.retryCount * 60))
            }
            
            logger.error("离线操作处理失败: \(error)")
        }
    }
    
    // MARK: - 状态监控
    
    func getPendingOperationsCount() -> Int {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<OfflineQueueEntity> = OfflineQueueEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func clearCompletedOperations() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<OfflineQueueEntity> = OfflineQueueEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "completed")
        
        do {
            let completedOperations = try context.fetch(request)
            for operation in completedOperations {
                context.delete(operation)
            }
            try context.save()
        } catch {
            logger.error("清理已完成操作失败: \(error)")
        }
    }
}

// MARK: - 数据结构

struct OfflineOperation {
    let type: OfflineOperationType
    let data: [String: Any]
}

enum OfflineOperationType: String, CaseIterable {
    case createTrade = "create_trade"
    case updateTrade = "update_trade"
    case deleteTrade = "delete_trade"
    case updatePosition = "update_position"
}

private let logger = Logger(subsystem: "TradingSystem", category: "OfflineQueue")
