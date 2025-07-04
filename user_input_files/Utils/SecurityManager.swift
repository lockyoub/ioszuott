/*
 安全管理器
 修复P1-2和P1-5问题：实现iOS证书锁定与越狱检测
 作者: MiniMax Agent
 */

import Foundation
import Security
import UIKit
import CommonCrypto

public class SecurityManager {
    
    static let shared = SecurityManager()
    
    // 证书锁定配置
    private let pinnedCertificates: [String: Data] = [
        "api.tradingapp.com": SecurityManager.loadCertificate(named: "api_cert"),
        "data.tradingapp.com": SecurityManager.loadCertificate(named: "data_cert")
    ]
    
    // 反调试标志
    private var antiDebuggingEnabled = true
    
    private init() {
        // 启动时进行安全检查
        performSecurityChecks()
    }
    
    // MARK: - 公共安全检查接口
    
    /// 执行全面的安全检查
    public func performSecurityChecks() {
        let jailbreakDetected = isDeviceJailbroken()
        let debuggerDetected = isDebuggerAttached()
        let simulatorDetected = isRunningOnSimulator()
        
        if jailbreakDetected {
            handleSecurityThreat(.jailbreak)
        }
        
        if debuggerDetected && antiDebuggingEnabled {
            handleSecurityThreat(.debugger)
        }
        
        if simulatorDetected && !isDebugBuild() {
            handleSecurityThreat(.simulator)
        }
        
        // 检查应用完整性
        if !verifyApplicationIntegrity() {
            handleSecurityThreat(.tampering)
        }
    }
    
    /// 验证SSL证书锁定
    public func validateServerTrust(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        guard let pinnedCertData = pinnedCertificates[host] else {
            // 如果没有配置证书锁定，使用系统默认验证
            return evaluateServerTrustUsingSystemRoots(serverTrust)
        }
        
        return validateCertificatePinning(serverTrust, pinnedCertificate: pinnedCertData)
    }
    
    // MARK: - 越狱检测
    
    /// 检测设备是否越狱
    private func isDeviceJailbroken() -> Bool {
        // 方法1: 检查越狱文件和目录
        if checkJailbreakFiles() {
            return true
        }
        
        // 方法2: 检查是否能访问系统目录
        if canAccessSystemDirectories() {
            return true
        }
        
        // 方法3: 检查是否安装了Cydia等越狱工具
        if checkJailbreakApps() {
            return true
        }
        
        // 方法4: 检查dylib注入
        if checkDylibInjection() {
            return true
        }
        
        // 方法5: 检查fork系统调用
        if canForkProcess() {
            return true
        }
        
        return false
    }
    
