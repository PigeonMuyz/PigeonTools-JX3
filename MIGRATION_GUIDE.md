# DungeonStat 数据迁移指南

## 概述

本指南将帮助你安全地将 DungeonStat 应用从 V1 版本升级到 V2 版本，解决以下关键问题：

1. ✅ **修复内存管理问题**：使用 UUID 代替 GameCharacter 对象作为字典键
2. ✅ **添加网络重试机制**：提高 API 请求的可靠性
3. ✅ **重构常量管理**：统一管理所有配置项
4. 🚧 **数据持久化升级**：未来将迁移到 Core Data（V3）

## 迁移策略

我们采用**渐进式、可回滚**的迁移策略，确保用户数据安全：

```
V1 (当前) → V2 (内存优化) → V3 (Core Data双轨) → V4 (完全Core Data)
```

### 迁移阶段

| 阶段 | 版本 | 描述 | 风险级别 | 是否可回滚 |
|------|------|------|----------|-----------|
| 1️⃣ | V1 → V2 | 修复字典键，保持 UserDefaults | 🟢 低 | ✅ 是 |
| 2️⃣ | V2 → V3 | 建立 Core Data，双轨运行 | 🟡 中 | ✅ 是 |
| 3️⃣ | V3 → V4 | 完全切换到 Core Data | 🟡 中 | ✅ 是 |

## 第一阶段：V1 → V2 迁移（推荐立即执行）

### 准备工作

**在开始之前，请确保：**

1. ⚠️ **关闭应用中所有正在进行的副本**
2. ⚠️ **记录当前数据状态**（建议截图保存）
3. ✅ **确保设备有足够存储空间**（至少 100MB）

### 执行步骤

#### 方法一：自动迁移（推荐）

1. **在 `DungeonStatApp.swift` 中添加迁移检查**

```swift
import SwiftUI

@main
struct DungeonStatApp: App {
    @StateObject private var dungeonManager = DungeonManager()
    @State private var showMigrationAlert = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dungeonManager)
                .onAppear {
                    checkAndMigrate()
                }
                .alert("需要数据升级", isPresented: $showMigrationAlert) {
                    Button("立即升级") {
                        performMigration()
                    }
                    Button("稍后提醒", role: .cancel) { }
                } message: {
                    Text("检测到新版本数据格式，需要升级以修复潜在的内存问题。此过程会自动备份您的数据。")
                }
        }
    }

    private func checkAndMigrate() {
        let migrationManager = MigrationManager.shared

        if migrationManager.needsMigration(to: .v2_characterID) {
            showMigrationAlert = true
        }
    }

    private func performMigration() {
        Task {
            let result = await MigrationManager.shared.migrate(to: .v2_characterID)

            if result.success {
                print("✅ 迁移成功")
                // 重新加载数据
                dungeonManager.reloadAllData()
            } else {
                print("❌ 迁移失败: \(result.error?.localizedDescription ?? "未知错误")")
            }
        }
    }
}
```

#### 方法二：手动迁移（测试用）

1. **在设置页面添加迁移入口**

在 `SettingsView.swift` 中添加：

```swift
Section(header: Text("高级设置")) {
    NavigationLink {
        MigrationTestView()
    } label: {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("数据迁移工具")
            Spacer()
            if MigrationManager.shared.needsMigration(to: .v2_characterID) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
}
```

2. **打开应用 → 设置 → 数据迁移工具**
3. **点击"迁移到 V2"按钮**
4. **等待迁移完成并查看结果**

### 迁移后验证

迁移完成后，请检查以下内容：

✅ **数据完整性检查清单：**

- [ ] 角色数量是否正确
- [ ] 副本列表是否完整
- [ ] 历史记录数量是否一致
- [ ] 各角色的副本统计是否正确
- [ ] 正在进行中的副本状态是否保留
- [ ] 掉落物品记录是否完整

**验证方法：**

```swift
// 在 DungeonManager 中调用
let report = DataMigrationHelper.generateMigrationReport(
    legacy: oldDungeons,
    migrated: newDungeons,
    characters: characters
)
print(report)
```

### 回滚操作

如果迁移后发现问题，可以立即回滚：

```swift
// 使用备份ID回滚
let backupId = "_backup_1234567890" // 从迁移结果中获取
let success = MigrationManager.shared.rollback(
    to: .v1_userDefaults,
    using: backupId
)

if success {
    dungeonManager.reloadAllData()
}
```

或者在迁移测试界面点击"回滚最近的迁移"按钮。

## 网络重试机制使用

### 在现有代码中启用重试

