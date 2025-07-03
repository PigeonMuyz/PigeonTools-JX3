//
//  SmartOCRManager.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/3.
//

import SwiftUI
import PhotosUI
import Vision
import Combine

// MARK: - 智能OCR管理器
class SmartOCRManager: ObservableObject {
    @Published var isProcessing = false
    @Published var recognizedItems: [RecognizedItem] = []
    
    // 固定关键字列表
    private let keywords = [
        "玄晶", "御马踏金", "鞍饰", "头饰", "马具", "足饰",
        "红莲", "扇风耳", "墨言", "聆音", "清泉侍女像", "北拒风狼",
        "玄域辟甲", "百合花", "遗忘的书函", "云鹤报捷", "麒麟", "夜泊蝶影",
        "不渡", "簪花空竹"]
    
    struct RecognizedItem: Identifiable {
        let id = UUID()
        var fullText: String          // 可编辑
        let originalText: String      // 原始识别文本
        let matchedKeyword: String
        var isSelected: Bool = false  // 新增：选中状态
        
        var isGoldItem: Bool {
            return fullText.contains("玄晶")
        }
        
        var color: Color {
            if isGoldItem {
                return Color(UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0) // 浅金色
                    default:
                        return UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0) // 深金色
                    }
                })
            } else {
                return Color(UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0) // 浅紫色
                    default:
                        return UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0) // 深紫色
                    }
                })
            }
        }
    }
    
    func recognizeText(from image: UIImage, completion: @escaping ([RecognizedItem]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        isProcessing = true
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion([])
                    return
                }
                
                // 提取所有识别到的文本行
                let allTexts = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                
                // 根据关键字匹配并提取包含关键字的完整行
                var matchedItems: [RecognizedItem] = []
                
                for text in allTexts {
                    for keyword in self?.keywords ?? [] {
                        if text.contains(keyword) {
                            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            let item = RecognizedItem(
                                fullText: cleanText,
                                originalText: cleanText,
                                matchedKeyword: keyword,
                                isSelected: true // 默认选中
                            )
                            
                            // 避免重复添加相同的文本
                            if !matchedItems.contains(where: { $0.originalText == item.originalText }) {
                                matchedItems.append(item)
                            }
                            break // 找到第一个匹配的关键字就停止
                        }
                    }
                }
                
                self?.recognizedItems = matchedItems
                completion(matchedItems)
            }
        }
        
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion([])
                }
            }
        }
    }
    
    func updateItemText(_ item: RecognizedItem, newText: String) {
        if let index = recognizedItems.firstIndex(where: { $0.id == item.id }) {
            recognizedItems[index].fullText = newText
        }
    }
    
    func toggleItemSelection(_ item: RecognizedItem) {
        if let index = recognizedItems.firstIndex(where: { $0.id == item.id }) {
            recognizedItems[index].isSelected.toggle()
        }
    }
    
    func getSelectedItems() -> [RecognizedItem] {
        return recognizedItems.filter { $0.isSelected }
    }
    
    func clearResults() {
        recognizedItems = []
    }
}

// MARK: - 掉落管理页面
struct DropManagementView: View {
    let record: CompletionRecord
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddDrop = false
    
