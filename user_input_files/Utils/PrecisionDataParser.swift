//
// PrecisionDataParser.swift
// 高精度金融数据解析工具
//

import Foundation

class PrecisionDataParser {
    
    /// 从JSON数据中安全解析Decimal类型
    static func parseDecimal(from data: [String: Any], key: String) -> NSDecimalNumber {
        if let stringValue = data[key] as? String {
            return NSDecimalNumber.safeDecimal(from: stringValue)
        } else if let doubleValue = data[key] as? Double {
            // 【精度修复】先转换为字符串再创建NSDecimalNumber，避免精度丢失
            return NSDecimalNumber.safeDecimal(from: String(doubleValue))
        } else if let intValue = data[key] as? Int {
            return NSDecimalNumber(value: intValue)
        }
        return NSDecimalNumber.zero
    }
    
    /// 从JSON数据中安全解析可选Decimal类型
    static func parseOptionalDecimal(from data: [String: Any], key: String) -> NSDecimalNumber? {
        if let stringValue = data[key] as? String {
            return NSDecimalNumber.safeDecimal(from: stringValue)
        } else if let doubleValue = data[key] as? Double {
            // 【精度修复】先转换为字符串再创建NSDecimalNumber，避免精度丢失
            return NSDecimalNumber.safeDecimal(from: String(doubleValue))
        } else if let intValue = data[key] as? Int {
            return NSDecimalNumber(value: intValue)
        }
        return nil
    }
    
    /// 将Decimal类型转换为字符串以便传输
    static func decimalToString(_ decimal: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter.string(from: decimal) ?? "0"
    }
    
    /// 金融计算专用的四舍五入
    static func roundForFinance(_ decimal: NSDecimalNumber, scale: Int16 = 4) -> NSDecimalNumber {
        let behavior = NSDecimalNumberHandler(roundingMode: .bankers,
                                            scale: scale,
                                            raiseOnExactness: false,
                                            raiseOnOverflow: false,
                                            raiseOnUnderflow: false,
                                            raiseOnDivideByZero: false)
        return decimal.rounding(accordingToBehavior: behavior)
    }
}

extension NSDecimalNumber {
    
    /// 安全地从字符串创建NSDecimalNumber
    static func safeDecimal(from string: String) -> NSDecimalNumber {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanString.isEmpty {
            return NSDecimalNumber.zero
        }
        
        let decimal = NSDecimalNumber(string: cleanString)
        return decimal == NSDecimalNumber.notANumber ? NSDecimalNumber.zero : decimal
    }
    
    /// 格式化为金融显示字符串
    var financialString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self) ?? "0.00"
    }
    
    /// 格式化为百分比字符串
    var percentageString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self) ?? "0.00%"
    }
}
