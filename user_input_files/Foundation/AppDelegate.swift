/*
 应用委托
 处理应用生命周期和系统回调
 作者: MiniMax Agent
 创建时间: 2025-07-03
 */

import UIKit
import CoreData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 配置应用启动
        configureAppearance()
        
        // 注册通知
        registerForNotifications()
        
        return true
    }
    
    // MARK: - 应用外观配置
    private func configureAppearance() {
        // 设置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 设置标签栏外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - 通知注册
    private func registerForNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - 远程通知
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("设备Token: \(token)")
        
        // 发送token到服务器
        NotificationManager.shared.updateDeviceToken(token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("注册远程通知失败: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 处理后台推送通知
        print("收到远程通知: \(userInfo)")
        
        // 处理通知数据
        NotificationManager.shared.handleRemoteNotification(userInfo)
        
        completionHandler(.newData)
    }
    
    // MARK: - 应用状态变化
    func applicationWillResignActive(_ application: UIApplication) {
        // 应用即将失去焦点
        print("应用即将失去焦点")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 应用进入后台
        print("应用进入后台")
        
        // 保存Core Data上下文
        PersistenceController.shared.save()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 应用即将进入前台
        print("应用即将进入前台")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 应用已激活
        print("应用已激活")
        
        // 清除角标
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // 应用即将终止
        print("应用即将终止")
        
        // 保存Core Data上下文
        PersistenceController.shared.save()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 应用在前台时显示通知
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 用户点击通知
        let userInfo = response.notification.request.content.userInfo
        print("用户点击通知: \(userInfo)")
        
        // 处理通知点击
        NotificationManager.shared.handleNotificationTap(userInfo)
        
        completionHandler()
    }
}