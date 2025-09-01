//
//  CharacterData.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 角色详细数据模型
struct CharacterDetailData: Codable {
    let code: Int
    let msg: String
    let data: CharacterData?
    let time: Int?
}

struct CharacterData: Codable {
    let zoneName: String?        // 修改为可选类型
    let serverName: String
    let roleName: String
    let roleId: String
    let globalRoleId: String
    let forceName: String
    let forceId: String
    let bodyName: String
    let bodyId: String
    let tongName: String?
    let tongId: String?
    let campName: String
    let campId: String
    let personName: String
    let personId: String?        // 修改为可选类型
    let personAvatar: String?    // 修改为可选类型
    let gameClient: String?      // 新增字段，可选类型
    let gameMode: String?        // 新增字段，可选类型
    let kungfuType: String?      // 新增字段，可选类型
    let kungfuName: String
    let kungfuId: String
    let equipList: [Equipment]
    let qixueList: [Qixue]
    let panelList: PanelList
}

struct Equipment: Codable, Identifiable {
    let id = UUID()
    let name: String
    let `class`: String
    let icon: String
    let kind: String
    let subKind: String
    let quality: String
    let strengthLevel: String
    let maxStrengthLevel: String
    let color: String
    let desc: String
    let source: String?
    let fiveStone: [FiveStone]?
    let colorStone: ColorStone?
    let permanentEnchant: [Enchant]?
    let commonEnchant: CommonEnchant?
    
    private enum CodingKeys: String, CodingKey {
        case name, `class`, icon, kind, subKind, quality, strengthLevel, maxStrengthLevel, color, desc, source, fiveStone, colorStone, permanentEnchant, commonEnchant
    }
}

struct FiveStone: Codable, Identifiable {
    let id = UUID()
    let name: String
    let level: String
    let max: String
    let min: String
    let icon: String
    let kind: String
    let subKind: String
    let desc: String
    let percent: Bool
    
    private enum CodingKeys: String, CodingKey {
        case name, level, max, min, icon, kind, subKind, desc, percent
    }
}

struct ColorStone: Codable, Identifiable {
    let id: String
    let name: String
    let `class`: String
    let level: String
    let icon: String
    let kind: String
    let subKind: String
    let attribute: [ColorStoneAttribute]
}

struct ColorStoneAttribute: Codable, Identifiable {
    let id = UUID()
    let max: String
    let min: String
    let desc: String
    let percent: Bool
    
    private enum CodingKeys: String, CodingKey {
        case max, min, desc, percent
    }
}

struct Enchant: Codable, Identifiable {
    let id: String
    let name: String
    let level: String
    let icon: String
    let attributes: [EnchantAttribute]
}

struct EnchantAttribute: Codable, Identifiable {
    let id = UUID()
    let max: String
    let min: String
    let attrib: [AttribDesc]
    
    private enum CodingKeys: String, CodingKey {
        case max, min, attrib
    }
}

struct AttribDesc: Codable, Identifiable {
    let id = UUID()
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case desc
    }
}

struct CommonEnchant: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let desc: String
}

struct Qixue: Codable, Identifiable {
    let id = UUID()
    let name: String
    let level: Int
    let icon: String
    let kind: String
    let subKind: String
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case name, level, icon, kind, subKind, desc
    }
}

struct PanelList: Codable {
    let score: Int
    let panel: [PanelAttribute]
}

struct PanelAttribute: Codable, Identifiable {
    let id = UUID()
    let name: String
    let percent: Bool
    let value: Double
    
    private enum CodingKeys: String, CodingKey {
        case name, percent, value
    }
}

// MARK: - Character Card Models
struct CharacterCardResponse: Codable {
    let code: Int
    let msg: String
    let data: CharacterCardData?
    let time: Int
}

struct CharacterCardData: Codable, Identifiable {
    let id = UUID()
    let zoneName: String
    let serverName: String
    let roleName: String
    let showHash: String
    let showAvatar: String
    let cacheTime: Int
    
    private enum CodingKeys: String, CodingKey {
        case zoneName, serverName, roleName, showHash, showAvatar, cacheTime
    }
}

struct CharacterCardCache: Codable, Identifiable {
    let id: UUID
    let zoneName: String
    let serverName: String
    let roleName: String
    let showHash: String
    let localImagePath: String? // 保留以兼容旧数据
    let imageBase64: String? // 新增Base64图片数据
    let cacheTime: Int
    let lastUpdated: Date
    
    init(id: UUID = UUID(), zoneName: String, serverName: String, roleName: String, showHash: String, localImagePath: String? = nil, imageBase64: String? = nil, cacheTime: Int, lastUpdated: Date) {
        self.id = id
        self.zoneName = zoneName
        self.serverName = serverName
        self.roleName = roleName
        self.showHash = showHash
        self.localImagePath = localImagePath
        self.imageBase64 = imageBase64
        self.cacheTime = cacheTime
        self.lastUpdated = lastUpdated
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, zoneName, serverName, roleName, showHash, localImagePath, imageBase64, cacheTime, lastUpdated
    }
}

