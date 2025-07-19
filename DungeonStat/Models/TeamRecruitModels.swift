//
//  TeamRecruitModels.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
//

import Foundation

// MARK: - 团队招募数据模型
struct TeamRecruitResponse: Codable {
    let code: Int
    let msg: String
    let data: TeamRecruitData
    let time: Int
}

struct TeamRecruitData: Codable {
    let zone: String
    let server: String
    let time: Int
    let data: [TeamRecruitItem]
}

struct TeamRecruitItem: Codable, Identifiable, Equatable {
    let id = UUID()
    let activity: String
    let leader: String
    let number: Int
    let maxNumber: Int
    let content: String
    
    // 其他字段，全部设为可选以避免解析错误
    let crossServer: Bool?
    let activityId: Int?
    let level: Int?
    let pushId: Int?
    let roomID: String?
    let roleId: Int?
    let createTime: Int?
    let label: [String]?
    
    enum CodingKeys: String, CodingKey {
        case activity
        case leader
        case number
        case maxNumber
        case content
        case crossServer
        case activityId
        case level
        case pushId
        case roomID
        case roleId
        case createTime
        case label
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 必需字段
        activity = try container.decode(String.self, forKey: .activity)
        leader = try container.decode(String.self, forKey: .leader)
        number = try container.decode(Int.self, forKey: .number)
        maxNumber = try container.decode(Int.self, forKey: .maxNumber)
        content = try container.decode(String.self, forKey: .content)
        
        // 可选字段，容忍类型不匹配
        crossServer = try? container.decode(Bool.self, forKey: .crossServer)
        activityId = try? container.decode(Int.self, forKey: .activityId)
        level = try? container.decode(Int.self, forKey: .level)
        pushId = try? container.decode(Int.self, forKey: .pushId)
        roomID = try? container.decode(String.self, forKey: .roomID)
        roleId = try? container.decode(Int.self, forKey: .roleId)
        createTime = try? container.decode(Int.self, forKey: .createTime)
        label = try? container.decode([String].self, forKey: .label)
    }
    
    static func == (lhs: TeamRecruitItem, rhs: TeamRecruitItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 人数状态
    var memberStatus: String {
        return "\(number)/\(maxNumber)"
    }
    
    // 是否已满员
    var isFull: Bool {
        return number >= maxNumber
    }
    
    // 缺人数量
    var neededMembers: Int {
        return max(0, maxNumber - number)
    }
}

// MARK: - 团队招募搜索类型
enum TeamRecruitSearchType: Int, CaseIterable {
    case all = 1        // 本服+跨服
    case local = 2      // 仅本服
    case cross = 3      // 仅跨服
    
    var displayName: String {
        switch self {
        case .all:
            return "本服+跨服"
        case .local:
            return "仅本服"
        case .cross:
            return "仅跨服"
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "globe"
        case .local:
            return "house"
        case .cross:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - 团队分类和识别扩展
extension TeamRecruitItem {
    
    /// 是否为金团
    var isGoldTeam: Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        
        // 检查内容关键字
        let goldKeywords = ["0抵消", "来打手", "包团"]
        let hasGoldKeywords = goldKeywords.contains { keyword in
            content.contains(keyword) || content.contains(keyword.replacingOccurrences(of: "z", with: ""))
        }
        
        // 检查是否为25人团且只有1人
        let is25PersonTeam = activity.contains("25人") && maxNumber == 25 && number == 1
        
        return hasGoldKeywords || is25PersonTeam
    }
    
    /// 是否有补贴
    var hasSubsidy: Bool {
        let content = self.content
        // 匹配"补"字后跟数字的模式，如"补1"、"补500"等
        let subsidyPattern = "补\\d+"
        let range = content.range(of: subsidyPattern, options: .regularExpression)
        return range != nil
    }
    
    /// 获取补贴信息
    var subsidyInfo: String? {
        guard hasSubsidy else { return nil }
        let content = self.content
        let subsidyPattern = "补\\d+"
        if let range = content.range(of: subsidyPattern, options: .regularExpression) {
            return String(content[range])
        }
        return nil
    }
    
    /// 匹配职业关键字
    func matchesProfession(_ searchText: String) -> Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        let searchLower = searchText.lowercased()
        
        // 定义完整的职业关键字映射
        let professionKeywords: [String: [String]] = [
            // 治疗职业
            "歌奶": ["歌", "歌奶", "万花奶", "万花治疗", "花奶", "万花", "歌治疗"],
            "药奶": ["药", "药奶", "药宗奶", "药宗治疗", "药治疗", "药宗"],
            "秀奶": ["秀", "秀奶", "七秀奶", "七秀治疗", "秀治疗", "七秀"],
            "毒奶": ["毒", "毒奶", "五毒奶", "五毒治疗", "毒治疗", "五毒"],
            "花奶": ["花", "花奶", "万花奶", "万花治疗", "歌奶", "万花", "花治疗"],
            "奶": ["奶", "治疗", "奶妈", "奶爸"],
            
            // 坦克职业
            "t": ["t", "坦克", "mt", "副t", "主t"],
            "铁牢": ["铁牢", "铁牢t", "少林t", "少林坦克"],
            "明教": ["明教", "明教t", "明教坦克"],
            "策天": ["策天", "策天t", "纯阳坦克"],
            
            // DPS职业
            "dps": ["dps", "输出", "dd"],
            "剑纯": ["剑纯", "纯阳剑", "太虚剑意"],
            "气纯": ["气纯", "纯阳气", "紫霞功"],
            "分山": ["分山", "分山劲", "苍云"],
            "莫问": ["莫问", "莫问归期", "长歌"],
            "霸刀": ["霸刀", "北傲决", "刀宗"],
            "蓬莱": ["蓬莱", "凌海决"],
            "衍天": ["衍天", "衍天宗", "五毒dps"],
            "惊羽": ["惊羽", "惊羽诀", "鹿鸣"],
            "天策": ["天策", "天策dps", "策"],
            "藏剑": ["藏剑", "问水诀", "山居剑意"],
            "毒经": ["毒经", "毒dps", "五毒输出"],
            "笑尘": ["笑尘", "笑尘诀", "万花dps"],
            "焚影": ["焚影", "焚影圣诀", "明教dps"],
            "冰心": ["冰心", "冰心诀", "七秀dps"],
            "云裳": ["云裳", "云裳心经", "秀dps"],
            "太玄": ["太玄", "太玄经", "藏剑dps"],
            "隐龙": ["隐龙", "隐龙诀", "苍云dps"],
            "无方": ["无方", "无方寸", "长歌dps"],
            
            // 通用搜索
            "tn": ["t", "n", "坦克", "奶妈", "治疗", "tn"],
            "tn补": ["tn补", "t补", "n补", "坦克补", "奶补", "治疗补"],
            "dps补": ["dps补", "dd补", "输出补"]
        ]
        
        // 检查是否匹配职业关键字
        for (profession, keywords) in professionKeywords {
            if searchLower.contains(profession) {
                return keywords.contains { keyword in
                    content.contains(keyword) || activity.contains(keyword)
                }
            }
        }
        
        // 直接匹配搜索词
        return content.contains(searchLower) || activity.contains(searchLower)
    }
}
