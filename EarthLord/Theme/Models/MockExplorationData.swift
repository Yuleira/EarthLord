import Foundation

struct MockExplorationData {
    
    // 模拟定义
    static let sampleItemDef = ItemDefinition(
        id: "water_bottle",
        name: "纯净水",
        description: "一瓶还算干净的水。",
        category: .water, // 改成 .water
        icon: "drop.fill" // 改成 icon
    )
    
    // 模拟物品
    static let sampleItem = CollectedItem(
        definition: sampleItemDef,
        quality: .good,
        foundDate: Date()
    )
    
    // 模拟统计
    static let sampleExplorationStats = ExplorationStats(
        totalDistance: 1250.5,
        duration: 3600,
        pointsVerified: 5,
        distanceRank: "A" // 补上 Rank
    )
    
    // 模拟结果
    static let sampleExplorationResult = ExplorationResult(
        isSuccess: true,
        message: "探索成功！",
        itemsCollected: [sampleItem, sampleItem], // 改成 itemsCollected
        experienceGained: 150,
        distanceWalked: 1250.5, // 补上距离
        stats: sampleExplorationStats
    )
}
