//
//  PriceAlertService.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  价格提醒服务 - 提供股票价格提醒的设置和管理功能
//

import Foundation
import CoreData
import Combine
import UserNotifications

/// 价格提醒服务
@MainActor
public class PriceAlertService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var alerts: [PriceAlert] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - 初始化
    init() {
        loadPriceAlerts()
        requestNotificationPermission()
    }
    
    // MARK: - 价格提醒管理
    
    /// 创建价格提醒
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - targetPrice: 目标价格
    ///   - alertType: 提醒类型 (高于/低于)
    ///   - isEnabled: 是否启用
    /// - Returns: 创建是否成功
    public func createPriceAlert(
        stockCode: String,
        stockName: String,
        targetPrice: Double,
        alertType: PriceAlertType,
        isEnabled: Bool = true
    ) async -> Bool {
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            let alertEntity = PriceAlertEntity(context: context)
            alertEntity.id = UUID()
            alertEntity.stockCode = stockCode
            alertEntity.stockName = stockName
            alertEntity.targetPrice = targetPrice
            alertEntity.alertType = alertType.rawValue
            alertEntity.isEnabled = isEnabled
            alertEntity.createdDate = Date()
            alertEntity.isTriggered = false
            
            try context.save()
            
            // 更新本地缓存
            let newAlert = PriceAlert(
                id: alertEntity.id!,
                stockCode: stockCode,
                stockName: stockName,
                targetPrice: targetPrice,
                alertType: alertType,
                isEnabled: isEnabled,
                createdDate: Date(),
                isTriggered: false
            )
            alerts.append(newAlert)
            
            // 如果启用，注册本地通知
            if isEnabled {
                await scheduleLocalNotification(for: newAlert)
            }
            
            // 同步到服务器
            await syncToServer(action: .create, alert: newAlert)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "创建价格提醒失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 更新价格提醒
    /// - Parameters:
    ///   - alertId: 提醒ID
    ///   - targetPrice: 新的目标价格
    ///   - isEnabled: 是否启用
    /// - Returns: 更新是否成功
    public func updatePriceAlert(alertId: UUID, targetPrice: Double? = nil, isEnabled: Bool? = nil) async -> Bool {
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<PriceAlertEntity> = PriceAlertEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", alertId as CVarArg)
            
            guard let alertEntity = try context.fetch(request).first else {
                errorMessage = "找不到指定的价格提醒"
                isLoading = false
                return false
            }
            
            if let targetPrice = targetPrice {
                alertEntity.targetPrice = targetPrice
            }
            
            if let isEnabled = isEnabled {
                alertEntity.isEnabled = isEnabled
            }
            
            try context.save()
            
            // 更新本地缓存
            if let index = alerts.firstIndex(where: { $0.id == alertId }) {
                if let targetPrice = targetPrice {
                    alerts[index].targetPrice = targetPrice
                }
                if let isEnabled = isEnabled {
                    alerts[index].isEnabled = isEnabled
                }
                
                // 重新调度通知
                await scheduleLocalNotification(for: alerts[index])
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "更新价格提醒失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 删除价格提醒
    /// - Parameter alertId: 提醒ID
    /// - Returns: 删除是否成功
    public func deletePriceAlert(alertId: UUID) async -> Bool {
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<PriceAlertEntity> = PriceAlertEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", alertId as CVarArg)
            
            let alertEntities = try context.fetch(request)
            for alertEntity in alertEntities {
                context.delete(alertEntity)
            }
            
            try context.save()
            
            // 取消本地通知
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alertId.uuidString])
            
            // 更新本地缓存
            alerts.removeAll { $0.id == alertId }
            
            // 同步到服务器
            await syncToServer(action: .delete, alertId: alertId)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "删除价格提醒失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 检查价格提醒是否触发
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - currentPrice: 当前价格
    public func checkPriceAlerts(stockCode: String, currentPrice: Double) async {
        let stockAlerts = alerts.filter { $0.stockCode == stockCode && $0.isEnabled && !$0.isTriggered }
        
        for alert in stockAlerts {
            var shouldTrigger = false
            
            switch alert.alertType {
            case .above:
                shouldTrigger = currentPrice >= alert.targetPrice
            case .below:
                shouldTrigger = currentPrice <= alert.targetPrice
            }
            
            if shouldTrigger {
                await triggerPriceAlert(alert: alert, currentPrice: currentPrice)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 加载价格提醒列表
    private func loadPriceAlerts() {
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<PriceAlertEntity> = PriceAlertEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PriceAlertEntity.createdDate, ascending: false)]
            
            let entities = try context.fetch(request)
            alerts = entities.compactMap { entity in
                guard let id = entity.id,
                      let stockCode = entity.stockCode,
                      let stockName = entity.stockName,
                      let alertTypeString = entity.alertType,
                      let alertType = PriceAlertType(rawValue: alertTypeString),
                      let createdDate = entity.createdDate else {
                    return nil
                }
                
                return PriceAlert(
                    id: id,
                    stockCode: stockCode,
                    stockName: stockName,
                    targetPrice: entity.targetPrice,
                    alertType: alertType,
                    isEnabled: entity.isEnabled,
                    createdDate: createdDate,
                    isTriggered: entity.isTriggered
                )
            }
            
        } catch {
            errorMessage = "加载价格提醒失败: \(error.localizedDescription)"
        }
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 调度本地通知
    private func scheduleLocalNotification(for alert: PriceAlert) async {
        guard alert.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "价格提醒"
        content.body = "\(alert.stockName) (\(alert.stockCode)) 价格\(alert.alertType == .above ? "高于" : "低于") ¥\(String(format: "%.2f", alert.targetPrice))"
        content.sound = .default
        content.userInfo = [
            "alertId": alert.id.uuidString,
            "stockCode": alert.stockCode,
            "stockName": alert.stockName,
            "targetPrice": alert.targetPrice
        ]
        
        // 这里可以设置更复杂的触发条件
        // 目前设置为立即触发，实际应用中应该基于实时价格数据
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("调度通知失败: \(error.localizedDescription)")
        }
    }
    
    /// 触发价格提醒
    private func triggerPriceAlert(alert: PriceAlert, currentPrice: Double) async {
        // 标记为已触发
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].isTriggered = true
        }
        
        // 更新数据库
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<PriceAlertEntity> = PriceAlertEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", alert.id as CVarArg)
            
            if let alertEntity = try context.fetch(request).first {
                alertEntity.isTriggered = true
                alertEntity.triggeredDate = Date()
                alertEntity.triggeredPrice = currentPrice
                try context.save()
            }
        } catch {
            print("更新提醒状态失败: \(error.localizedDescription)")
        }
        
        // 发送本地通知
        let content = UNMutableNotificationContent()
        content.title = "价格提醒触发"
        content.body = "\(alert.stockName) (\(alert.stockCode)) 当前价格 ¥\(String(format: "%.2f", currentPrice))，已\(alert.alertType == .above ? "突破" : "跌破")目标价格 ¥\(String(format: "%.2f", alert.targetPrice))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// 同步到服务器
    private func syncToServer(action: PriceAlertAction, alert: PriceAlert? = nil, alertId: UUID? = nil) async {
        do {
            var request: [String: Any] = ["action": action.rawValue]
            
            switch action {
            case .create, .update:
                if let alert = alert {
                    request["alert"] = [
                        "id": alert.id.uuidString,
                        "stockCode": alert.stockCode,
                        "stockName": alert.stockName,
                        "targetPrice": alert.targetPrice,
                        "alertType": alert.alertType.rawValue,
                        "isEnabled": alert.isEnabled
                    ]
                }
            case .delete:
                if let alertId = alertId {
                    request["alertId"] = alertId.uuidString
                }
            }
            
            // 发送请求到后端
            // let response = try await networkManager.post("/api/price-alerts", data: request)
            print("价格提醒同步到服务器: \(request)")
            
        } catch {
            print("同步到服务器失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - 数据模型

/// 价格提醒信息
public struct PriceAlert: Identifiable, Equatable {
    public let id: UUID
    public let stockCode: String
    public let stockName: String
    public var targetPrice: Double
    public let alertType: PriceAlertType
    public var isEnabled: Bool
    public let createdDate: Date
    public var isTriggered: Bool
    
    public static func == (lhs: PriceAlert, rhs: PriceAlert) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 价格提醒类型
public enum PriceAlertType: String, CaseIterable {
    case above = "above"    // 高于
    case below = "below"    // 低于
    
    public var displayName: String {
        switch self {
        case .above:
            return "高于"
        case .below:
            return "低于"
        }
    }
}

/// 价格提醒操作类型
enum PriceAlertAction: String {
    case create = "create"
    case update = "update"
    case delete = "delete"
}