    var body: some View {
        List {
            Section {
                // 副本信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.dungeonName)
                            .font(.headline)
                        Spacer()
                        Text(record.completedDate, formatter: dateFormatter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(record.character.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("掉落物品 (\(record.drops.count))")) {
                if record.drops.isEmpty {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.secondary)
                        Text("暂无掉落记录")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(record.drops) { drop in
                        HStack(spacing: 12) {
                            // 颜色指示器
                            Circle()
                                .fill(drop.color)
                                .frame(width: 10, height: 10)
                            
                            // 物品名称
                            Text(drop.name)
                                .font(.body)
                                .foregroundColor(drop.color)
                            
                            Spacer()
                            
                            // 类型标识
                            if drop.name.contains("玄晶") {
                                Text("大铁")
                                    .font(.caption)
                                    .foregroundColor(drop.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(drop.color.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteDrops)
                }
            }
            
            Section {
                Button(action: {
                    showingAddDrop = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("添加掉落")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("掉落管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddDrop) {
            SmartAddDropView(record: record, isPresented: $showingAddDrop)
        }
    }
    
    private func deleteDrops(offsets: IndexSet) {
        for index in offsets {
            let drop = record.drops[index]
            dungeonManager.removeDropFromRecord(record, dropId: drop.id)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
}

// MARK: - 掉落物品条目
struct DropItem_Input: Identifiable {
    let id = UUID()
    var name: String
    var isFromOCR: Bool = false
    
    var color: Color {
        if name.contains("玄晶") {
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
                default:
                    return UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
                }
            })
        } else {
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
                default:
                    return UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)
                }
            })
        }
    }
}

// MARK: - 智能添加掉落视图
struct SmartAddDropView: View {
    let record: CompletionRecord
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    @State private var dropItems: [DropItem_Input] = [DropItem_Input(name: "")]
    @State private var selectedPhotoItem: PhotosPickerItem?
    @StateObject private var ocrManager = SmartOCRManager()
    
    // 临时存储数组，避免重复添加
    @State private var tempRecognizedNames: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                Section(header: HStack {
                    Text("掉落物品")
                    Spacer()
                    if dropItems.count > 1 {
                        Text("\(dropItems.count) 个")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }) {
                    ForEach(dropItems.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            // 颜色指示器
                            if !dropItems[index].name.isEmpty {
                                Circle()
                                    .fill(dropItems[index].color)
                                    .frame(width: 8, height: 8)
                            }
                            
                            TextField("输入物品名称", text: $dropItems[index].name)
                                .foregroundColor(dropItems[index].name.isEmpty ? .primary : dropItems[index].color)
                            
                            // OCR标识
                            if dropItems[index].isFromOCR {
                                Image(systemName: "eye.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            // 删除按钮
                            if dropItems.count > 1 {
                                Button(action: {
                                    dropItems.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    // 添加更多按钮
                    Button(action: {
                        addEmptyInputField()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            Text("添加更多")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("图片识别")) {
                    // 照片选择器
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("选择照片识别")
                                    .foregroundColor(.blue)
                                Text("识别结果会自动添加到上方列表")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if ocrManager.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    
                    // 识别状态
                    if ocrManager.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在识别图片中的掉落物品...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("添加掉落")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAllDrops()
                    }
                    .disabled(!hasValidDrops())
                }
            }
            .onChange(of: selectedPhotoItem) { photoItem in
                Task {
                    if let photoItem = photoItem,
                       let data = try? await photoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        
                        ocrManager.recognizeText(from: image) { recognizedItems in
                            // 使用临时数组避免重复
                            addRecognizedItemsToListSafely(recognizedItems)
                        }
                    }
                }
            }
        }
    }
    
    private func addRecognizedItemsToListSafely(_ recognizedItems: [SmartOCRManager.RecognizedItem]) {
        var newItems: [DropItem_Input] = []
        
        for item in recognizedItems {
            let itemName = item.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否已经存在（包括临时存储和当前列表）
            let alreadyExists = tempRecognizedNames.contains(itemName) ||
                               dropItems.contains(where: { $0.name == itemName })
            
            if !alreadyExists && !itemName.isEmpty {
                // 添加到临时存储
                tempRecognizedNames.insert(itemName)
                // 收集新物品
                newItems.append(DropItem_Input(name: itemName, isFromOCR: true))
            }
        }
        
        // 批量插入所有新物品，不添加空输入框
        if !newItems.isEmpty {
            insertRecognizedItems(newItems)
        }
    }
    
    // 专门用于插入识别结果的方法（不添加空输入框）
    private func insertRecognizedItems(_ newItems: [DropItem_Input]) {
        // 先尝试填充现有的空输入框
        var itemsToInsert = newItems
        
        // 找到所有空输入框并填充
        for (index, item) in dropItems.enumerated() {
            if item.name.isEmpty && !itemsToInsert.isEmpty {
                dropItems[index] = itemsToInsert.removeFirst()
            }
        }
        
        // 如果还有剩余的识别物品，直接添加到末尾
        if !itemsToInsert.isEmpty {
            dropItems.append(contentsOf: itemsToInsert)
        }
    }
    
    // 手动添加空输入框的方法
    private func addEmptyInputField() {
        dropItems.append(DropItem_Input(name: ""))
    }
    

    
    private func addRecognizedItemsToList(_ recognizedItems: [SmartOCRManager.RecognizedItem]) {
        // 添加识别到的物品
        for item in recognizedItems {
            // 避免重复添加相同名称的物品
            if !dropItems.contains(where: { $0.name == item.fullText }) {
                dropItems.append(DropItem_Input(name: item.fullText, isFromOCR: true))
            }
        }
        
        // 确保总是有一个空的输入框在最后，但不要重复添加
        if dropItems.last?.name.isEmpty != true {
            dropItems.append(DropItem_Input(name: ""))
        }
    }
    
    private func hasValidDrops() -> Bool {
        return dropItems.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func saveAllDrops() {
        // 收集所有有效的物品名称
        let validDropNames = dropItems.compactMap { item -> String? in
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty ? nil : trimmedName
        }
        
        // 批量添加到记录中
        dungeonManager.addMultipleDropsToRecord(record, dropNames: validDropNames)
        
        // 清理临时状态
        tempRecognizedNames.removeAll()
        
        isPresented = false
    }
}
