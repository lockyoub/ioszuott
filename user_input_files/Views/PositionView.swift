/*
 持仓管理视图
 显示和管理用户持仓
 作者: MiniMax Agent
 创建时间: 2025-07-03
 */

import SwiftUI

struct PositionView: View {
    @EnvironmentObject private var tradingService: TradingService
    @EnvironmentObject private var marketDataService: MarketDataService
    @State private var selectedPosition: PositionEntity?
    @State private var showingPositionDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 总览卡片
                PortfolioSummaryCard()
                    .padding()
                
                // 持仓列表
                List {
                    ForEach(tradingService.positions, id: \.symbol) { position in
                        PositionRowView(position: position) {
                            selectedPosition = position
                            showingPositionDetail = true
                        }
                    }
                }
            }
            .navigationTitle("我的持仓")
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingPositionDetail) {
                if let position = selectedPosition {
                    PositionDetailView(position: position)
                }
            }
        }
    }
    
    @MainActor
    private func refreshData() async {
        // 刷新持仓数据
        await tradingService.refreshPositions()
        
        // 刷新市场数据
        let symbols = tradingService.positions.map { $0.symbol ?? "" }
        await marketDataService.subscribe(symbols: symbols)
    }
}

struct PortfolioSummaryCard: View {
    @EnvironmentObject private var tradingService: TradingService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("投资组合总览")
                    .font(.headline)
                Spacer()
                Button("详细") {
                    // 显示详细投资组合页面
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                SummaryItem(
                    title: "总市值",
                    value: formatCurrency(totalMarketValue),
                    color: .primary
                )
                
                SummaryItem(
                    title: "今日盈亏",
                    value: formatCurrency(todayPnL),
                    color: todayPnL >= 0 ? .green : .red
                )
                
                SummaryItem(
                    title: "总盈亏",
                    value: formatCurrency(totalPnL),
                    color: totalPnL >= 0 ? .green : .red
                )
            }
            
            HStack(spacing: 20) {
                SummaryItem(
                    title: "持仓股票",
                    value: "\(tradingService.positions.count)只",
                    color: .secondary
                )
                
                SummaryItem(
                    title: "盈亏比例",
                    value: formatPercentage(totalPnLPercent),
                    color: totalPnLPercent >= 0 ? .green : .red
                )
                
                SummaryItem(
                    title: "可用资金",
                    value: formatCurrency(availableFunds),
                    color: .secondary
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var totalMarketValue: Double {
        tradingService.positions.reduce(0) { total, position in
            total + (position.marketValue?.doubleValue ?? 0)
        }
    }
    
    private var todayPnL: Double {
        // 计算今日盈亏
        tradingService.dailyPnL
    }
    
    private var totalPnL: Double {
        tradingService.positions.reduce(0) { total, position in
            total + (position.pnl?.doubleValue ?? 0)
        }
    }
    
    private var totalPnLPercent: Double {
        guard totalMarketValue > 0 else { return 0 }
        return (totalPnL / totalMarketValue) * 100
    }
    
    private var availableFunds: Double {
        tradingService.accountInfo.availableFunds
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value / 100)) ?? "0.00%"
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PositionRowView: View {
    let position: PositionEntity
    let onTap: () -> Void
    @EnvironmentObject private var marketDataService: MarketDataService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("持仓: \(position.quantity)股")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("成本: \(formatPrice(position.avgCost?.doubleValue ?? 0))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatPrice(currentPrice))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(priceChangeColor)
                
                Text(formatCurrency(position.marketValue?.doubleValue ?? 0))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(formatCurrency(position.pnl?.doubleValue ?? 0))
                    Text("(\(formatPercentage(position.pnlPercent?.doubleValue ?? 0)))")
                }
                .font(.caption)
                .foregroundColor(pnlColor)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
    
    private var currentPrice: Double {
        marketDataService.getCurrentPrice(for: position.symbol ?? "") ?? position.currentPrice?.doubleValue ?? 0
    }
    
    private var priceChangeColor: Color {
        let avgCost = position.avgCost?.doubleValue ?? 0
        return currentPrice >= avgCost ? .green : .red
    }
    
    private var pnlColor: Color {
        let pnl = position.pnl?.doubleValue ?? 0
        return pnl >= 0 ? .green : .red
    }
    
    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        String(format: "%+.2f%%", value)
    }
}

struct PositionDetailView: View {
    let position: PositionEntity
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var marketDataService: MarketDataService
    @EnvironmentObject private var tradingService: TradingService
    
