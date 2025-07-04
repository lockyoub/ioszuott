//
//  TimePickerView.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  时间选择器组件
//

import SwiftUI

/// 时间选择器视图
struct TimePickerView: View {
    @Binding var selectedTime: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date
    @State private var showingDatePicker = false
    
    let title: String
    let isStartTime: Bool
    
    init(selectedTime: Binding<String>, title: String, isStartTime: Bool = true) {
        self._selectedTime = selectedTime
        self.title = title
        self.isStartTime = isStartTime
        
        // 初始化选择的时间
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: selectedTime.wrappedValue) {
            self._selectedDate = State(initialValue: time)
        } else {
            // 如果解析失败，使用默认时间
            let defaultTime = isStartTime ? "09:00" : "15:00"
            let defaultDate = formatter.date(from: defaultTime) ?? Date()
            self._selectedDate = State(initialValue: defaultDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题说明
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(isStartTime ? "设置免打扰开始时间" : "设置免打扰结束时间")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 当前选择的时间显示
                currentTimeDisplay
                
                // 时间选择器
                timePickerSection
                
                // 快速选择按钮
                quickSelectSection
                
                Spacer()
                
                // 操作按钮
                actionButtons
            }
            .padding()
            .background(Color.black)
            .navigationTitle("选择时间")
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
    }
    
    // MARK: - 当前时间显示
    private var currentTimeDisplay: some View {
        VStack(spacing: 8) {
            Text("当前设置")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(formatTime(selectedDate))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    // MARK: - 时间选择器区域
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择时间")
                .font(.headline)
                .foregroundColor(.white)
            
            DatePicker(
                "时间",
                selection: $selectedDate,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .preferredColorScheme(.dark)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 快速选择区域
    private var quickSelectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速选择")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(quickSelectTimes, id: \.self) { time in
                    QuickSelectButton(
                        time: time,
                        isSelected: formatTime(selectedDate) == time,
                        action: {
                            selectTime(time)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("重置") {
                resetToDefault()
            }
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            Button("确定") {
                confirmSelection()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    
    // MARK: - 计算属性
    private var quickSelectTimes: [String] {
        if isStartTime {
            return ["22:00", "23:00", "00:00", "01:00", "02:00", "08:00"]
        } else {
            return ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00"]
        }
    }
    
    // MARK: - 方法
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func selectTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            selectedDate = date
        }
    }
    
    private func resetToDefault() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let defaultTime = isStartTime ? "22:00" : "08:00"
        if let date = formatter.date(from: defaultTime) {
            selectedDate = date
        }
    }
    
    private func confirmSelection() {
        selectedTime = formatTime(selectedDate)
        dismiss()
    }
}

// MARK: - 快速选择按钮
struct QuickSelectButton: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// MARK: - 时间范围选择器
struct TimeRangePickerView: View {
    @Binding var startTime: String
    @Binding var endTime: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    
    init(startTime: Binding<String>, endTime: Binding<String>) {
        self._startTime = startTime
        self._endTime = endTime
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // 初始化开始时间
        if let start = formatter.date(from: startTime.wrappedValue) {
            self._selectedStartDate = State(initialValue: start)
        } else {
            let defaultStart = formatter.date(from: "22:00") ?? Date()
            self._selectedStartDate = State(initialValue: defaultStart)
        }
        
        // 初始化结束时间
        if let end = formatter.date(from: endTime.wrappedValue) {
            self._selectedEndDate = State(initialValue: end)
        } else {
            let defaultEnd = formatter.date(from: "08:00") ?? Date()
            self._selectedEndDate = State(initialValue: defaultEnd)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 说明文字
                VStack(alignment: .leading, spacing: 8) {
                    Text("免打扰时间设置")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("在此时间段内，App将不会发送价格提醒通知")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 时间范围显示
                timeRangeDisplay
                
                // 开始时间选择
                timePickerSection(
                    title: "开始时间",
                    selectedDate: $selectedStartDate
                )
                
                // 结束时间选择
                timePickerSection(
                    title: "结束时间",
                    selectedDate: $selectedEndDate
                )
                
                Spacer()
                
                // 操作按钮
                actionButtons
            }
            .padding()
            .background(Color.black)
            .navigationTitle("免打扰时间")
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
    }
    
    // MARK: - 时间范围显示
    private var timeRangeDisplay: some View {
        HStack {
            VStack {
                Text("开始")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatTime(selectedStartDate))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .foregroundColor(.gray)
            
            Spacer()
            
            VStack {
                Text("结束")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatTime(selectedEndDate))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 时间选择器区域
    private func timePickerSection(title: String, selectedDate: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            DatePicker(
                title,
                selection: selectedDate,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("重置") {
                resetToDefaults()
            }
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            Button("确定") {
                confirmSelection()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    
    // MARK: - 方法
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func resetToDefaults() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let start = formatter.date(from: "22:00") {
            selectedStartDate = start
        }
        
        if let end = formatter.date(from: "08:00") {
            selectedEndDate = end
        }
    }
    
    private func confirmSelection() {
        startTime = formatTime(selectedStartDate)
        endTime = formatTime(selectedEndDate)
        dismiss()
    }
}

// MARK: - 预览
struct TimePickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimePickerView(
                selectedTime: .constant("22:00"),
                title: "开始时间",
                isStartTime: true
            )
            .preferredColorScheme(.dark)
            
            TimeRangePickerView(
                startTime: .constant("22:00"),
                endTime: .constant("08:00")
            )
            .preferredColorScheme(.dark)
        }
    }
}