// MARK: - Character Achievement Detail Models
struct CharacterAchievementDetailResponse: Codable {
    let code: Int
    let msg: String
    let data: CharacterAchievementDetailData?
    let time: Int
}

struct CharacterAchievementDetailData: Codable {
    let zoneName: String
    let serverName: String
    let roleName: String
    let roleId: String
    let globalRoleId: String
    let forceName: String
    let forceId: String
    let bodyName: String
    let bodyId: String
    let tongName: String?
    let tongId: String?
    let campName: String
    let campId: String
    let personName: String?
    let personId: String
    let personAvatar: String?
    let data: [AchievementDetail]
}

struct AchievementDetail: Codable, Identifiable {
    let id: Int
    let icon: String
    let likes: Int
    let name: String
    let `class`: String
    let subClass: String
    let desc: String
    let detail: String
    let maps: [String]
    let isFinished: Bool
    let isFav: Bool
    let type: String
    let currentValue: Int
    let triggerValue: Int
    let subset: [AchievementSubset]
    let rewardItem: String?
    let rewardPoint: Int
    let rewardPrefix: String
    let rewardSuffix: String
    
    private enum CodingKeys: String, CodingKey {
        case id, icon, likes, name, `class`, subClass, desc, detail, maps, isFinished, isFav, type, currentValue, triggerValue, subset, rewardItem, rewardPoint, rewardPrefix, rewardSuffix
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        icon = try container.decode(String.self, forKey: .icon)
        likes = try container.decode(Int.self, forKey: .likes)
        name = try container.decode(String.self, forKey: .name)
        `class` = try container.decode(String.self, forKey: .class)
        subClass = try container.decode(String.self, forKey: .subClass)
        desc = try container.decode(String.self, forKey: .desc)
        detail = try container.decode(String.self, forKey: .detail)
        maps = try container.decode([String].self, forKey: .maps)
        isFinished = try container.decode(Bool.self, forKey: .isFinished)
        isFav = try container.decode(Bool.self, forKey: .isFav)
        type = try container.decode(String.self, forKey: .type)
        currentValue = try container.decode(Int.self, forKey: .currentValue)
        triggerValue = try container.decode(Int.self, forKey: .triggerValue)
        subset = try container.decode([AchievementSubset].self, forKey: .subset)
        rewardPoint = try container.decode(Int.self, forKey: .rewardPoint)
        rewardPrefix = try container.decode(String.self, forKey: .rewardPrefix)
        rewardSuffix = try container.decode(String.self, forKey: .rewardSuffix)
        
        // 处理 rewardItem 字段，可能是字符串或字典
        if let rewardItemString = try? container.decode(String.self, forKey: .rewardItem) {
            rewardItem = rewardItemString
        } else {
            // 如果不是字符串，设为 nil
            rewardItem = nil
        }
    }
    
    // 便利构造函数，用于手动创建 AchievementDetail
    init(id: Int, icon: String, likes: Int, name: String, class: String, subClass: String, desc: String, detail: String, maps: [String], isFinished: Bool, isFav: Bool, type: String, currentValue: Int, triggerValue: Int, subset: [AchievementSubset], rewardItem: String?, rewardPoint: Int, rewardPrefix: String, rewardSuffix: String) {
        self.id = id
        self.icon = icon
        self.likes = likes
        self.name = name
        self.`class` = `class`
        self.subClass = subClass
        self.desc = desc
        self.detail = detail
        self.maps = maps
        self.isFinished = isFinished
        self.isFav = isFav
        self.type = type
        self.currentValue = currentValue
        self.triggerValue = triggerValue
        self.subset = subset
        self.rewardItem = rewardItem
        self.rewardPoint = rewardPoint
        self.rewardPrefix = rewardPrefix
        self.rewardSuffix = rewardSuffix
    }
}

struct AchievementSubset: Codable, Identifiable {
    let id: Int
    let icon: String
    let isFinished: Bool
    let name: String
    
    private enum CodingKeys: String, CodingKey {
        case id, icon, isFinished, name
    }
}

// MARK: - Dungeon Achievement Query Cache
struct DungeonAchievementQueryCache: Codable, Identifiable {
    let id = UUID()
    let serverName: String
    let roleName: String
    let dungeonName: String
    let achievements: [AchievementDetail]
    let queryTime: Date
    let unfinishedCount: Int
    let totalCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case serverName, roleName, dungeonName, achievements, queryTime, unfinishedCount, totalCount
    }
}
