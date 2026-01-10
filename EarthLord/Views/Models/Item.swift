import Foundation
import SwiftUI

// 1. 物品品质
enum ItemQuality: String, Codable, CaseIterable {
    case pristine = "完美"
    case good = "良好"
    case worn = "陈旧"
    case damaged = "破损"
    case ruined = "报废"
    
    var color: Color {
        switch self {
        case .pristine: return .purple
        case .good: return .blue
        case .worn: return .green
        case .damaged: return .orange
        case .ruined: return .gray
        }
    }
}

// 2. 物品类别 (这里的名字必须跟报错里的一模一样)
enum ItemCategory: String, Codable, CaseIterable {
    case water = "水"
    case food = "食物"
    case medical = "药品"
    case material = "材料"
    case tool = "工具"
    case weapon = "武器"
    case other = "其他"
}

// 3. 物品定义
struct ItemDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ItemCategory
    let icon: String // 之前叫 iconName，改回 icon
}

// 4. 收集到的物品
struct CollectedItem: Identifiable, Codable {
    let id: UUID
    let definition: ItemDefinition
    let quality: ItemQuality
    let foundDate: Date
    
    init(id: UUID = UUID(), definition: ItemDefinition, quality: ItemQuality, foundDate: Date = Date()) {
        self.id = id
        self.definition = definition
        self.quality = quality
        self.foundDate = foundDate
    }
}
