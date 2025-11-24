//
//  CDDropItem.swift
//  DungeonStat
//
//  Core Data 实体 - 掉落物品
//

import Foundation
import CoreData

@objc(CDDropItem)
public class CDDropItem: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var recordId: UUID
    @NSManaged public var record: CDCompletionRecord?

    // MARK: - 转换方法

    /// 从 DropItem 模型创建
    static func create(from model: DropItem, recordId: UUID, in context: NSManagedObjectContext) -> CDDropItem {
        let entity = CDDropItem(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.recordId = recordId
        return entity
    }

    /// 转换为 DropItem 模型
    func toModel() -> DropItem {
        return DropItem(id: id, name: name)
    }
}

// MARK: - 查询扩展

extension CDDropItem {
    /// 获取所有掉落
    static func fetchAll(in context: NSManagedObjectContext) throws -> [CDDropItem] {
        let request = NSFetchRequest<CDDropItem>(entityName: "CDDropItem")
        return try context.fetch(request)
    }

    /// 根据 ID 查找掉落
    static func fetch(by id: UUID, in context: NSManagedObjectContext) throws -> CDDropItem? {
        let request = NSFetchRequest<CDDropItem>(entityName: "CDDropItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 查找指定记录的掉落
    static func fetch(forRecord recordId: UUID, in context: NSManagedObjectContext) throws -> [CDDropItem] {
        let request = NSFetchRequest<CDDropItem>(entityName: "CDDropItem")
        request.predicate = NSPredicate(format: "recordId == %@", recordId as CVarArg)
        return try context.fetch(request)
    }

    /// 删除掉落
    static func delete(id: UUID, in context: NSManagedObjectContext) throws {
        if let drop = try fetch(by: id, in: context) {
            context.delete(drop)
        }
    }
}
