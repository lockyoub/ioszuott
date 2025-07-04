/*
 策略管理视图
 管理和配置交易策略
 作者: MiniMax Agent
 创建时间: 2025-07-03
 */

import SwiftUI

struct StrategyView: View {
    @EnvironmentObject private var strategyEngine: StrategyEngine
    @State private var showingCreateStrategy = false
    @State private var selectedStrategy: StrategyEntity?
    
    var body: some View {
        NavigationView {
            VStack {
                // 策略列表
                List {
                    ForEach(strategyEngine.strategies, id: \.id) { strategy in
                        StrategyRowView(strategy: strategy) {
                            selectedStrategy = strategy
                        }
                    }
                    .onDelete(perform: deleteStrategies)
                }
                
                // 添加策略按钮
                Button(action: {
                    showingCreateStrategy = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("创建新策略")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("交易策略")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingCreateStrategy) {
                CreateStrategyView()
            }
            .sheet(item: $selectedStrategy) { strategy in
                StrategyDetailView(strategy: strategy)
            }
        }
    }
    
    private func deleteStrategies(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                strategyEngine.deleteStrategy(strategyEngine.strategies[index])
            }
        }
    }
}

struct StrategyRowView: View {
    let strategy: StrategyEntity
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.name ?? "未命名策略")
                    .font(.headline)
                
                Text(strategy.type ?? "未知类型")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("时间周期: \(strategy.timeframe ?? "1m")")
                    Spacer()
                    Text(strategy.isActive ? "运行中" : "已停止")
                        .foregroundColor(strategy.isActive ? .green : .red)
                }
                .font(.caption)
            }
            
            Spacer()
            
            VStack {
                Circle()
                    .fill(strategy.isActive ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                Button(action: {
                    strategyEngine.toggleStrategy(strategy)
                }) {
                    Image(systemName: strategy.isActive ? "pause.fill" : "play.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
}

struct CreateStrategyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var strategyEngine: StrategyEngine
    
    @State private var strategyName = ""
    @State private var strategyType = "移动平均"
    @State private var timeframe = "1m"
    @State private var parameters = ""
    
    let strategyTypes = ["移动平均", "RSI", "MACD", "布林带", "自定义"]
    let timeframes = ["1m", "5m", "15m", "30m", "1h", "4h", "1d"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("策略名称", text: $strategyName)
                    
                    Picker("策略类型", selection: $strategyType) {
                        ForEach(strategyTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    
                    Picker("时间周期", selection: $timeframe) {
                        ForEach(timeframes, id: \.self) { tf in
                            Text(tf)
                        }
                    }
                }
                
                Section("参数配置") {
                    TextField("参数 (JSON格式)", text: $parameters, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("创建策略")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createStrategy()
                    }
                    .disabled(strategyName.isEmpty)
                }
            }
        }
    }
    
    private func createStrategy() {
        strategyEngine.createStrategy(
            name: strategyName,
            type: strategyType,
            timeframe: timeframe,
            parameters: parameters
        )
        dismiss()
    }
}

struct StrategyDetailView: View {
    let strategy: StrategyEntity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 策略基本信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("基本信息")
                            .font(.headline)
                        
                        InfoRow(title: "策略名称", value: strategy.name ?? "")
                        InfoRow(title: "策略类型", value: strategy.type ?? "")
                        InfoRow(title: "时间周期", value: strategy.timeframe ?? "")
                        InfoRow(title: "状态", value: strategy.isActive ? "运行中" : "已停止")
                        InfoRow(title: "创建时间", value: formatDate(strategy.createdAt))
                        InfoRow(title: "更新时间", value: formatDate(strategy.updatedAt))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // 策略参数
                    if let parameters = strategy.parameters, !parameters.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("参数配置")
                                .font(.headline)
                            
                            Text(parameters)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // 策略信号历史
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近信号")
                            .font(.headline)
                        
                        if let signals = strategy.signals?.allObjects as? [StrategySignalEntity] {
                            ForEach(signals.prefix(5), id: \.id) { signal in
                                SignalRowView(signal: signal)
                            }
                        } else {
                            Text("暂无信号")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("策略详情")
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
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SignalRowView: View {
    let signal: StrategySignalEntity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(signal.signal ?? "")
                    .font(.headline)
                    .foregroundColor(signalColor)
                
                Text(signal.symbol ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let confidence = signal.confidence {
                    Text("\(Int(confidence.doubleValue * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(formatTime(signal.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var signalColor: Color {
        switch signal.signal {
        case "买入", "BUY":
            return .green
        case "卖出", "SELL":
            return .red
        default:
            return .blue
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}