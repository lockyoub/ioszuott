/*
 安全交易服务
 作者: MiniMax Agent
 创建日期: 2025-06-28
 
 重构后的交易服务，所有交易都通过后端API进行，确保安全性和一致性
 */

import Foundation
import CoreData
import Combine

/// 安全交易服务类 - 所有交易通过后端API
@MainActor
public class SecureTradingService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var orders: [OrderEntity] = []
    @Published var trades: [TradeEntity] = []
    @Published var accountInfo: AccountInfo = AccountInfo()
    @Published var isTrading: Bool = false
    @Published var dailyPnL: Double = 0.0
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private var networkManager: NetworkManager
    private var orderMonitorTimer: Timer?
    
    // MARK: - 初始化
    init() {
        self.networkManager = NetworkManager.shared
        setupOrderMonitoring()
        loadExistingOrders()
    }
    
    deinit {
        orderMonitorTimer?.invalidate()
    }
    
    // MARK: - 连接管理
    
    /// 连接到后端交易服务
    /// - Returns: 连接是否成功
    public func connectToTradingService() async -> Bool {
        connectionStatus = .connecting
        
        do {
            // 验证后端连接
            let healthResponse: HealthResponse = try await networkManager.get("/api/health")
            
            if healthResponse.status == "healthy" {
                isConnected = true
                connectionStatus = .connected
                
                // 获取账户信息
                await refreshAccountInfo()
                
                // 同步订单状态
                await syncOrderStatus()
                
                print("成功连接到后端交易服务")
                return true
            } else {
                connectionStatus = .failed
                print("后端服务不健康")
                return false
            }
        } catch {
            connectionStatus = .failed
            print("连接后端服务失败: \(error)")
            return false
        }
    }
    
    /// 断开连接
    public func disconnect() {
        isConnected = false
        connectionStatus = .disconnected
        print("已断开后端交易服务连接")
    }
    
    // MARK: - 订单管理
    
    /// 下单 - 通过后端API
    /// - Parameter order: 订单请求
    /// - Returns: 订单响应
    public func submitOrder(order: OrderRequest) async -> OrderResponse {
        guard isConnected else {
            return OrderResponse(
                success: false,
                orderId: nil,
                message: "未连接到交易服务",
                errorCode: "CONNECTION_ERROR"
            )
        }
        
        isTrading = true
        defer { isTrading = false }
        
        do {
            // 通过后端API提交订单
            let endpoint = "/api/v1/orders/submit"
            let response: OrderResponse = try await networkManager.post(endpoint, body: order)
            
            if response.success, let orderId = response.orderId {
                // 创建本地订单记录
                let orderEntity = createOrderEntity(from: order, orderId: orderId)
                orders.append(orderEntity)
                
                // 开始跟踪订单状态
                await trackOrderExecution(orderId: orderId)
                
                print("订单提交成功: \(orderId)")
            } else {
                print("订单提交失败: \(response.message)")
            }
            
            return response
        } catch {
            print("提交订单错误: \(error)")
            return OrderResponse(
                success: false,
                orderId: nil,
                message: "提交订单失败: \(error.localizedDescription)",
                errorCode: "SUBMIT_ORDER_ERROR"
            )
        }
    }
    
    /// 取消订单 - 通过后端API
    /// - Parameter orderId: 订单ID
    /// - Returns: 取消是否成功
    public func cancelOrder(orderId: String) async -> Bool {
        guard isConnected else {
            print("未连接到交易服务")
            return false
        }
        
        do {
            let endpoint = "/api/v1/orders/\(orderId)/cancel"
            let response: CancelOrderResponse = try await networkManager.post(endpoint, body: ["orderId": orderId])
            
            if response.success {
                // 更新本地订单状态
                if let orderIndex = orders.firstIndex(where: { $0.orderId == orderId }) {
                    orders[orderIndex].status = OrderStatus.cancelled.rawValue
                    orders[orderIndex].updateTime = Date()
                    saveContext()
                }
                
                print("订单取消成功: \(orderId)")
            } else {
                print("订单取消失败: \(response.message)")
            }
            
            return response.success
        } catch {
            print("取消订单错误: \(error)")
            return false
        }
    }
    
    /// 查询订单状态 - 通过后端API
    /// - Parameter orderId: 订单ID
    /// - Returns: 订单状态
    public func queryOrderStatus(orderId: String) async -> OrderStatus? {
        guard isConnected else {
            return nil
        }
        
        do {
            let endpoint = "/api/v1/orders/\(orderId)/status"
            let response: OrderStatusResponse = try await networkManager.get(endpoint)
            
            if let status = OrderStatus(rawValue: response.status) {
                // 更新本地订单状态
                if let orderIndex = orders.firstIndex(where: { $0.orderId == orderId }) {
                    orders[orderIndex].status = status.rawValue
                    orders[orderIndex].updateTime = Date()
                    saveContext()
                }
                
                return status
            }
            
            return nil
        } catch {
            print("查询订单状态错误: \(error)")
            return nil
        }
    }
    
    /// 获取账户信息 - 通过后端API
    public func refreshAccountInfo() async {
        guard isConnected else { return }
        
        do {
            let endpoint = "/api/v1/account/info"
            let response: AccountInfoResponse = try await networkManager.get(endpoint)
            
            accountInfo = AccountInfo(
                totalAssets: response.totalAssets,
                availableCash: response.availableCash,
                positionValue: response.positionValue,
                totalPnL: response.totalPnL,
                dayPnL: response.dayPnL
            )
            
            dailyPnL = response.dayPnL
            
            print("账户信息已更新")
        } catch {
            print("获取账户信息错误: \(error)")
        }
    }
    
    /// 获取持仓信息 - 通过后端API
    public func getPositions() async -> [Position] {
        guard isConnected else { return [] }
        
        do {
            let endpoint = "/api/v1/positions"
            let response: PositionsResponse = try await networkManager.get(endpoint)
            return response.positions
        } catch {
            print("获取持仓信息错误: \(error)")
            return []
        }
    }
    
    /// 跟踪订单执行
    /// - Parameter orderId: 订单ID
    public func trackOrderExecution(orderId: String) async {
        var attempts = 0
        let maxAttempts = 60 // 最多跟踪60次，每次间隔5秒
        
        while attempts < maxAttempts {
            if let status = await queryOrderStatus(orderId: orderId) {
                switch status {
                case .filled:
                    // 订单完全成交，获取成交详情
                    await handleOrderFilled(orderId: orderId)
                    return
                case .cancelled, .rejected:
                    // 订单已取消或被拒绝，停止跟踪
                    print("订单\(orderId)已取消或被拒绝")
                    return
                case .partiallyFilled:
                    // 部分成交，继续跟踪
                    await handlePartialFill(orderId: orderId)
                case .pending:
                    // 继续等待
                    break
                }
            }
            
            attempts += 1
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 等待5秒
        }
        
        print("订单\(orderId)跟踪超时")
    }
    
    // MARK: - 私有方法
    
    /// 处理订单成交
    /// - Parameter orderId: 订单ID
    private func handleOrderFilled(orderId: String) async {
        guard let order = orders.first(where: { $0.orderId == orderId }) else { return }
        
        do {
            // 从后端获取成交详情
            let endpoint = "/api/v1/orders/\(orderId)/fills"
            let fillDetails: OrderFillResponse = try await networkManager.get(endpoint)
            
            // 创建交易记录
            let trade = createTradeEntity(from: order, fillDetails: fillDetails)
            trades.append(trade)
            
            // 刷新账户信息和持仓
            await refreshAccountInfo()
            
            print("订单\(orderId)完全成交")
        } catch {
            print("处理订单成交错误: \(error)")
        }
    }
    
    /// 处理部分成交
    /// - Parameter orderId: 订单ID
    private func handlePartialFill(orderId: String) async {
        guard let order = orders.first(where: { $0.orderId == orderId }) else { return }
        
        do {
            // 从后端获取部分成交详情
            let endpoint = "/api/v1/orders/\(orderId)/fills"
            let fillDetails: OrderFillResponse = try await networkManager.get(endpoint)
            
            // 创建部分交易记录
            if fillDetails.filledQuantity > 0 {
                let trade = createTradeEntity(from: order, fillDetails: fillDetails)
                trades.append(trade)
            }
            
            print("订单\(orderId)部分成交: \(fillDetails.filledQuantity)")
        } catch {
            print("处理部分成交错误: \(error)")
        }
    }
    
    /// 创建订单实体
    /// - Parameters:
    ///   - order: 订单请求
    ///   - orderId: 订单ID
    /// - Returns: 订单实体
    private func createOrderEntity(from order: OrderRequest, orderId: String) -> OrderEntity {
        let context = persistenceController.container.viewContext
        let orderEntity = OrderEntity(context: context)
        
        orderEntity.orderId = orderId
        orderEntity.symbol = order.symbol
        orderEntity.orderType = order.orderType.rawValue
        orderEntity.quantity = Int32(order.quantity)
        orderEntity.price = order.price
        orderEntity.status = OrderStatus.pending.rawValue
        orderEntity.createTime = Date()
        orderEntity.updateTime = Date()
        
        saveContext()
        return orderEntity
    }
    
    /// 创建交易实体
    /// - Parameters:
    ///   - order: 订单实体
    ///   - fillDetails: 成交详情
    /// - Returns: 交易实体
    private func createTradeEntity(from order: OrderEntity, fillDetails: OrderFillResponse) -> TradeEntity {
        let context = persistenceController.container.viewContext
        let trade = TradeEntity(context: context)
        
        trade.tradeId = fillDetails.tradeId
        trade.orderId = order.orderId
        trade.symbol = order.symbol
        trade.tradeType = order.orderType
        trade.quantity = Int32(fillDetails.filledQuantity)
        trade.price = fillDetails.fillPrice
        trade.amount = fillDetails.fillPrice * Double(fillDetails.filledQuantity)
        trade.commission = fillDetails.commission
        trade.timestamp = fillDetails.fillTime
        
        saveContext()
        return trade
    }
    
    /// 设置订单监控
    private func setupOrderMonitoring() {
        orderMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.monitorPendingOrders()
            }
        }
    }
    
    /// 监控待处理订单
    private func monitorPendingOrders() async {
        let pendingOrders = orders.filter { order in
            let status = OrderStatus(rawValue: order.status) ?? .pending
            return status == .pending || status == .partiallyFilled
        }
        
        for order in pendingOrders {
            if let orderId = order.orderId {
                await trackOrderExecution(orderId: orderId)
            }
        }
    }
    
    /// 同步订单状态
    private func syncOrderStatus() async {
        guard isConnected else { return }
        
        for order in orders {
            if let orderId = order.orderId {
                _ = await queryOrderStatus(orderId: orderId)
            }
        }
    }
    
    /// 加载现有订单
    private func loadExistingOrders() {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<OrderEntity>(entityName: "OrderEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OrderEntity.createTime, ascending: false)]
        
        do {
            orders = try context.fetch(request)
        } catch {
            print("加载订单失败: \(error)")
        }
    }
    
    /// 保存CoreData上下文
    private func saveContext() {
        let context = persistenceController.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存上下文失败: \(error)")
            }
        }
    }
}

// MARK: - 响应数据模型

struct HealthResponse: Codable {
    let status: String
    let timestamp: Date
}

struct OrderResponse: Codable {
    let success: Bool
    let orderId: String?
    let message: String
    let errorCode: String?
}

struct CancelOrderResponse: Codable {
    let success: Bool
    let message: String
}

struct OrderStatusResponse: Codable {
    let status: String
    let message: String?
}

struct AccountInfoResponse: Codable {
    let totalAssets: Double
    let availableCash: Double
    let positionValue: Double
    let totalPnL: Double
    let dayPnL: Double
}

struct PositionsResponse: Codable {
    let positions: [Position]
}

struct OrderFillResponse: Codable {
    let tradeId: String
    let filledQuantity: Int
    let fillPrice: Double
    let commission: Double
    let fillTime: Date
}
