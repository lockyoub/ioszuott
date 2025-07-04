//
// DataSyncManager.swift - DEPRECATED
// 此文件已被废弃，请使用UnifiedDataService替代
// 废弃日期: 2025-06-29
// 原因: P0-2修复 - 统一数据同步逻辑，解决精度问题
//

/*
 ⚠️ 废弃通知 ⚠️
 
 DataSyncManager已被废弃，原因如下：
 
 1. 使用Double类型处理金融数据，存在精度丢失风险
 2. 与UnifiedDataService形成重复和冲突的数据同步逻辑
 3. 使用的DataModels与新版UnifiedModels不兼容
 
 请使用以下替代方案：
 
 旧代码:
 ```swift
 await DataSyncManager.shared.syncAllData()
 ```
 
 新代码:
 ```swift
 await UnifiedSyncManager.shared.syncAllData()
 ```
 
 或直接使用:
 ```swift
 try await UnifiedDataService.shared.performFullDataSync()
 ```
 
 迁移指南:
 1. 将所有DataSyncManager.shared调用替换为UnifiedSyncManager.shared
 2. 确保使用UnifiedModels中的实体类型
 3. 运行数据迁移工具进行数据转换
 */

// 保留原始代码用于参考，但添加编译时警告
#warning("DataSyncManager已废弃，请使用UnifiedDataService替代")

// 原始DataSyncManager代码被移动到此处作为参考
// 实际项目中应删除此文件

import Foundation
import CoreData

/*
 此处保留原始DataSyncManager代码作为参考
 实际使用时应删除此文件，并确保所有引用都已迁移到UnifiedDataService
 */
