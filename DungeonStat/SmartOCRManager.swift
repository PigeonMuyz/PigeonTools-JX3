//
//  SmartOCRManager.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/3.
//

import SwiftUI
import PhotosUI
import Vision
import Combine  // 添加这个导入

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
                                matchedKeyword: keyword
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
                                Text("金装")
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

// MARK: - 智能添加掉落视图
struct SmartAddDropView: View {
    let record: CompletionRecord
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    @State private var manualDropName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @StateObject private var ocrManager = SmartOCRManager()
    
    private var previewColor: Color {
        if manualDropName.contains("玄晶") {
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
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("手动输入")) {
                    TextField("物品名称", text: $manualDropName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !manualDropName.isEmpty {
                        HStack {
                            Text("预览:")
                                .foregroundColor(.secondary)
                            Text(manualDropName)
                                .foregroundColor(previewColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(previewColor.opacity(0.15))
                                .cornerRadius(6)
                            Spacer()
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
                                Text("自动识别：玄晶、精炼石、强化石等")
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
                
                // 识别结果
                if !ocrManager.recognizedItems.isEmpty {
                    Section(header: HStack {
                        Text("识别结果")
                        Spacer()
                        Text("找到 \(ocrManager.recognizedItems.count) 个")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }) {
                        ForEach(ocrManager.recognizedItems) { item in
                            RecognizedItemRow(
                                item: item,
                                onTextChanged: { newText in
                                    ocrManager.updateItemText(item, newText: newText)
                                },
                                onAdd: { finalText in
                                    let drop = DropItem(name: finalText)
                                    dungeonManager.addDropToRecord(record, dropItem: drop)
                                }
                            )
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
                        if !manualDropName.isEmpty {
                            let drop = DropItem(name: manualDropName)
                            dungeonManager.addDropToRecord(record, dropItem: drop)
                        }
                        isPresented = false
                    }
                    .disabled(manualDropName.isEmpty && ocrManager.recognizedItems.isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { photoItem in
                Task {
                    if let photoItem = photoItem,
                       let data = try? await photoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        
                        ocrManager.recognizeText(from: image) { items in
                            // 结果已经在 ocrManager.recognizedItems 中更新
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 识别结果行组件
struct RecognizedItemRow: View {
    let item: SmartOCRManager.RecognizedItem
    let onTextChanged: (String) -> Void
    let onAdd: (String) -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // 颜色指示器
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.fullText)
                        .foregroundColor(item.color)
                        .font(.body)
                    
                    if item.fullText != item.originalText {
                        Text("原文: \(item.originalText)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .strikethrough()
                    }
                    
                    Text("关键字: \(item.matchedKeyword)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 编辑按钮
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.orange)
                    }
                    
                    // 添加按钮
                    Button(action: {
                        onAdd(item.fullText)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemSheet(
                item: item,
                isPresented: $showingEditSheet,
                onSave: { newText in
                    onTextChanged(newText)
                }
            )
        }
    }
}

// MARK: - 编辑物品名称弹窗
struct EditItemSheet: View {
    let item: SmartOCRManager.RecognizedItem
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    
    @State private var editingText = ""
    
    var previewColor: Color {
        if editingText.contains("玄晶") {
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
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("编辑物品名称")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("原始识别:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text(item.originalText)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("编辑后:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TextField("物品名称", text: $editingText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                if !editingText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预览效果:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        HStack {
                            Text(editingText)
                                .foregroundColor(previewColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(previewColor.opacity(0.15))
                                .cornerRadius(6)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("编辑物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(editingText)
                        isPresented = false
                    }
                    .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editingText = item.fullText
            }
        }
    }
}
