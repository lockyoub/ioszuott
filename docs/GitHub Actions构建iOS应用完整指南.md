# GitHub Actions构建iOS应用完整指南

**适用于无苹果电脑、无开发者账号的iOS应用构建**

## 📋 前置条件

### GitHub仓库要求
- [x] GitHub仓库（免费账户即可）
- [x] GitHub Actions权限（默认启用）
- [x] 项目源代码已上传

### 项目文件要求
✅ **已包含的文件**：
- `StockTradingApp.swift` - 主应用文件
- `Models/` - 数据模型目录
- `Views/` - 视图组件目录  
- `Services/` - 服务层目录
- `Utils/` - 工具类目录
- `TradingDataModel.xcdatamodeld/` - Core Data模型
- `Info.plist` - 应用配置文件

📦 **自动生成的文件**：
- `StockTradingApp.xcodeproj` - Xcode项目文件
- `Package.swift` - Swift包管理
- `project.yml` - XcodeGen配置
- `AppDelegate.swift` - 应用委托
- `AppState.swift` - 应用状态管理

## 🚀 快速开始

### 步骤1: 上传代码到GitHub

```bash
# 1. 创建新的GitHub仓库
# 在GitHub网站创建名为 "ios-stock-trading-app" 的仓库

# 2. 克隆到本地
git clone https://github.com/your-username/ios-stock-trading-app.git
cd ios-stock-trading-app

# 3. 复制项目文件
# 将所有项目文件复制到仓库根目录

# 4. 提交代码
git add .
git commit -m "Initial commit: iOS股票交易应用"
git push origin main
```

### 步骤2: 配置GitHub Actions

1. **复制工作流文件**
   ```bash
   mkdir -p .github/workflows
   # 将 build-ios.yml 复制到 .github/workflows/ 目录
   ```

2. **提交工作流配置**
   ```bash
   git add .github/workflows/build-ios.yml
   git commit -m "Add GitHub Actions workflow for iOS build"
   git push origin main
   ```

### 步骤3: 触发构建

#### 自动触发（推荐）
- **Push到main分支**: 自动开始构建
- **Pull Request**: 自动验证构建
- **Push到develop分支**: 开发版本构建

#### 手动触发
1. 访问GitHub仓库 → Actions标签
2. 选择"构建iOS应用 (未签名IPA)"工作流
3. 点击"Run workflow"按钮
4. 选择构建配置（Debug/Release）
5. 点击"Run workflow"开始构建

## 🔧 构建流程详解

### 构建阶段说明

#### 1. 环境准备 (2-3分钟)
```yaml
运行环境: macOS-14 (GitHub托管)
Xcode版本: 15.4
iOS目标版本: 15.0+
Swift版本: 5.9
```

#### 2. 项目结构化 (1-2分钟)
- 创建标准Xcode项目目录结构
- 移动源文件到相应位置
- 生成Package.swift配置
- 创建Info.plist应用配置

#### 3. 项目文件生成 (2-3分钟)
- 安装XcodeGen工具
- 基于project.yml生成.xcodeproj文件
- 解析Swift代码依赖关系
- 创建缺失的基础类文件

#### 4. 编译构建 (5-8分钟)
- 清理构建缓存
- Swift代码编译
- 资源文件处理
- Core Data模型编译

#### 5. 应用归档 (2-3分钟)
- 创建.xcarchive归档文件
- 生成应用二进制文件
- 处理应用资源和依赖

#### 6. IPA导出 (1-2分钟)
- 基于ExportOptions.plist导出
- 生成未签名IPA包
- 创建构建信息文件

### 总构建时间
- **Debug配置**: 约12-18分钟
- **Release配置**: 约15-22分钟

## 📦 构建产物说明

### 下载位置
1. **GitHub Actions页面**
   - 访问仓库 → Actions → 选择具体的运行
   - 下载"StockTradingApp-unsigned-ipa-{run_number}"压缩包

2. **GitHub Releases** (仅main分支)
   - 访问仓库 → Releases
   - 下载最新的预发布版本

### 文件内容
```
StockTradingApp-unsigned-ipa-{run_number}.zip
├── StockTradingApp_{timestamp}_{commit}_unsigned.ipa  # 未签名IPA包
└── build_info.txt                                    # 构建信息
```

### 构建信息示例
```
构建信息
========
应用名称: 股票交易系统
版本: 1.0.0 (1)
构建配置: Release
构建时间: 20250703_133550
提交哈希: a1b2c3d4e5f6789...
分支: main
构建环境: GitHub Actions (macOS-14)
Xcode版本: 15.4
iOS目标版本: 15.0
```

## 📱 IPA包使用方法

### 方法1: iOS模拟器安装（推荐）

1. **使用Xcode**
   ```bash
   # 1. 打开Xcode
   # 2. Window → Devices and Simulators
   # 3. 选择iOS模拟器
   # 4. 将IPA文件拖拽到模拟器
   ```

2. **使用命令行**
   ```bash
   # 安装到模拟器
   xcrun simctl install booted /path/to/StockTradingApp.ipa
   
   # 启动应用
   xcrun simctl launch booted com.stocktrading.app
   ```

### 方法2: 重新签名安装真机

