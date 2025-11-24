//
//  CoreDataStack.swift
//  DungeonStat
//
//  Core Data 栈管理 - 使用纯代码定义模型
//

import Foundation
import CoreData

// MARK: - Core Data Stack
class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {
        // 初始化时检查是否需要创建存储
        _ = persistentContainer
    }

    // MARK: - 持久化容器

    lazy var persistentContainer: NSPersistentContainer = {
        // 创建模型描述
        let model = CoreDataStack.createManagedObjectModel()
        let container = NSPersistentContainer(name: "DungeonStat", managedObjectModel: model)

        // 配置存储
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DungeonStat.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        container.persistentStoreDescriptions = [description]

        // 加载存储
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data 加载失败: \(error), \(error.userInfo)")
                // 如果加载失败，尝试删除并重建
                if FileManager.default.fileExists(atPath: storeURL.path) {
                    try? FileManager.default.removeItem(at: storeURL)
                    container.loadPersistentStores { _, _ in
                        print("✅ Core Data 重建成功")
                    }
                }
            } else {
                print("✅ Core Data 加载成功: \(storeDescription)")
            }
        }

        return container
    }()

    // MARK: - 上下文

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - 保存

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data 保存成功")
            } catch {
                let nsError = error as NSError
                print("❌ Core Data 保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func save(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - 清空数据

    func clearAllData() throws {
        let context = viewContext

        // 清空所有实体
        let entities = ["CDGameCharacter", "CDDungeon", "CDCompletionRecord", "CDDropItem"]

        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try context.execute(deleteRequest)
        }

        try context.save()
        print("✅ Core Data 数据已清空")
    }

    // MARK: - 模型定义（纯代码方式）

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // 创建实体
        let characterEntity = createCharacterEntity()
        let dungeonEntity = createDungeonEntity()
        let recordEntity = createCompletionRecordEntity()
        let dropEntity = createDropItemEntity()

        // 设置实体关系
        setupRelationships(
            character: characterEntity,
            dungeon: dungeonEntity,
            record: recordEntity,
            drop: dropEntity
        )

        model.entities = [characterEntity, dungeonEntity, recordEntity, dropEntity]

        return model
    }

    // MARK: - 实体定义

    private static func createCharacterEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDGameCharacter"
        entity.managedObjectClassName = NSStringFromClass(CDGameCharacter.self)

        // 属性
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let serverAttr = NSAttributeDescription()
        serverAttr.name = "server"
        serverAttr.attributeType = .stringAttributeType
        serverAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let schoolAttr = NSAttributeDescription()
        schoolAttr.name = "school"
        schoolAttr.attributeType = .stringAttributeType
        schoolAttr.isOptional = false

        let bodyTypeAttr = NSAttributeDescription()
        bodyTypeAttr.name = "bodyType"
        bodyTypeAttr.attributeType = .stringAttributeType
        bodyTypeAttr.isOptional = false

        entity.properties = [idAttr, serverAttr, nameAttr, schoolAttr, bodyTypeAttr]

        return entity
    }

    private static func createDungeonEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDDungeon"
        entity.managedObjectClassName = NSStringFromClass(CDDungeon.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let categoryIdAttr = NSAttributeDescription()
        categoryIdAttr.name = "categoryId"
        categoryIdAttr.attributeType = .UUIDAttributeType
        categoryIdAttr.isOptional = true

        // 使用 Transformable 存储字典数据
        let countsAttr = NSAttributeDescription()
        countsAttr.name = "characterCountsData"
        countsAttr.attributeType = .transformableAttributeType
        countsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        countsAttr.isOptional = true

        let weeklyCountsAttr = NSAttributeDescription()
        weeklyCountsAttr.name = "characterWeeklyCountsData"
        weeklyCountsAttr.attributeType = .transformableAttributeType
        weeklyCountsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        weeklyCountsAttr.isOptional = true

        let totalCountsAttr = NSAttributeDescription()
        totalCountsAttr.name = "characterTotalCountsData"
        totalCountsAttr.attributeType = .transformableAttributeType
        totalCountsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        totalCountsAttr.isOptional = true

        entity.properties = [idAttr, nameAttr, categoryIdAttr, countsAttr, weeklyCountsAttr, totalCountsAttr]

        return entity
    }

    private static func createCompletionRecordEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDCompletionRecord"
        entity.managedObjectClassName = NSStringFromClass(CDCompletionRecord.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let dungeonNameAttr = NSAttributeDescription()
        dungeonNameAttr.name = "dungeonName"
        dungeonNameAttr.attributeType = .stringAttributeType
        dungeonNameAttr.isOptional = false

        let completedDateAttr = NSAttributeDescription()
        completedDateAttr.name = "completedDate"
        completedDateAttr.attributeType = .dateAttributeType
        completedDateAttr.isOptional = false

        let weekNumberAttr = NSAttributeDescription()
        weekNumberAttr.name = "weekNumber"
        weekNumberAttr.attributeType = .integer32AttributeType
        weekNumberAttr.isOptional = false

        let yearAttr = NSAttributeDescription()
        yearAttr.name = "year"
        yearAttr.attributeType = .integer32AttributeType
        yearAttr.isOptional = false

        let durationAttr = NSAttributeDescription()
        durationAttr.name = "duration"
        durationAttr.attributeType = .doubleAttributeType
        durationAttr.isOptional = false

        let characterIdAttr = NSAttributeDescription()
        characterIdAttr.name = "characterId"
        characterIdAttr.attributeType = .UUIDAttributeType
        characterIdAttr.isOptional = false

        entity.properties = [idAttr, dungeonNameAttr, completedDateAttr, weekNumberAttr, yearAttr, durationAttr, characterIdAttr]

        return entity
    }

    private static func createDropItemEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDDropItem"
        entity.managedObjectClassName = NSStringFromClass(CDDropItem.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let recordIdAttr = NSAttributeDescription()
        recordIdAttr.name = "recordId"
        recordIdAttr.attributeType = .UUIDAttributeType
        recordIdAttr.isOptional = false

        entity.properties = [idAttr, nameAttr, recordIdAttr]

        return entity
    }

    private static func setupRelationships(
        character: NSEntityDescription,
        dungeon: NSEntityDescription,
        record: NSEntityDescription,
        drop: NSEntityDescription
    ) {
        // CompletionRecord <-> DropItem (一对多)
        let recordDropsRel = NSRelationshipDescription()
        recordDropsRel.name = "drops"
        recordDropsRel.destinationEntity = drop
        recordDropsRel.isOptional = true
        recordDropsRel.deleteRule = .cascadeDeleteRule
        recordDropsRel.maxCount = 0 // 0 表示无限制

        let dropRecordRel = NSRelationshipDescription()
        dropRecordRel.name = "record"
        dropRecordRel.destinationEntity = record
        dropRecordRel.isOptional = false
        dropRecordRel.deleteRule = .nullifyDeleteRule
        dropRecordRel.maxCount = 1

        recordDropsRel.inverseRelationship = dropRecordRel
        dropRecordRel.inverseRelationship = recordDropsRel

        record.properties.append(recordDropsRel)
        drop.properties.append(dropRecordRel)
    }
}
