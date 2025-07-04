//
//  PriceAlertSetupView.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  价格提醒设置界面
//

import SwiftUI

/// 价格提醒设置视图
struct PriceAlertSetupView: View {
    @StateObject private var priceAlertService = PriceAlertService()
    @Environment(\.dismiss) private var dismiss
    
    let stockCode: String
    let stockName: String
    let currentPrice: Double
    
    @State private var targetPrice: String = ""
    @State private var selectedAlertType: PriceAlertType = .above
    @State private var isEnabled: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 股票信息
                stockInfoSection
                
                // 当前价格
                currentPriceSection
                
                // 提醒设置
                alertSettingsSection
                
                Spacer()
                
                // 创建按钮
                createButton
            }
            .padding()
            .background(Color.black)
            .navigationTitle("价格提醒设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            targetPrice = String(format: "%.2f", currentPrice)
        }
    }
    
    // MARK: - 股票信息区域
    private var stockInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stockName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(stockCode)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 当前价格区域
    private var currentPriceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前价格")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("¥\(String(format: "%.2f", currentPrice))")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 提醒设置区域
    private var alertSettingsSection: some View {
        VStack(spacing: 16) {
            // 提醒类型选择
            VStack(alignment: .leading, spacing: 8) {
                Text("提醒类型")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("提醒类型", selection: $selectedAlertType) {
                    ForEach(PriceAlertType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 目标价格输入
            VStack(alignment: .leading, spacing: 8) {
                Text("目标价格")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("¥")
                        .foregroundColor(.white)
                    
                    TextField("请输入目标价格", text: $targetPrice)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 启用开关
            HStack {
                Text("启用提醒")
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 提醒预览
            alertPreviewSection
        }
    }
    
    // MARK: - 提醒预览
    private var alertPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("提醒预览")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("价格提醒")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    let priceText = Double(targetPrice) ?? currentPrice
                    Text("\(stockName) (\(stockCode)) 价格\(selectedAlertType.displayName) ¥\(String(format: "%.2f", priceText))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 创建按钮
    private var createButton: some View {
        Button(action: createPriceAlert) {
            HStack {
                if priceAlertService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                }
                
                Text("创建价格提醒")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isValidInput ? Color.blue : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!isValidInput || priceAlertService.isLoading)
    }
    
    // MARK: - 计算属性
    private var isValidInput: Bool {
        guard let price = Double(targetPrice), price > 0 else { return false }
        return !stockCode.isEmpty && !stockName.isEmpty
    }
    
    // MARK: - 操作方法
    private func createPriceAlert() {
        guard let price = Double(targetPrice) else {
            alertMessage = "请输入有效的价格"
            showingAlert = true
            return
        }
        
        Task {
            let success = await priceAlertService.createPriceAlert(
                stockCode: stockCode,
                stockName: stockName,
                targetPrice: price,
                alertType: selectedAlertType,
                isEnabled: isEnabled
            )
            
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "价格提醒创建成功"
                    self.showingAlert = true
                    
                    // 延迟关闭界面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                    }
                } else {
                    self.alertMessage = priceAlertService.errorMessage ?? "创建失败"
                    self.showingAlert = true
                }
            }
        }
    }
}

// MARK: - 预览
struct PriceAlertSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PriceAlertSetupView(
            stockCode: "000001",
            stockName: "平安银行",
            currentPrice: 12.85
        )
        .preferredColorScheme(.dark)
    }
}
