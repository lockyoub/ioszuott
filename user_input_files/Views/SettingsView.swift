/*
 设置视图
 应用设置和偏好配置
 作者: MiniMax Agent
 创建时间: 2025-07-03
 */

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAbout = false
    @State private var showingDataExport = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息部分
                Section {
                    UserProfileSection()
                }
                
                // 显示设置
                Section("显示设置") {
                    ThemeSettingRow()
                    LanguageSettingRow()
                    CurrencySettingRow()
                }
                
                // 交易设置
                Section("交易设置") {
                    NavigationLink("风险管理", destination: RiskManagementSettingsView())
                    NavigationLink("交易偏好", destination: TradingPreferencesView())
                    NavigationLink("价格提醒", destination: PriceAlertSettingsView())
                }
                
                // 通知设置
                Section("通知设置") {
                    NavigationLink("推送通知", destination: NotificationSettingsView())
                    NavigationLink("声音设置", destination: SoundSettingsView())
                }
                
                // 数据与隐私
                Section("数据与隐私") {
                    NavigationLink("数据管理", destination: DataManagementView())
                    Button("导出数据") {
                        showingDataExport = true
                    }
                    NavigationLink("隐私设置", destination: PrivacySettingsView())
                }
                
                // 帮助与支持
                Section("帮助与支持") {
                    NavigationLink("使用帮助", destination: HelpView())
                    NavigationLink("联系客服", destination: ContactSupportView())
                    Button("关于应用") {
                        showingAbout = true
                    }
                }
                
                // 账户操作
                Section {
                    if appState.isLoggedIn {
                        Button("退出登录") {
                            appState.logout()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("登录") {
                            // 显示登录界面
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
        }
    }
}

struct UserProfileSection: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(userInitials)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser.isEmpty ? "未登录" : appState.currentUser)
                    .font(.headline)
                
                if appState.isLoggedIn {
                    Text("点击查看个人资料")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("登录以同步数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if appState.isLoggedIn {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .onTapGesture {
            if appState.isLoggedIn {
                // 显示个人资料页面
            } else {
                // 显示登录页面
            }
        }
    }
    
    private var userInitials: String {
        let username = appState.currentUser
        if username.isEmpty {
            return "?"
        }
        return String(username.prefix(2)).uppercased()
    }
}

struct ThemeSettingRow: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Picker("主题", selection: $appState.theme) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Text(theme.displayName).tag(theme)
            }
        }
    }
}

struct LanguageSettingRow: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Picker("语言", selection: $appState.settings.language) {
            Text("简体中文").tag(Language.chinese)
            Text("English").tag(Language.english)
        }
    }
}

struct CurrencySettingRow: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Picker("货币", selection: $appState.settings.currency) {
            Text("人民币 (CNY)").tag(Currency.cny)
            Text("美元 (USD)").tag(Currency.usd)
            Text("港币 (HKD)").tag(Currency.hkd)
        }
    }
}

// MARK: - 子设置视图

