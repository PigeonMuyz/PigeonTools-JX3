//
//  CDCompletionRecord.swift
//  DungeonStat
//
//  Core Data 实体 - 完成记录
//

import Foundation
import CoreData

@objc(CDCompletionRecord)
public class CDCompletionRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var dungeonName: String
    @NSManaged public var completedDate: Date
    @NSManaged public var weekNumber: Int32
    @NSManaged public var year: Int32
    @NSManaged public var duration: Double
    @NSManaged public var characterId: UUID
    @NSManaged public var drops: NSSet?

    // MARK: - 转换方法

    /// 从 CompletionRecord 模型创建
    static func create(from model: CompletionRecord, in context: NSManagedObjectContext) -> CDCompletionRecord {
        let entity = CDCompletionRecord(context: context)
        entity.id = model.id
        entity.dungeonName = model.dungeonName
        entity.completedDate = model.completedDate
        entity.weekNumber = Int32(model.weekNumber)
        entity.year = Int32(model.year)
        entity.duration = model.duration
        entity.characterId = model.character.id
        return entity
    }

    /// 转换为 CompletionRecord 模型（需要角色信息）
    func toModel(character: GameCharacter) -> CompletionRecord {
        // 获取掉落物品
        let dropItems: [DropItem]
        if let dropsSet = drops as? Set<CDDropItem> {
            dropItems = dropsSet.map { $0.toModel() }
        } else {
            dropItems = []
        }

        return CompletionRecord(
            id: id,
            dungeonName: dungeonName,
            character: character,
            completedDate: completedDate,
            weekNumber: Int(weekNumber),
            year: Int(year),
            duration: duration,
            drops: dropItems
        )
    }
}

// MARK: - 查询扩展

extension CDCompletionRecord {
    /// 获取所有记录
    static func fetchAll(in context: NSManagedObjectContext) throws -> [CDCompletionRecord] {
        let request = NSFetchRequest<CDCompletionRecord>(entityName: "CDCompletionRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        return try context.fetch(request)
    }

    /// 根据 ID 查找记录
    static func fetch(by id: UUID, in context: NSManagedObjectContext) throws -> CDCompletionRecord? {
        let request = NSFetchRequest<CDCompletionRecord>(entityName: "CDCompletionRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 查找指定角色的记录
    static func fetch(forCharacter characterId: UUID, in context: NSManagedObjectContext) throws -> [CDCompletionRecord] {
        let request = NSFetchRequest<CDCompletionRecord>(entityName: "CDCompletionRecord")
        request.predicate = NSPredicate(format: "characterId == %@", characterId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        return try context.fetch(request)
    }

    /// 删除记录
    static func delete(id: UUID, in context: NSManagedObjectContext) throws {
        if let record = try fetch(by: id, in: context) {
            context.delete(record)
        }
    }
}

// MARK: - 掉落物品管理

extension CDCompletionRecord {
    var dropsArray: [CDDropItem] {
        return (drops as? Set<CDDropItem>)?.sorted { $0.name < $1.name } ?? []
    }

    func addDrop(_ drop: CDDropItem) {
        let items = self.mutableSetValue(forKey: "drops")
        items.add(drop)
    }

    func removeDrop(_ drop: CDDropItem) {
        let items = self.mutableSetValue(forKey: "drops")
        items.remove(drop)
    }
}
