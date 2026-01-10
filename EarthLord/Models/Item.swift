import Foundation
import SwiftUI

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

enum ItemCategory: String, Codable, CaseIterable {
    case water = "水"
    case food = "食物"
    case medical = "药品"
    case material = "材料"
    case tool = "工具"
    case weapon = "武器"
    case other = "其他"
}

struct ItemDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ItemCategory
    let icon: String
}

struct CollectedItem: Identifiable, Codable {
    let id: UUID
    let definition: ItemDefinition
    let quality: ItemQuality
    let foundDate: Date
    var quantity: Int = 1 // 补上 quantity
    
    // 补上 itemId，让 View 能找到它
    var itemId: String {
        return definition.id
    }
    
    init(id: UUID = UUID(), definition: ItemDefinition, quality: ItemQuality, foundDate: Date = Date(), quantity: Int = 1) {
        self.id = id
        self.definition = definition
        self.quality = quality
        self.foundDate = foundDate
        self.quantity = quantity
    }
}
