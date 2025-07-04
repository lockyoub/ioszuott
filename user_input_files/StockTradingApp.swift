/*
 多周期股票做T交易系统 - iOS原生应用
 主应用文件
 作者: MiniMax Agent
 创建时间: 2025-06-24 14:32:13
 */

import SwiftUI
import CoreData
import UserNotifications

@main
struct StockTradingApp: App {
    // Core Data容器
    let persistenceController = PersistenceController.shared
    
    // 应用状态管理
    @StateObject private var appState = AppState()
    @StateObject private var marketDataService = MarketDataService()
    @StateObject private var tradingService = TradingService()
    @StateObject private var strategyEngine = StrategyEngine()
    
    // 通知管理
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var pushNotificationService = PushNotificationService.shared
    
    // 应用委托
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .environmentObject(marketDataService)
                .environmentObject(tradingService)
                .environmentObject(strategyEngine)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    saveContext()
                }
        }
    }
    
    /// 应用初始化设置
    private func setupApp() {
        // 配置应用启动参数
        configureAppearance()
        
        // 启动核心服务
        startCoreServices()
        
        // 注册推送通知
        registerForPushNotifications()
    }
    
    /// 配置应用外观
    private func configureAppearance() {
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    /// 启动核心服务
    private func startCoreServices() {
        Task {
            await marketDataService.start()
            await tradingService.start()
            await strategyEngine.start()
        }
    }
    
    /// 注册推送通知
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// 保存Core Data上下文
    private func saveContext() {
        let context = persistenceController.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存数据失败: \(error)")
            }
        }
    }
}