    @State private var showingSellConfirmation = false
    @State private var sellQuantity: Int = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本信息卡片
                    PositionInfoCard(position: position)
                    
                    // 盈亏分析卡片
                    PnLAnalysisCard(position: position)
                    
                    // 操作按钮
                    ActionButtonsView(
                        position: position,
                        onSell: {
                            sellQuantity = Int(position.quantity)
                            showingSellConfirmation = true
                        }
                    )
                    
                    // 相关交易记录
                    TradeHistorySection(position: position)
                }
                .padding()
            }
            .navigationTitle(position.symbol ?? "持仓详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("确认卖出", isPresented: $showingSellConfirmation) {
                TextField("卖出数量", value: $sellQuantity, format: .number)
                Button("确认") {
                    executeSell()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请输入要卖出的股票数量")
            }
        }
    }
    
    private func executeSell() {
        Task {
            await tradingService.sellStock(
                symbol: position.symbol ?? "",
                quantity: sellQuantity,
                price: marketDataService.getCurrentPrice(for: position.symbol ?? "") ?? 0
            )
            dismiss()
        }
    }
}

struct PositionInfoCard: View {
    let position: PositionEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("持仓信息")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("股票代码:")
                        .foregroundColor(.secondary)
                    Text(position.symbol ?? "")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("持仓数量:")
                        .foregroundColor(.secondary)
                    Text("\(position.quantity)股")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("平均成本:")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", position.avgCost?.doubleValue ?? 0))
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("当前价格:")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", position.currentPrice?.doubleValue ?? 0))
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("市值:")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", position.marketValue?.doubleValue ?? 0))
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("最后更新:")
                        .foregroundColor(.secondary)
                    Text(formatDate(position.lastUpdate))
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PnLAnalysisCard: View {
    let position: PositionEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("盈亏分析")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("浮动盈亏")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f", position.pnl?.doubleValue ?? 0))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(pnlColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("盈亏比例")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%+.2f%%", position.pnlPercent?.doubleValue ?? 0))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(pnlColor)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var pnlColor: Color {
        let pnl = position.pnl?.doubleValue ?? 0
        return pnl >= 0 ? .green : .red
    }
}

struct ActionButtonsView: View {
    let position: PositionEntity
    let onSell: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSell) {
                Text("卖出")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                // 添加到自选
            }) {
                Text("加自选")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct TradeHistorySection: View {
    let position: PositionEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关交易")
                .font(.headline)
            
            if let trades = position.trades?.allObjects as? [TradeEntity] {
                ForEach(trades.prefix(5), id: \.id) { trade in
                    TradeRowView(trade: trade)
                }
                
                if trades.count > 5 {
                    Button("查看更多") {
                        // 显示完整交易历史
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Text("暂无相关交易记录")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TradeRowView: View {
    let trade: TradeEntity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trade.direction ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(directionColor.opacity(0.2))
                    .foregroundColor(directionColor)
                    .cornerRadius(4)
                
                Text(formatDate(trade.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(trade.quantity)股 @ \(String(format: "%.2f", trade.price?.doubleValue ?? 0))")
                    .font(.caption)
                
                Text(String(format: "%.2f", trade.amount?.doubleValue ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var directionColor: Color {
        switch trade.direction {
        case "买入", "BUY":
            return .green
        case "卖出", "SELL":
            return .red
        default:
            return .blue
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}