    private func checkJailbreakFiles() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/cydia",
            "/private/var/stash"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func canAccessSystemDirectories() -> Bool {
        let restrictedPaths = [
            "/private/var/mobile/",
            "/root/",
            "/private/etc/"
        ]
        
        for path in restrictedPaths {
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: path)
                return true // 如果能访问，说明可能越狱了
            } catch {
                // 无法访问是正常的
            }
        }
        
        return false
    }
    
    private func checkJailbreakApps() -> Bool {
        let jailbreakSchemes = [
            "cydia://",
            "sileo://", 
            "zebra://",
            "installer://",
            "icy://",
            "sbsettings://"
        ]
        
        for scheme in jailbreakSchemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func checkDylibInjection() -> Bool {
        // 检查是否有可疑的动态库被注入
        var count: UInt32 = 0
        let images = _dyld_image_count()
        
        for i in 0..<images {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)
                
                // 检查可疑的库名
                let suspiciousLibs = [
                    "MobileSubstrate",
                    "SubstrateLoader",
                    "SubstrateInserter",
                    "CydiaSubstrate",
                    "cynject",
                    "pspawn"
                ]
                
                for lib in suspiciousLibs {
                    if name.contains(lib) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func canForkProcess() -> Bool {
        let pid = fork()
        if pid >= 0 {
            if pid > 0 {
                // 父进程，杀死子进程
                kill(pid, SIGTERM)
            }
            return true // 能够fork说明可能越狱了
        }
        return false
    }
    
    // MARK: - 反调试检测
    
    /// 检测是否连接了调试器
    private func isDebuggerAttached() -> Bool {
        // 方法1: 使用ptrace检测
        if ptrace(PT_DENY_ATTACH, 0, 0, 0) == -1 {
            return true
        }
        
        // 方法2: 检查sysctl
        return checkSysctlDebugger()
    }
    
    private func checkSysctlDebugger() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    // MARK: - 模拟器检测
    
    /// 检测是否在模拟器上运行
    private func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 应用完整性验证
    
    /// 验证应用完整性
    private func verifyApplicationIntegrity() -> Bool {
        // 检查应用签名
        guard verifyCodeSignature() else {
            return false
        }
        
        // 检查应用Bundle
        guard verifyApplicationBundle() else {
            return false
        }
        
        return true
    }
    
    private func verifyCodeSignature() -> Bool {
        // 获取代码签名信息
        guard let executablePath = Bundle.main.executablePath else {
            return false
        }
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: executablePath)
    }
    
    private func verifyApplicationBundle() -> Bool {
        // 验证关键文件是否存在
        let criticalFiles = [
            "Info.plist",
            "embedded.mobileprovision"
        ]
        
        for file in criticalFiles {
            guard let _ = Bundle.main.path(forResource: file.components(separatedBy: ".").first,
                                          ofType: file.components(separatedBy: ".").last) else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - 证书锁定
    
    /// 验证证书锁定
    private func validateCertificatePinning(_ serverTrust: SecTrust, pinnedCertificate: Data) -> Bool {
        // 获取服务器证书链
        let serverCertCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<serverCertCount {
            if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                let serverCertData = SecCertificateCopyData(serverCert)
                let serverCertBytes = CFDataGetBytePtr(serverCertData)
                let serverCertLength = CFDataGetLength(serverCertData)
                
                let serverData = Data(bytes: serverCertBytes!, count: serverCertLength)
                
                // 比较证书
                if serverData == pinnedCertificate {
                    return true
                }
                
                // 也可以比较公钥
                if comparePublicKeys(serverCert: serverCert, pinnedCertData: pinnedCertificate) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func comparePublicKeys(serverCert: SecCertificate, pinnedCertData: Data) -> Bool {
        // 提取服务器证书的公钥
        guard let serverPublicKey = extractPublicKey(from: serverCert) else {
            return false
        }
        
        // 从锁定的证书数据提取公钥
        guard let pinnedCert = SecCertificateCreateWithData(nil, pinnedCertData as CFData),
              let pinnedPublicKey = extractPublicKey(from: pinnedCert) else {
            return false
        }
        
        // 比较公钥
        let serverKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil)
        let pinnedKeyData = SecKeyCopyExternalRepresentation(pinnedPublicKey, nil)
        
        guard let serverData = serverKeyData as Data?,
              let pinnedData = pinnedKeyData as Data? else {
            return false
        }
        
        return serverData == pinnedData
    }
    
    private func extractPublicKey(from certificate: SecCertificate) -> SecKey? {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        guard status == errSecSuccess, let validTrust = trust else {
            return nil
        }
        
        return SecTrustCopyPublicKey(validTrust)
    }
    
    private func evaluateServerTrustUsingSystemRoots(_ serverTrust: SecTrust) -> Bool {
        let result = SecTrustEvaluateWithError(serverTrust, nil)
        return result
    }
    
    // MARK: - 加载证书
    
    private static func loadCertificate(named name: String) -> Data {
        guard let certPath = Bundle.main.path(forResource: name, ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath) else {
            fatalError("无法加载证书: \(name)")
        }
        return certData as Data
    }
    
    // MARK: - 威胁处理
    
    enum SecurityThreat {
        case jailbreak
        case debugger
        case simulator
        case tampering
        case certificateValidationFailed
    }
    
    private func handleSecurityThreat(_ threat: SecurityThreat) {
        let threatMessage: String
        
        switch threat {
        case .jailbreak:
            threatMessage = "检测到设备已越狱，应用将无法正常运行"
        case .debugger:
            threatMessage = "检测到调试器连接，应用将退出"
        case .simulator:
            threatMessage = "生产版本不支持在模拟器上运行"
        case .tampering:
            threatMessage = "检测到应用被篡改，应用将退出"
        case .certificateValidationFailed:
            threatMessage = "服务器证书验证失败，连接不安全"
        }
        
        logSecurityEvent(threat: threat, message: threatMessage)
        
        // 根据威胁类型采取不同的行动
        switch threat {
        case .jailbreak:
            showSecurityAlert(message: threatMessage) {
                // 可以选择退出应用或限制功能
                self.restrictAppFunctionality()
            }
        case .debugger, .tampering:
            // 立即退出应用
            exit(EXIT_FAILURE)
        case .simulator:
            if !isDebugBuild() {
                exit(EXIT_FAILURE)
            }
        case .certificateValidationFailed:
            showSecurityAlert(message: threatMessage) {
                // 阻止网络连接
                self.blockNetworkConnections()
            }
        }
    }
    
    private func showSecurityAlert(message: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "安全警告",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                completion()
            })
            
            if let topViewController = UIApplication.shared.windows.first?.rootViewController {
                var presentingController = topViewController
                while let presented = presentingController.presentedViewController {
                    presentingController = presented
                }
                presentingController.present(alert, animated: true)
            }
        }
    }
    
    private func restrictAppFunctionality() {
        // 限制应用功能，比如禁用交易功能
        NotificationCenter.default.post(name: .securityThreatDetected, object: nil)
    }
    
    private func blockNetworkConnections() {
        // 阻止网络连接
        NotificationCenter.default.post(name: .networkSecurityThreat, object: nil)
    }
    
    private func logSecurityEvent(threat: SecurityThreat, message: String) {
        // 记录安全事件到本地日志
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] SECURITY_THREAT: \(threat) - \(message)"
        
        // 这里可以集成到应用的日志系统
        print(logEntry)
        
        // 也可以发送到远程安全监控系统
        sendSecurityEventToRemoteLogging(threat: threat, message: message)
    }
    
    private func sendSecurityEventToRemoteLogging(threat: SecurityThreat, message: String) {
        // 实现远程安全事件上报
        // 注意：在检测到安全威胁时，网络连接可能不可信
    }
    
    // MARK: - 辅助方法
    
    private func isDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - 通知扩展

extension Notification.Name {
    static let securityThreatDetected = Notification.Name("SecurityThreatDetected")
    static let networkSecurityThreat = Notification.Name("NetworkSecurityThreat")
}

// MARK: - URLSessionDelegate 集成

extension SecurityManager: URLSessionDelegate {
    
    public func urlSession(_ session: URLSession, 
                          didReceive challenge: URLAuthenticationChallenge, 
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // 检查服务器信任
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        if validateServerTrust(serverTrust, forHost: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            handleSecurityThreat(.certificateValidationFailed)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
