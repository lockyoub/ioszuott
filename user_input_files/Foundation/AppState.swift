/*
 应用状态管理
 管理全局应用状态和配置
 作者: MiniMax Agent
 创建时间: 2025-07-03
 */

import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    
    // MARK: - 用户状态
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: String = ""
    @Published var userProfile: UserProfile?
    
    // MARK: - 应用主题
    @Published var theme: AppTheme = .system
    @Published var isDarkMode: Bool = false
    
    // MARK: - 网络状态
    @Published var isConnected: Bool = true
    @Published var connectionQuality: ConnectionQuality = .good
    
    // MARK: - 交易状态
    @Published var isTradingEnabled: Bool = false
    @Published var tradingSessionStatus: TradingSessionStatus = .closed
    @Published var marketStatus: MarketStatus = .closed
    
    // MARK: - 应用设置
    @Published var settings: AppSettings = AppSettings()
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    // MARK: - 错误和状态管理
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var currentMarketStatus: MarketStatus = .closed
    
    // MARK: - 私有属性
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - 初始化
    init() {
        loadUserDefaults()
        setupBindings()
        observeSystemTheme()
    }
    
    // MARK: - 用户状态管理
    func login(username: String, token: String) {
        currentUser = username
        isLoggedIn = true
        
        // 保存登录状态
        userDefaults.set(username, forKey: "currentUser")
        userDefaults.set(token, forKey: "authToken")
        userDefaults.set(true, forKey: "isLoggedIn")
    }
    
    func logout() {
        currentUser = ""
        isLoggedIn = false
        userProfile = nil
        
        // 清除保存的数据
        userDefaults.removeObject(forKey: "currentUser")
        userDefaults.removeObject(forKey: "authToken")
        userDefaults.set(false, forKey: "isLoggedIn")
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        
        // 保存用户配置
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: "userProfile")
        }
    }
    
    // MARK: - 主题管理
    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        userDefaults.set(theme.rawValue, forKey: "appTheme")
        
        updateDarkModeStatus()
    }
    
    private func updateDarkModeStatus() {
        switch theme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    // MARK: - 网络状态管理
    func updateConnectionStatus(_ isConnected: Bool, quality: ConnectionQuality = .good) {
        self.isConnected = isConnected
        self.connectionQuality = quality
    }
    
    // MARK: - 交易状态管理
    func updateTradingStatus(enabled: Bool, sessionStatus: TradingSessionStatus, marketStatus: MarketStatus) {
        isTradingEnabled = enabled
        tradingSessionStatus = sessionStatus
        self.marketStatus = marketStatus
    }
    
    // MARK: - 设置管理
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        
        // 保存设置
        if let data = try? JSONEncoder().encode(newSettings) {
            userDefaults.set(data, forKey: "appSettings")
        }
    }
    
    func updateNotificationSettings(_ newSettings: NotificationSettings) {
        notificationSettings = newSettings
        
        // 保存通知设置
        if let data = try? JSONEncoder().encode(newSettings) {
            userDefaults.set(data, forKey: "notificationSettings")
        }
    }
    
    // MARK: - 错误状态管理
    func clearError() {
        errorMessage = nil
    }
    
    func setError(_ message: String) {
        errorMessage = message
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func updateMarketStatus(_ status: MarketStatus) {
        currentMarketStatus = status
    }
    
    // MARK: - 私有方法
    private func loadUserDefaults() {
        // 加载用户状态
        currentUser = userDefaults.string(forKey: "currentUser") ?? ""
        isLoggedIn = userDefaults.bool(forKey: "isLoggedIn")
        
        // 加载主题设置
        if let themeString = userDefaults.string(forKey: "appTheme"),
           let savedTheme = AppTheme(rawValue: themeString) {
            theme = savedTheme
        }
        
        // 加载用户配置
        if let profileData = userDefaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
        
        // 加载应用设置
        if let settingsData = userDefaults.data(forKey: "appSettings"),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: settingsData) {
            settings = savedSettings
        }
        
        // 加载通知设置
        if let notificationData = userDefaults.data(forKey: "notificationSettings"),
           let savedNotificationSettings = try? JSONDecoder().decode(NotificationSettings.self, from: notificationData) {
            notificationSettings = savedNotificationSettings
        }
        
        updateDarkModeStatus()
    }
    
    private func setupBindings() {
        // 监听主题变化
        $theme
            .sink { [weak self] _ in
                self?.updateDarkModeStatus()
            }
            .store(in: &cancellables)
    }
    
    private func observeSystemTheme() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.theme == .system {
                    self?.updateDarkModeStatus()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 数据模型
struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let avatar: String?
    let riskLevel: RiskLevel
    let tradingExperience: TradingExperience
    let preferredCurrency: Currency
}

struct AppSettings: Codable {
    var language: Language = .chinese
    var currency: Currency = .cny
    var timeZone: TimeZone = .shanghai
    var chartRefreshInterval: Int = 1000 // 毫秒
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var autoSave: Bool = true
    var dataCompression: Bool = true
}

// NotificationSettings 已移至 SharedModels.swift 统一管理

// QuietHours 已移至 SharedModels.swift 统一管理

// MARK: - 枚举定义
enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }
}

enum ConnectionQuality: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case poor = "poor"
    case disconnected = "disconnected"
}

enum TradingSessionStatus: String, Codable {
    case preMarket = "preMarket"
    case open = "open"
    case closed = "closed"
    case afterHours = "afterHours"
}

enum MarketStatus: String, Codable {
    case open = "open"
    case closed = "closed"
    case holiday = "holiday"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .open: return "开市"
        case .closed: return "闭市"
        case .holiday: return "休市"
        case .maintenance: return "维护"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .green
        case .closed: return .red
        case .holiday: return .orange
        case .maintenance: return .gray
        }
    }
}

// RiskLevel 已移至 SharedModels.swift 统一管理

enum TradingExperience: String, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case professional = "professional"
}

enum Currency: String, Codable {
    case cny = "CNY"
    case usd = "USD"
    case hkd = "HKD"
}

enum Language: String, Codable {
    case chinese = "zh-CN"
    case english = "en-US"
}

enum TimeZone: String, Codable {
    case shanghai = "Asia/Shanghai"
    case hongKong = "Asia/Hong_Kong"
    case newYork = "America/New_York"
}