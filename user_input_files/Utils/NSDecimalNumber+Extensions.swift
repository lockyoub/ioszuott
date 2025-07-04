/*
 NSDecimalNumber扩展
 提供安全的高精度数值操作和转换工具
 作者: MiniMax Agent
 */

import Foundation

extension NSDecimalNumber {
    
    // MARK: - 安全创建方法
    
    /// 从字符串安全创建NSDecimalNumber
    static func safeDecimal(from string: String?) -> NSDecimalNumber {
        guard let string = string, !string.isEmpty else {
            return NSDecimalNumber.zero
        }
        
        // 移除可能的空格和特殊字符
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return NSDecimalNumber(string: cleanString) ?? NSDecimalNumber.zero
    }
    
    /// 从Double安全创建NSDecimalNumber
    static func safeDecimal(from double: Double) -> NSDecimalNumber {
        guard double.isFinite else {
            return NSDecimalNumber.zero
        }
        return NSDecimalNumber(value: double)
    }
    
    /// 从Float安全创建NSDecimalNumber
    static func safeDecimal(from float: Float) -> NSDecimalNumber {
        guard float.isFinite else {
            return NSDecimalNumber.zero
        }
        return NSDecimalNumber(value: float)
    }
    
    /// 从Decimal安全创建NSDecimalNumber
    static func safeDecimal(from decimal: Decimal) -> NSDecimalNumber {
        return NSDecimalNumber(decimal: decimal)
    }
    
    // MARK: - 比较方法
    
    /// 是否大于另一个NSDecimalNumber
    func isGreaterThan(_ other: NSDecimalNumber) -> Bool {
        return self.compare(other) == .orderedDescending
    }
    
    /// 是否小于另一个NSDecimalNumber
    func isLessThan(_ other: NSDecimalNumber) -> Bool {
        return self.compare(other) == .orderedAscending
    }
    
    /// 是否等于另一个NSDecimalNumber
    func isEqualTo(_ other: NSDecimalNumber) -> Bool {
        return self.compare(other) == .orderedSame
    }
    
    /// 是否大于或等于另一个NSDecimalNumber
    func isGreaterThanOrEqualTo(_ other: NSDecimalNumber) -> Bool {
        let result = self.compare(other)
        return result == .orderedDescending || result == .orderedSame
    }
    
    /// 是否小于或等于另一个NSDecimalNumber
    func isLessThanOrEqualTo(_ other: NSDecimalNumber) -> Bool {
        let result = self.compare(other)
        return result == .orderedAscending || result == .orderedSame
    }
    
    /// 是否为正数
    var isPositive: Bool {
        return self.compare(NSDecimalNumber.zero) == .orderedDescending
    }
    
    /// 是否为负数
    var isNegative: Bool {
        return self.compare(NSDecimalNumber.zero) == .orderedAscending
    }
    
    /// 是否为零
    var isZero: Bool {
        return self.compare(NSDecimalNumber.zero) == .orderedSame
    }
    
    // MARK: - 数学运算方法
    
    /// 安全除法（避免除零）
    func safeDividing(by divisor: NSDecimalNumber) -> NSDecimalNumber {
        guard !divisor.isZero else {
            return NSDecimalNumber.zero
        }
        return self.dividing(by: divisor)
    }
    
    /// 取绝对值
    var absoluteValue: NSDecimalNumber {
        return self.isNegative ? self.multiplying(by: NSDecimalNumber(value: -1)) : self
    }
    
    /// 四舍五入到指定小数位
    func rounded(toScale scale: Int16) -> NSDecimalNumber {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: scale,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return self.rounding(accordingToBehavior: behavior)
    }
    
    /// 向上取整到指定小数位
    func roundedUp(toScale scale: Int16) -> NSDecimalNumber {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .up,
            scale: scale,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return self.rounding(accordingToBehavior: behavior)
    }
    
    /// 向下取整到指定小数位
    func roundedDown(toScale scale: Int16) -> NSDecimalNumber {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .down,
            scale: scale,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return self.rounding(accordingToBehavior: behavior)
    }
    
    // MARK: - 格式化方法
    
    /// 格式化为货币字符串
    func toCurrencyString(
        currencyCode: String = "CNY",
        minimumFractionDigits: Int = 2,
        maximumFractionDigits: Int = 2
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        
        return formatter.string(from: self) ?? "¥0.00"
    }
    
    /// 格式化为百分比字符串
    func toPercentString(
        fractionDigits: Int = 2,
        showSign: Bool = false
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        
        if showSign {
            formatter.positivePrefix = "+"
        }
        
        // NSDecimalNumber需要除以100来正确显示百分比
        let percentValue = self.safeDividing(by: NSDecimalNumber(value: 100))
        return formatter.string(from: percentValue) ?? "0.00%"
    }
    
    /// 格式化为带符号的数字字符串
    func toSignedString(
        fractionDigits: Int = 2,
        showPositiveSign: Bool = true
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        
        if showPositiveSign {
            formatter.positivePrefix = "+"
        }
        
        return formatter.string(from: self) ?? "0.00"
    }
    
