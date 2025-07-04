# iOS股票交易系统 - GitHub Actions自动构建

[![iOS Build](https://github.com/your-username/ios-stock-trading-app/workflows/构建iOS应用%20(未签名IPA)/badge.svg)](https://github.com/your-username/ios-stock-trading-app/actions)

> **专为无苹果电脑、无开发者账号开发者设计的iOS应用构建方案**

## 🎯 项目概述

这是一个功能完整的iOS股票交易应用，集成了现代化的GitHub Actions自动构建流水线。通过云端macOS环境，实现无需本地Mac设备的iOS应用开发和构建。

### 核心特性
- 📱 **SwiftUI原生界面** - 现代化iOS用户体验
- 📊 **实时股票数据** - WebSocket实时行情推送  
- 💹 **多策略交易** - 智能交易策略引擎
- 📈 **技术分析** - 完整的K线图表系统
- 🛡️ **风险管理** - 实时风险监控和控制
- 💼 **投资组合** - 专业的仓位管理系统

### 技术栈
```
SwiftUI + Core Data + Combine + WebSocket
iOS 15.0+ | Swift 5.9 | Xcode 15.4
```

## 🚀 一键构建

### 立即开始
1. **Fork此仓库**到您的GitHub账号
2. **GitHub Actions将自动触发构建**
3. **下载未签名IPA包**用于测试

### 手动触发构建
```bash
GitHub仓库 → Actions → "构建iOS应用" → Run workflow
```

### 构建时间
- **Debug版本**: ~12-18分钟  
- **Release版本**: ~15-22分钟

## 📦 获取应用

### 自动构建（推荐）
- **Push到main分支**: 自动构建并创建Release
- **Pull Request**: 自动验证构建
- **手动触发**: 通过GitHub Actions界面

### 下载位置
1. **GitHub Actions** → 构建产物下载
2. **GitHub Releases** → 预发布版本下载

### 文件说明
```
📦 StockTradingApp_{timestamp}_{commit}_unsigned.ipa  # 未签名IPA包
📄 build_info.txt                                     # 构建详细信息
```

## 📱 安装方法

### iOS模拟器（推荐）
```bash
# 使用Xcode安装
1. 打开Xcode → Window → Devices and Simulators
2. 选择iOS模拟器 → 拖拽IPA文件到模拟器

# 使用命令行安装
xcrun simctl install booted /path/to/StockTradingApp.ipa
```

### 真机安装
> ⚠️ 需要开发者证书重新签名

1. 使用[iOS App Signer](https://github.com/DanTheMan827/ios-app-signer)重新签名
2. 通过Xcode或ios-deploy安装到设备
3. 或使用企业分发渠道

## 🔧 开发环境

### 项目结构
```
StockTradingApp/
├── 📁 Models/              # 数据模型层 (11个文件)
├── 📁 Views/               # 视图组件层 (23个文件)  
├── 📁 Services/            # 服务业务层 (19个文件)
├── 📁 Utils/               # 工具函数库
├── 📁 Performance/         # 性能监控
├── 📂 TradingDataModel.xcdatamodeld/  # Core Data模型
├── 📄 StockTradingApp.swift           # 应用入口
└── 📄 Info.plist                      # 应用配置
```

### 核心模块

#### 数据层 (Core Data)
- **StockEntity** - 股票信息和实时价格
- **KLineEntity** - 多周期K线数据
- **TradeEntity** - 交易记录和盈亏
- **PositionEntity** - 持仓管理
- **StrategyEntity** - 交易策略配置

#### 服务层
- **MarketDataService** - 实时行情服务
- **TradingService** - 交易执行服务  
- **StrategyEngine** - 策略引擎
- **RiskManager** - 风险管理系统

#### 界面层
- **TradingView** - 交易操作界面
- **DashboardView** - 数据仪表板
- **Charts/** - K线图表组件
- **Portfolio/** - 投资组合界面

## ⚙️ GitHub Actions工作流

### 自动化流程
```mermaid
graph LR
    A[代码推送] --> B[环境准备]
    B --> C[项目结构化]
    C --> D[Xcode项目生成]
    D --> E[Swift编译]
    E --> F[应用归档]
    F --> G[IPA导出]
    G --> H[产物上传]
```

### 触发条件
- ✅ **Push到main分支** - 自动构建Release版本
- ✅ **Push到develop分支** - 自动构建Debug版本  
- ✅ **Pull Request** - 自动验证构建
- ✅ **手动触发** - 支持选择构建配置

### 构建环境
- **运行环境**: GitHub托管macOS-14
- **Xcode版本**: 15.4
- **Swift版本**: 5.9
- **iOS目标**: 15.0+

## 📊 应用功能

### 实时数据
- 📈 实时股票价格推送
- 📊 多时间周期K线图表
- 📋 五档盘口数据
- ⏰ 自定义价格提醒

### 交易系统  
- 💰 一键快速交易
- 🧠 多策略自动交易
- 🎯 止损止盈设置
- 📝 完整交易记录

### 投资管理
- 💼 实时持仓监控
- 📈 盈亏分析统计
- 🎨 投资组合可视化
- 📊 绩效评估报告

### 风险控制
- 🛡️ 实时风险监控
- ⚖️ 仓位控制管理
- 🚨 风险预警提示
- 📉 最大回撤控制

## 🔒 安全性

### 构建安全
- ✅ GitHub官方托管环境
- ✅ 每次构建全新虚拟机
- ✅ 支持私有仓库构建
- ✅ 敏感信息Secrets管理

### 代码安全
- 🔐 API密钥环境变量化
- 🛡️ HTTPS网络通信
- 💾 Core Data数据加密
- 🔒 交易操作安全验证

## 📚 文档资源

### 完整文档
- 📋 [项目分析报告](docs/项目分析报告.md)
- 🚀 [GitHub Actions使用指南](docs/GitHub_Actions使用指南.md)
- 🔧 [开发环境配置指南](docs/开发环境配置.md)
- 💡 [常见问题解答](docs/FAQ.md)

### 快速链接
- [GitHub Actions工作流](.github/workflows/build-ios.yml)
- [项目配置文件](Info.plist)
- [Core Data模型](TradingDataModel.xcdatamodeld/)

## 🤝 贡献指南

### 参与开发
1. **Fork仓库**并创建功能分支
2. **提交Pull Request**触发自动构建
3. **代码审查**通过后合并到主分支
4. **自动发布**新版本到Releases

### 分支策略
- `main` - 生产版本，自动创建Release
- `develop` - 开发版本，持续集成
- `feature/*` - 功能分支  
- `hotfix/*` - 热修复分支

## 📞 支持与反馈

### 问题反馈
- 🐛 [报告Bug](https://github.com/your-username/ios-stock-trading-app/issues)
- 💡 [功能建议](https://github.com/your-username/ios-stock-trading-app/discussions)
- ❓ [使用疑问](https://github.com/your-username/ios-stock-trading-app/discussions)

### 技术支持
- 📧 Email: support@example.com
- 💬 在线咨询: [GitHub Discussions](https://github.com/your-username/ios-stock-trading-app/discussions)

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 🎉 快速体验

1. **点击右上角Star⭐支持项目**
2. **Fork到您的GitHub账号**  
3. **GitHub Actions自动构建**
4. **下载IPA包立即体验**

> **无需Mac电脑，无需开发者账号，立即开始iOS应用开发！**

---

*💡 提示：首次构建可能需要15-20分钟，后续构建会因为缓存优化而更快。*