**原有代码：**
```swift
let roleData = try await JX3APIService.shared.fetchRoleDetails(
    server: character.server,
    name: character.name
)
```

**改进后：**
```swift
let roleData = try await JX3APIService.shared.fetchRoleDetailsWithRetry(
    server: character.server,
    name: character.name
)
```

### 自定义重试配置

```swift
// 使用更激进的重试策略
let data = try await NetworkRetryService.executeWithRetry(
    config: .aggressive  // 重试5次，最长等待30秒
) {
    try await someNetworkOperation()
}

// 使用温和的重试策略（适合低优先级任务）
let data = try await NetworkRetryService.executeWithRetry(
    config: .gentle  // 重试2次，最长等待5秒
) {
    try await backgroundSync()
}
```

## 常量迁移

### 更新颜色使用

**旧代码：**
```swift
Color(UIColor { traitCollection in
    switch traitCollection.userInterfaceStyle {
    case .dark:
        return UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
    default:
        return UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
    }
})
```

**新代码：**
```swift
@Environment(\.colorScheme) var colorScheme

// 在 body 中使用
.foregroundColor(Constants.Colors.goldItem(for: colorScheme))
```

## 故障排查

### 问题 1：迁移失败

**症状：** 迁移过程中报错

**解决方案：**
1. 查看迁移日志：设置 → 数据迁移工具 → 查看迁移日志
2. 检查错误信息
3. 使用备份回滚
4. 联系开发者并提供日志

### 问题 2：数据不一致

**症状：** 迁移后统计数据不匹配

**解决方案：**
```swift
// 重新同步统计数据
dungeonManager.syncStatisticsFromRecords()
```

### 问题 3：应用崩溃

**症状：** 迁移后应用启动崩溃

**解决方案：**
1. 删除并重装应用（**会丢失数据，谨慎操作**）
2. 或手动恢复备份：
   - 使用 Xcode → Window → Devices and Simulators
   - 下载应用容器
   - 从 Library/Preferences 中恢复备份数据

## 性能优化建议

### 1. 定期清理备份

```swift
// 只保留最近3个备份
DataPersistenceManager.shared.cleanupOldBackups()
```

### 2. 批量操作使用异步

```swift
// 批量加载角色卡片
try await NetworkRetryService.executeBatch(
    items: characters,
    maxConcurrent: 3  // 最多同时3个请求
) { character in
    _ = try await fetchCharacterCard(for: character)
}
```

## 未来计划

### V3：Core Data 双轨运行（开发中）

- ✅ 保留 UserDefaults 作为备份
- ✅ 新数据同时写入 Core Data 和 UserDefaults
- ✅ 验证数据一致性
- ⏳ 预计发布时间：未定

### V4：完全切换到 Core Data

- ⏳ 停止使用 UserDefaults
- ⏳ 完全迁移到 Core Data
- ⏳ 清理旧数据

## 技术支持

如果在迁移过程中遇到问题：

1. 📋 **收集信息**：
   - 当前数据版本
   - 迁移日志
   - 错误截图

2. 🐛 **提交 Issue**：
   - GitHub Issues: [项目地址]
   - 附上收集的信息

3. 💾 **保护数据**：
   - 迁移前务必备份
   - 保留备份ID以便回滚

## 附录

### A. 文件清单

本次改进新增的文件：

```
Services/
├── MigrationManager.swift           # 迁移管理器
├── DataMigrationHelper.swift        # 迁移辅助工具
└── NetworkRetryService.swift        # 网络重试服务

Models/
└── DungeonV2.swift                  # 改进的副本模型

Views/Settings/
└── MigrationTestView.swift          # 迁移测试界面

Utils/
└── Constants.swift                  # 更新的常量管理
```

### B. 备份位置

所有备份数据存储在 UserDefaults 中，键名格式：
- `SavedDungeons_backup_[时间戳]`
- `SavedCharacters_backup_[时间戳]`
- `CompletionRecords_backup_[时间戳]`
- `BackupInfo_[时间戳]`

### C. 数据验证脚本

```swift
// 验证迁移前后数据一致性
func validateDataIntegrity() {
    let oldCount = oldDungeons.reduce(0) { sum, dungeon in
        sum + dungeon.characterTotalCounts.values.reduce(0, +)
    }

    let newCount = newDungeons.reduce(0) { sum, dungeon in
        sum + dungeon.characterTotalCounts.values.reduce(0, +)
    }

    assert(oldCount == newCount, "数据总数不一致！")
}
```

---

**最后更新：** 2025-10-09
**文档版本：** 1.0
**适用版本：** DungeonStat V1 → V2