    /// 格式化为紧凑的数字字符串（如：1.2K, 3.4M）
    func toCompactString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let absValue = self.absoluteValue
        let sign = self.isNegative ? "-" : ""
        
        if absValue.isGreaterThanOrEqualTo(NSDecimalNumber(value: 1_000_000_000)) {
            let value = absValue.safeDividing(by: NSDecimalNumber(value: 1_000_000_000))
            return "\(sign)\(formatter.string(from: value) ?? "0")B"
        } else if absValue.isGreaterThanOrEqualTo(NSDecimalNumber(value: 1_000_000)) {
            let value = absValue.safeDividing(by: NSDecimalNumber(value: 1_000_000))
            return "\(sign)\(formatter.string(from: value) ?? "0")M"
        } else if absValue.isGreaterThanOrEqualTo(NSDecimalNumber(value: 1_000)) {
            let value = absValue.safeDividing(by: NSDecimalNumber(value: 1_000))
            return "\(sign)\(formatter.string(from: value) ?? "0")K"
        } else {
            return formatter.string(from: self) ?? "0"
        }
    }
    
    // MARK: - 类型转换
    
    /// 安全转换为Double（可能会丢失精度）
    var safeDoubleValue: Double {
        let double = self.doubleValue
        return double.isFinite ? double : 0.0
    }
    
    /// 安全转换为Float（可能会丢失精度）
    var safeFloatValue: Float {
        let float = self.floatValue
        return float.isFinite ? float : 0.0
    }
    
    /// 安全转换为Int
    var safeIntValue: Int {
        return Int(self.int64Value)
    }
    
    /// 安全转换为Int32
    var safeInt32Value: Int32 {
        return self.int32Value
    }
    
    /// 转换为Decimal
    var decimalValue: Decimal {
        return self.decimalValue
    }
    
    // MARK: - 常用常量
    
    /// 一百
    static let hundred = NSDecimalNumber(value: 100)
    
    /// 一千
    static let thousand = NSDecimalNumber(value: 1000)
    
    /// 一万
    static let tenThousand = NSDecimalNumber(value: 10000)
    
    /// 一百万
    static let million = NSDecimalNumber(value: 1_000_000)
    
    /// 负一
    static let negativeOne = NSDecimalNumber(value: -1)
}

// MARK: - 金融计算专用扩展
extension NSDecimalNumber {
    
    /// 计算手续费
    static func calculateCommission(
        amount: NSDecimalNumber,
        rate: NSDecimalNumber = NSDecimalNumber(string: "0.0003")!,
        minFee: NSDecimalNumber = NSDecimalNumber(string: "5.0")!
    ) -> NSDecimalNumber {
        let calculatedFee = amount.multiplying(by: rate)
        return calculatedFee.isGreaterThan(minFee) ? calculatedFee : minFee
    }
    
    /// 计算印花税（仅卖出时收取）
    static func calculateStampTax(
        amount: NSDecimalNumber,
        isSell: Bool,
        rate: NSDecimalNumber = NSDecimalNumber(string: "0.001")!
    ) -> NSDecimalNumber {
        return isSell ? amount.multiplying(by: rate) : NSDecimalNumber.zero
    }
    
    /// 计算净金额
    static func calculateNetAmount(
        grossAmount: NSDecimalNumber,
        commission: NSDecimalNumber,
        stampTax: NSDecimalNumber,
        isBuy: Bool
    ) -> NSDecimalNumber {
        let totalFees = commission.adding(stampTax)
        
        if isBuy {
            // 买入：净金额 = 成交金额 + 费用
            return grossAmount.adding(totalFees)
        } else {
            // 卖出：净金额 = 成交金额 - 费用
            return grossAmount.subtracting(totalFees)
        }
    }
    
    /// 计算收益率
    static func calculateReturnRate(
        currentValue: NSDecimalNumber,
        costValue: NSDecimalNumber
    ) -> NSDecimalNumber {
        guard !costValue.isZero else { return NSDecimalNumber.zero }
        
        let profit = currentValue.subtracting(costValue)
        return profit.safeDividing(by: costValue).multiplying(by: NSDecimalNumber.hundred)
    }
    
    /// 计算年化收益率
    static func calculateAnnualizedReturn(
        totalReturn: NSDecimalNumber,
        days: Int
    ) -> NSDecimalNumber {
        guard days > 0 else { return NSDecimalNumber.zero }
        
        let daysInYear = NSDecimalNumber(value: 365.25)
        let daysFactor = daysInYear.safeDividing(by: NSDecimalNumber(value: days))
        
        return totalReturn.multiplying(by: daysFactor)
    }
}

// MARK: - Core Data兼容性
extension NSDecimalNumber {
    
    /// 从Core Data的Decimal属性安全读取
    static func fromCoreData(_ value: Any?) -> NSDecimalNumber {
        if let decimal = value as? NSDecimalNumber {
            return decimal
        } else if let decimal = value as? Decimal {
            return NSDecimalNumber(decimal: decimal)
        } else if let double = value as? Double {
            return NSDecimalNumber.safeDecimal(from: double)
        } else if let string = value as? String {
            return NSDecimalNumber.safeDecimal(from: string)
        } else {
            return NSDecimalNumber.zero
        }
    }
}
