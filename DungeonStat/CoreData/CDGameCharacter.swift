//
//  CDGameCharacter.swift
//  DungeonStat
//
//  Core Data 实体 - 游戏角色
//

import Foundation
import CoreData

@objc(CDGameCharacter)
public class CDGameCharacter: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var server: String
    @NSManaged public var name: String
    @NSManaged public var school: String
    @NSManaged public var bodyType: String

    // MARK: - 转换方法

    /// 从 GameCharacter 模型创建
    static func create(from model: GameCharacter, in context: NSManagedObjectContext) -> CDGameCharacter {
        let entity = CDGameCharacter(context: context)
        entity.id = model.id
        entity.server = model.server
        entity.name = model.name
        entity.school = model.school
        entity.bodyType = model.bodyType
        return entity
    }

    /// 转换为 GameCharacter 模型
    func toModel() -> GameCharacter {
        var character = GameCharacter(
            server: server,
            name: name,
            school: school,
            bodyType: bodyType
        )
        // 使用反射替换 ID（因为 GameCharacter.id 是 let 常量）
        // 这里我们需要创建一个新的实例
        return GameCharacter(
            id: id,
            server: server,
            name: name,
            school: school,
            bodyType: bodyType
        )
    }

    /// 更新数据
    func update(from model: GameCharacter) {
        self.server = model.server
        self.name = model.name
        self.school = model.school
        self.bodyType = model.bodyType
    }
}

// MARK: - 查询扩展

extension CDGameCharacter {
    /// 获取所有角色
    static func fetchAll(in context: NSManagedObjectContext) throws -> [CDGameCharacter] {
        let request = NSFetchRequest<CDGameCharacter>(entityName: "CDGameCharacter")
        return try context.fetch(request)
    }

    /// 根据 ID 查找角色
    static func fetch(by id: UUID, in context: NSManagedObjectContext) throws -> CDGameCharacter? {
        let request = NSFetchRequest<CDGameCharacter>(entityName: "CDGameCharacter")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 删除角色
    static func delete(id: UUID, in context: NSManagedObjectContext) throws {
        if let character = try fetch(by: id, in: context) {
            context.delete(character)
        }
    }
}
