//
//  AuthManager.swift
//  股票做T系统
//
//  Created by MiniMax Agent on 2025-06-27.
//  认证管理器 - 处理JWT token的存储和认证
//

import Foundation
import Security
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let keychainService = "com.stocktrading.app"
    private let tokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"  // 新增：刷新令牌存储
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - 认证状态检查 【P0-1安全修复】
    func checkAuthenticationStatus() {
        // 检查本地是否有token
        guard let token = getStoredToken(), !token.isEmpty else {
            self.isAuthenticated = false
            return
        }

        // 通过调用一个受保护的API端点来验证token（服务端验证）
        Task {
            do {
                // 假设 NetworkManager 中有一个验证当前用户的API
                let user = try await NetworkManager.shared.fetchCurrentUser()
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } catch {
                // 如果API调用失败（例如401），则认为token无效
                DispatchQueue.main.async {
                    self.logout() // logout会清理token并更新UI状态
                }
            }
        }
    }
    
    // MARK: - 登录
    func login(username: String, password: String) async throws {
        let loginData = LoginRequest(username: username, password: password)
        
        // 发送登录请求
        let response = try await NetworkManager.shared.login(loginData)
        
        // 存储access token和refresh token
        try storeToken(response.accessToken)
        try storeRefreshToken(response.refreshToken)
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUser = User(
                id: 0, // 从token解析或API获取
                username: username,
                email: nil
            )
        }
    }
    
    // MARK: - 登出
    func logout() {
        clearStoredToken()
        clearStoredRefreshToken()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    // MARK: - Token管理
    func getStoredToken() -> String? {
        return KeychainHelper.load(key: tokenKey, service: keychainService)
    }
    
    private func storeToken(_ token: String) throws {
        let success = KeychainHelper.save(
            data: token,
            key: tokenKey,
            service: keychainService
        )
        if !success {
            throw AuthError.tokenStorageError
        }
    }
    
    private func clearStoredToken() {
        KeychainHelper.delete(key: tokenKey, service: keychainService)
    }
    
    // MARK: - 刷新令牌管理
    func getStoredRefreshToken() -> String? {
        return KeychainHelper.load(key: refreshTokenKey, service: keychainService)
    }
    
    private func storeRefreshToken(_ token: String) throws {
        let success = KeychainHelper.save(
            data: token,
            key: refreshTokenKey,
            service: keychainService
        )
        if !success {
            throw AuthError.tokenStorageError
        }
    }
    
    private func clearStoredRefreshToken() {
        KeychainHelper.delete(key: refreshTokenKey, service: keychainService)
    }
    
    /// 【P1功能实现】刷新访问令牌
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = getStoredRefreshToken() else {
            throw AuthError.noRefreshToken
        }
        
        do {
            let response = try await NetworkManager.shared.refreshToken(refreshToken)
            
            // 更新存储的令牌
            try storeToken(response.accessToken)
            try storeRefreshToken(response.refreshToken)
            
            print("令牌刷新成功")
        } catch {
            // 刷新失败，清除所有令牌并要求重新登录
            clearStoredToken()
            clearStoredRefreshToken()
            
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
            
            throw AuthError.refreshTokenExpired
        }
    }
    
    /// 检查令牌是否即将过期并自动刷新 【P0-1安全修复】
    func checkAndRefreshTokenIfNeeded() async {
        guard let token = getStoredToken() else { return }
        
        // 【安全修复】从JWT中解析过期时间，但不用于安全验证，只用于判断是否需要"尝试"刷新
        // 真正的安全验证在网络请求的拦截器中处理401错误
        if isTokenNearExpiry(token, minutesToExpiry: 5) {
            do {
                try await refreshTokenIfNeeded()
            } catch {
                print("自动刷新令牌失败: \(error)")
            }
        }
    }
    
    private func isTokenNearExpiry(_ token: String, minutesToExpiry: Double) -> Bool {
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return true }
        
        guard let payloadData = Data(base64Encoded: components[1].base64URLDecoded()) else {
            return true
        }
        
        do {
            if let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
               let exp = payload["exp"] as? TimeInterval {
                let expirationDate = Date(timeIntervalSince1970: exp)
                let warningTime = Date().addingTimeInterval(minutesToExpiry * 60)
                return expirationDate <= warningTime
            }
        } catch {
            print("JWT解析失败: \(error)")
            return true
        }
        
        return true
    }
    
    // 【P0-1安全修复】移除isTokenValid方法
    // 原因：客户端本地JWT校验存在安全漏洞，可以绕过服务端的令牌吊销机制
    // 修复方案：所有令牌验证统一通过服务端API进行
    
    // MARK: - 获取认证头
    func getAuthorizationHeader() -> String? {
        guard let token = getStoredToken() else { return nil }
        return "Bearer \(token)"
    }
}

// MARK: - 数据模型
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String  // 新增：刷新令牌
    let tokenType: String
    let expiresIn: Int
    let refreshExpiresIn: Int  // 新增：刷新令牌过期时间
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
    }
}

struct User: Codable {
    let id: Int
    let username: String
    let email: String?
}

enum AuthError: Error {
    case tokenStorageError
    case invalidCredentials
    case networkError
    case noRefreshToken
    case refreshTokenExpired
    
    var localizedDescription: String {
        switch self {
        case .tokenStorageError:
            return "Token存储失败"
        case .invalidCredentials:
            return "用户名或密码错误"
        case .networkError:
            return "网络连接错误"
        case .noRefreshToken:
            return "没有可用的刷新令牌"
        case .refreshTokenExpired:
            return "刷新令牌已过期，请重新登录"
        }
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static func save(data: String, key: String, service: String) -> Bool {
        let dataToStore = data.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataToStore
        ]
        
        // 删除现有项目
        SecItemDelete(query as CFDictionary)
        
        // 添加新项目
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func load(key: String, service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    static func delete(key: String, service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - JWT解码扩展
extension String {
    /// 【安全修复】JWT base64URL解码支持
    func base64URLDecoded() -> String {
        var base64 = self
        // 添加必要的填充
        while base64.count % 4 != 0 {
            base64 += "="
        }
        // 替换URL安全字符
        base64 = base64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        return base64
    }
}
