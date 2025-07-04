//
//  WatchlistService.swift
//  StockTradingApp
//
//  Created by MiniMax Agent on 2025-06-27.
//  自选股管理服务 - 提供自选股的增删改查功能
//

import Foundation
import CoreData
import Combine

/// 自选股管理服务
@MainActor
public class WatchlistService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var watchlist: [WatchlistStock] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    
    // MARK: - 初始化
    init() {
        loadWatchlist()
    }
    
    // MARK: - 自选股管理
    
    /// 添加股票到自选股
    /// - Parameters:
    ///   - stockCode: 股票代码
    ///   - stockName: 股票名称
    /// - Returns: 添加是否成功
    public func addToWatchlist(stockCode: String, stockName: String) async -> Bool {
        guard !isStockInWatchlist(stockCode: stockCode) else {
            errorMessage = "股票已在自选股中"
            return false
        }
        
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            let watchlistStock = WatchlistStockEntity(context: context)
            watchlistStock.stockCode = stockCode
            watchlistStock.stockName = stockName
            watchlistStock.addedDate = Date()
            watchlistStock.sortOrder = Int32(watchlist.count)
            
            try context.save()
            
            // 更新本地缓存
            let newStock = WatchlistStock(
                stockCode: stockCode,
                stockName: stockName,
                addedDate: Date(),
                sortOrder: watchlist.count
            )
            watchlist.append(newStock)
            
            // 同步到服务器
            await syncToServer(action: .add, stockCode: stockCode, stockName: stockName)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "添加自选股失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 从自选股中移除股票
    /// - Parameter stockCode: 股票代码
    /// - Returns: 移除是否成功
    public func removeFromWatchlist(stockCode: String) async -> Bool {
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<WatchlistStockEntity> = WatchlistStockEntity.fetchRequest()
            request.predicate = NSPredicate(format: "stockCode == %@", stockCode)
            
            let stocks = try context.fetch(request)
            for stock in stocks {
                context.delete(stock)
            }
            
            try context.save()
            
            // 更新本地缓存
            watchlist.removeAll { $0.stockCode == stockCode }
            
            // 同步到服务器
            await syncToServer(action: .remove, stockCode: stockCode)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "移除自选股失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 检查股票是否已在自选股中
    /// - Parameter stockCode: 股票代码
    /// - Returns: 是否在自选股中
    public func isStockInWatchlist(stockCode: String) -> Bool {
        return watchlist.contains { $0.stockCode == stockCode }
    }
    
    /// 更新自选股排序
    /// - Parameter stocks: 新的排序后的股票列表
    public func updateWatchlistOrder(_ stocks: [WatchlistStock]) async {
        isLoading = true
        
        do {
            let context = persistenceController.container.viewContext
            
            for (index, stock) in stocks.enumerated() {
                let request: NSFetchRequest<WatchlistStockEntity> = WatchlistStockEntity.fetchRequest()
                request.predicate = NSPredicate(format: "stockCode == %@", stock.stockCode)
                
                if let entity = try context.fetch(request).first {
                    entity.sortOrder = Int32(index)
                }
            }
            
            try context.save()
            watchlist = stocks
            
            // 同步到服务器
            await syncToServer(action: .reorder, stockList: stocks)
            
            isLoading = false
            
        } catch {
            errorMessage = "更新排序失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - 私有方法
    
    /// 加载自选股列表
    private func loadWatchlist() {
        do {
            let context = persistenceController.container.viewContext
            let request: NSFetchRequest<WatchlistStockEntity> = WatchlistStockEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistStockEntity.sortOrder, ascending: true)]
            
            let entities = try context.fetch(request)
            watchlist = entities.map { entity in
                WatchlistStock(
                    stockCode: entity.stockCode ?? "",
                    stockName: entity.stockName ?? "",
                    addedDate: entity.addedDate ?? Date(),
                    sortOrder: Int(entity.sortOrder)
                )
            }
            
        } catch {
            errorMessage = "加载自选股失败: \(error.localizedDescription)"
        }
    }
    
    /// 同步到服务器
    private func syncToServer(action: WatchlistAction, stockCode: String? = nil, stockName: String? = nil, stockList: [WatchlistStock]? = nil) async {
        // 这里实现与后端API的同步逻辑
        // 根据具体的后端API接口来实现
        do {
            var request: [String: Any] = ["action": action.rawValue]
            
            switch action {
            case .add:
                request["stockCode"] = stockCode
                request["stockName"] = stockName
            case .remove:
                request["stockCode"] = stockCode
            case .reorder:
                request["stockList"] = stockList?.map { stock in
                    ["stockCode": stock.stockCode, "sortOrder": stock.sortOrder]
                }
            }
            
            // 发送请求到后端
            // let response = try await networkManager.post("/api/watchlist", data: request)
            print("自选股同步到服务器: \(request)")
            
        } catch {
            print("同步到服务器失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - 数据模型

/// 自选股股票信息
public struct WatchlistStock: Identifiable, Equatable {
    public let id = UUID()
    public let stockCode: String
    public let stockName: String
    public let addedDate: Date
    public var sortOrder: Int
    
    public static func == (lhs: WatchlistStock, rhs: WatchlistStock) -> Bool {
        return lhs.stockCode == rhs.stockCode
    }
}

/// 自选股操作类型
enum WatchlistAction: String {
    case add = "add"
    case remove = "remove"
    case reorder = "reorder"
}