#### 使用iOS App Signer (macOS)
1. 下载[iOS App Signer](https://github.com/DanTheMan827/ios-app-signer)
2. 导入开发者证书和配置文件
3. 选择IPA文件进行重新签名
4. 使用Xcode安装到真机

#### 使用命令行工具
```bash
# 1. 解压IPA包
unzip StockTradingApp.ipa

# 2. 重新签名
codesign -f -s "iPhone Developer: Your Name" Payload/StockTradingApp.app

# 3. 重新打包
zip -r StockTradingApp_signed.ipa Payload/

# 4. 安装到设备
ios-deploy --bundle StockTradingApp_signed.ipa
```

### 方法3: 企业分发

#### 内部测试分发
1. 配置企业开发者账号
2. 生成企业分发证书
3. 重新签名IPA包
4. 通过企业分发渠道安装

#### 第三方分发平台
- **TestFlight** (需要开发者账号)
- **蒲公英** (pgyer.com)
- **Fir.im**
- **内部分发系统**

## ⚠️ 常见问题与解决方案

### 构建失败

#### 问题1: Swift编译错误
```bash
错误信息: "Cannot find 'SomeClass' in scope"
```
**解决方案**:
1. 检查Swift文件中的import语句
2. 确保所有依赖类都已定义
3. 查看GitHub Actions日志中的详细错误信息

#### 问题2: Core Data模型错误
```bash
错误信息: "CoreData model file not found"
```
**解决方案**:
1. 确保.xcdatamodeld文件结构完整
2. 检查Core Data实体定义
3. 验证模型文件路径配置

#### 问题3: 资源文件缺失
```bash
错误信息: "Resource file not found"
```
**解决方案**:
1. 检查Info.plist文件配置
2. 确保所有资源文件已上传
3. 验证Bundle ID配置

### 安装问题

#### 问题1: 模拟器安装失败
**原因**: IPA包与模拟器架构不匹配
**解决方案**:
1. 确保使用iOS 15.0+模拟器
2. 使用x86_64架构的模拟器
3. 尝试不同版本的iOS模拟器

#### 问题2: 真机安装失败
**原因**: 缺少有效的开发者证书
**解决方案**:
1. 获取Apple开发者账号
2. 生成开发者证书和配置文件
3. 使用工具重新签名IPA包

### 性能优化

#### 构建速度优化
1. **启用构建缓存**
   ```yaml
   - name: 缓存构建依赖
     uses: actions/cache@v3
     with:
       path: ~/Library/Developer/Xcode/DerivedData
       key: xcode-${{ runner.os }}-${{ hashFiles('**/*.swift') }}
   ```

2. **并行编译**
   ```bash
   xcodebuild -jobs $(sysctl -n hw.ncpu)
   ```

#### 包大小优化
1. **启用Bitcode** (Release配置)
2. **符号剥离** (Strip Symbols)
3. **资源压缩** (Asset Catalog优化)

## 🔒 安全性考虑

### 敏感信息管理

#### GitHub Secrets配置
```bash
# 在GitHub仓库设置中添加Secrets:
API_KEY: your_api_key_here
SECRET_TOKEN: your_secret_token_here
```

#### 代码中使用Secrets
```swift
// 在Swift代码中获取环境变量
if let apiKey = ProcessInfo.processInfo.environment["API_KEY"] {
    // 使用API密钥
}
```

### 构建环境安全
- GitHub Actions使用官方托管的macOS runner
- 每次构建都是全新的虚拟环境
- 构建结束后环境自动销毁
- 支持私有仓库构建

## 📊 监控与通知

### 构建状态监控

#### GitHub Status Badge
```markdown
[![iOS Build](https://github.com/your-username/ios-stock-trading-app/workflows/构建iOS应用%20(未签名IPA)/badge.svg)](https://github.com/your-username/ios-stock-trading-app/actions)
```

#### 邮件通知
```yaml
- name: 发送构建通知
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 构建历史追踪
- **成功率统计**: GitHub Actions自动统计
- **构建时间趋势**: 可通过GitHub API获取
- **下载统计**: GitHub Releases提供下载数据

## 🎯 最佳实践建议

### 分支策略
```
main (生产版本)
├── develop (开发版本)
├── feature/* (功能分支)
└── hotfix/* (热修复分支)
```

### 版本管理
```yaml
# 自动版本号生成
BUILD_NUMBER: ${{ github.run_number }}
VERSION_NAME: "1.0.0"
```

### 质量保证
```yaml
# 添加代码质量检查
- name: Swift格式检查
  run: swiftformat --lint .

- name: 代码静态分析
  run: swiftlint
```

### 自动化测试
```yaml
# 单元测试
- name: 运行单元测试
  run: |
    xcodebuild test \
      -project StockTradingApp.xcodeproj \
      -scheme StockTradingApp \
      -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📞 技术支持

### 问题反馈渠道
1. **GitHub Issues**: 项目相关问题
2. **GitHub Discussions**: 使用交流和建议
3. **Email**: 紧急技术支持

### 文档资源
- [GitHub Actions官方文档](https://docs.github.com/en/actions)
- [Xcode命令行工具指南](https://developer.apple.com/xcode/)
- [iOS开发最佳实践](https://developer.apple.com/ios/)

---

## 📝 更新日志

### v1.0.0 (2025-07-03)
- ✅ 首次发布GitHub Actions工作流
- ✅ 支持自动化iOS应用构建
- ✅ 生成未签名IPA包
- ✅ 完整的项目配置生成
- ✅ 多分支构建支持
- ✅ 自动Release创建

### 计划中的功能
- [ ] 自动化测试集成
- [ ] 代码质量检查
- [ ] 多架构支持 (Intel/Apple Silicon)
- [ ] 签名IPA生成 (需要证书)
- [ ] TestFlight自动上传

---

*本指南基于GitHub Actions和Xcode 15.4编写，适用于iOS 15.0+设备。*