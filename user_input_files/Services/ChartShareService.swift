//
//  ChartShareService.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  图表分享服务 - 提供图表截图生成和分享功能
//

import SwiftUI
import UIKit

/// 图表分享服务
@MainActor
public class ChartShareService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 生成图表截图
    
    /// 生成图表截图
    /// - Parameter view: 要截图的视图
    /// - Returns: 生成的UIImage
    public func generateChartImage(from view: AnyView) async -> UIImage? {
        isGenerating = true
        
        defer {
            isGenerating = false
        }
        
        return await withCheckedContinuation { continuation in
            // 使用UIHostingController来渲染SwiftUI视图
            let hostingController = UIHostingController(rootView: view)
            
            // 设置合适的尺寸
            let targetSize = CGSize(width: 800, height: 600)
            hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
            
            // 强制布局
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            
            // 生成图片
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let image = renderer.image { context in
                hostingController.view.layer.render(in: context.cgContext)
            }
            
            continuation.resume(returning: image)
        }
    }
    
    /// 为特定股票生成完整的图表截图
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - includeWatermark: 是否包含水印
    /// - Returns: 生成的UIImage
    public func generateStockChartImage(
        stockCode: String,
        stockName: String,
        includeWatermark: Bool = true
    ) async -> UIImage? {
        isGenerating = true
        
        defer {
            isGenerating = false
        }
        
        // 创建完整的图表视图用于截图
        let chartView = AnyView(
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    VStack(alignment: .leading) {
                        Text(stockName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(stockCode)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if includeWatermark {
                        Text("StockTradingApp")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.black)
                
                // 图表区域 (这里应该是实际的图表组件)
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 400)
                    
                    Text("图表截图生成中...")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                // 时间戳
                HStack {
                    Spacer()
                    Text("生成时间: \(formatDate(Date()))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color.black)
            }
        )
        
        return await generateChartImage(from: chartView)
    }
    
    // MARK: - 分享功能
    
    /// 分享图表
    /// - Parameters:
    ///   - image: 要分享的图片
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    ///   - sourceView: 源视图（用于iPad的弹出框定位）
    public func shareChart(
        image: UIImage,
        stockCode: String,
        stockName: String,
        sourceView: UIView? = nil
    ) {
        let shareText = "【股票图表分享】\n\(stockName) (\(stockCode))\n生成时间: \(formatDate(Date()))"
        let activityItems: [Any] = [shareText, image]
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // iPad适配
        if let popover = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                // 如果没有提供源视图，使用根视图控制器的视图
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popover.sourceView = window.rootViewController?.view
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
        }
        
        // 获取当前的视图控制器并呈现分享界面
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    /// 保存图表到相册
    /// - Parameter image: 要保存的图片
    /// - Returns: 保存是否成功
    public func saveChartToPhotos(_ image: UIImage) async -> Bool {
        return await withCheckedContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), UnsafeMutableRawPointer(Unmanaged.passRetained(continuation).toOpaque()))
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let continuation = Unmanaged<CheckedContinuation<Bool, Never>>.fromOpaque(contextInfo).takeRetainedValue()
        
        if let error = error {
            print("保存图片失败: \(error.localizedDescription)")
            continuation.resume(returning: false)
        } else {
            continuation.resume(returning: true)
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 扩展方法
extension View {
    /// 创建视图的截图
    /// - Returns: UIImage
    func snapshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = CGSize(width: 800, height: 600)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = UIColor.clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