struct RiskManagementSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var maxPositionSize: Double = 10000
    @State private var stopLossPercent: Double = 5.0
    @State private var takeProfitPercent: Double = 10.0
    
    var body: some View {
        Form {
            Section("仓位控制") {
                HStack {
                    Text("单笔最大金额")
                    Spacer()
                    TextField("金额", value: $maxPositionSize, format: .currency(code: "CNY"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                }
                
                HStack {
                    Text("最大仓位比例")
                    Spacer()
                    Text("80%")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("止损止盈") {
                HStack {
                    Text("默认止损比例")
                    Spacer()
                    TextField("百分比", value: $stopLossPercent, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("默认止盈比例")
                    Spacer()
                    TextField("百分比", value: $takeProfitPercent, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
        }
        .navigationTitle("风险管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TradingPreferencesView: View {
    @State private var enableAutoTrading = false
    @State private var confirmBeforeTrade = true
    @State private var defaultQuantity = 100
    
    var body: some View {
        Form {
            Section("交易确认") {
                Toggle("交易前确认", isOn: $confirmBeforeTrade)
                Toggle("启用自动交易", isOn: $enableAutoTrading)
            }
            
            Section("默认设置") {
                Stepper("默认交易数量: \(defaultQuantity)", value: $defaultQuantity, in: 100...10000, step: 100)
            }
        }
        .navigationTitle("交易偏好")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PriceAlertSettingsView: View {
    @State private var enablePriceAlerts = true
    @State private var alertSound = "默认"
    
    var body: some View {
        Form {
            Section("价格提醒") {
                Toggle("启用价格提醒", isOn: $enablePriceAlerts)
                
                Picker("提醒声音", selection: $alertSound) {
                    Text("默认").tag("默认")
                    Text("铃声1").tag("铃声1")
                    Text("铃声2").tag("铃声2")
                }
            }
        }
        .navigationTitle("价格提醒")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// NotificationSettingsView 现在统一使用 Views/Notifications/NotificationSettings.swift 中的定义

struct SoundSettingsView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Form {
            Section("声音设置") {
                Toggle("启用声音", isOn: $appState.settings.soundEnabled)
                Toggle("启用震动", isOn: $appState.settings.vibrationEnabled)
            }
        }
        .navigationTitle("声音设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @State private var cacheSize = "125.6 MB"
    @State private var showingClearConfirmation = false
    
    var body: some View {
        Form {
            Section("存储空间") {
                HStack {
                    Text("缓存大小")
                    Spacer()
                    Text(cacheSize)
                        .foregroundColor(.secondary)
                }
                
                Button("清除缓存") {
                    showingClearConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            Section("数据同步") {
                HStack {
                    Text("自动备份")
                    Spacer()
                    Text("已开启")
                        .foregroundColor(.green)
                }
                
                Button("立即备份") {
                    // 执行备份
                }
            }
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认清除", isPresented: $showingClearConfirmation) {
            Button("清除", role: .destructive) {
                // 清除缓存
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("这将清除所有缓存数据，但不会影响您的交易记录。")
        }
    }
}

struct PrivacySettingsView: View {
    @State private var enableAnalytics = false
    @State private var enableCrashReporting = true
    
    var body: some View {
        Form {
            Section("数据收集") {
                Toggle("使用分析", isOn: $enableAnalytics)
                    .onChange(of: enableAnalytics) { _ in
                        // 更新分析设置
                    }
                
                Toggle("崩溃报告", isOn: $enableCrashReporting)
                    .onChange(of: enableCrashReporting) { _ in
                        // 更新崩溃报告设置
                    }
            }
            
            Section("隐私政策") {
                Button("查看隐私政策") {
                    // 打开隐私政策
                }
                
                Button("查看用户协议") {
                    // 打开用户协议
                }
            }
        }
        .navigationTitle("隐私设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("常见问题") {
                NavigationLink("如何开始交易？", destination: EmptyView())
                NavigationLink("如何设置止损？", destination: EmptyView())
                NavigationLink("如何查看交易记录？", destination: EmptyView())
            }
            
            Section("操作指南") {
                NavigationLink("新手入门", destination: EmptyView())
                NavigationLink("高级功能", destination: EmptyView())
                NavigationLink("风险提示", destination: EmptyView())
            }
        }
        .navigationTitle("使用帮助")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactSupportView: View {
    var body: some View {
        Form {
            Section("联系方式") {
                HStack {
                    Text("客服电话")
                    Spacer()
                    Text("400-123-4567")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("客服邮箱")
                    Spacer()
                    Text("support@stockapp.com")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("在线客服")
                    Spacer()
                    Text("工作日 9:00-18:00")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("反馈建议") {
                Button("提交问题反馈") {
                    // 打开反馈页面
                }
                
                Button("功能建议") {
                    // 打开建议页面
                }
            }
        }
        .navigationTitle("联系客服")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 应用图标
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 8) {
                    Text("股票交易系统")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("版本 1.0.0 (1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Text("专业的股票交易应用，提供实时行情、智能策略和风险管理功能。")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 实时股票行情推送")
                        Text("• 多策略自动交易")
                        Text("• 专业K线图表分析")
                        Text("• 智能风险管理系统")
                        Text("• 完整投资组合管理")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("© 2025 MiniMax Agent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("保留所有权利")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportType = "交易记录"
    @State private var dateRange = "最近一个月"
    @State private var isExporting = false
    
    let exportTypes = ["交易记录", "持仓数据", "策略配置", "全部数据"]
    let dateRanges = ["最近一周", "最近一个月", "最近三个月", "全部时间"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("导出设置") {
                    Picker("数据类型", selection: $exportType) {
                        ForEach(exportTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    
                    Picker("时间范围", selection: $dateRange) {
                        ForEach(dateRanges, id: \.self) { range in
                            Text(range)
                        }
                    }
                }
                
                Section {
                    Button(action: startExport) {
                        if isExporting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("导出中...")
                            }
                        } else {
                            Text("开始导出")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        // 模拟导出过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            // 显示导出完成提示
            dismiss()
        }
    }
}