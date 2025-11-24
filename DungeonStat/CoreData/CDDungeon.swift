//
//  CDDungeon.swift
//  DungeonStat
//
//  Core Data 实体 - 副本
//

import Foundation
import CoreData

@objc(CDDungeon)
public class CDDungeon: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var categoryId: UUID?
    @NSManaged public var characterCountsData: Data?
    @NSManaged public var characterWeeklyCountsData: Data?
    @NSManaged public var characterTotalCountsData: Data?

    // MARK: - 辅助方法

    /// 获取角色计数字典
    var characterCounts: [UUID: Int] {
        get {
            guard let data = characterCountsData else { return [:] }
            return (try? JSONDecoder().decode([UUID: Int].self, from: data)) ?? [:]
        }
        set {
            characterCountsData = try? JSONEncoder().encode(newValue)
        }
    }

    var characterWeeklyCounts: [UUID: Int] {
        get {
            guard let data = characterWeeklyCountsData else { return [:] }
            return (try? JSONDecoder().decode([UUID: Int].self, from: data)) ?? [:]
        }
        set {
            characterWeeklyCountsData = try? JSONEncoder().encode(newValue)
        }
    }

    var characterTotalCounts: [UUID: Int] {
        get {
            guard let data = characterTotalCountsData else { return [:] }
            return (try? JSONDecoder().decode([UUID: Int].self, from: data)) ?? [:]
        }
        set {
            characterTotalCountsData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - 转换方法

    /// 从 DungeonV2 模型创建
    static func create(from model: DungeonV2, in context: NSManagedObjectContext) -> CDDungeon {
        let entity = CDDungeon(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.categoryId = model.categoryId
        entity.characterCounts = model.characterCounts
        entity.characterWeeklyCounts = model.characterWeeklyCounts
        entity.characterTotalCounts = model.characterTotalCounts
        return entity
    }

    /// 转换为 DungeonV2 模型
    func toModel() -> DungeonV2 {
        var dungeon = DungeonV2(id: id, name: name)
        dungeon.categoryId = categoryId
        dungeon.characterCounts = characterCounts
        dungeon.characterWeeklyCounts = characterWeeklyCounts
        dungeon.characterTotalCounts = characterTotalCounts
        return dungeon
    }

    /// 更新数据
    func update(from model: DungeonV2) {
        self.name = model.name
        self.categoryId = model.categoryId
        self.characterCounts = model.characterCounts
        self.characterWeeklyCounts = model.characterWeeklyCounts
        self.characterTotalCounts = model.characterTotalCounts
    }
}

// MARK: - 查询扩展

extension CDDungeon {
    /// 获取所有副本
    static func fetchAll(in context: NSManagedObjectContext) throws -> [CDDungeon] {
        let request = NSFetchRequest<CDDungeon>(entityName: "CDDungeon")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request)
    }

    /// 根据 ID 查找副本
    static func fetch(by id: UUID, in context: NSManagedObjectContext) throws -> CDDungeon? {
        let request = NSFetchRequest<CDDungeon>(entityName: "CDDungeon")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 根据名称查找副本
    static func fetch(byName name: String, in context: NSManagedObjectContext) throws -> CDDungeon? {
        let request = NSFetchRequest<CDDungeon>(entityName: "CDDungeon")
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 删除副本
    static func delete(id: UUID, in context: NSManagedObjectContext) throws {
        if let dungeon = try fetch(by: id, in: context) {
            context.delete(dungeon)
        }
    }
}
