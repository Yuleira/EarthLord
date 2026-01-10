import Foundation

// 探索统计
struct ExplorationStats {
    let totalDistance: Double
    let duration: TimeInterval
    let pointsVerified: Int
    let distanceRank: String
    
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// 探索结果
struct ExplorationResult {
    let isSuccess: Bool
    let message: String
    let itemsCollected: [CollectedItem]
    let experienceGained: Int
    let distanceWalked: Double
    let stats: ExplorationStats
    
    // 补上 View 需要的时间字段
    let startTime: Date
    let endTime: Date
}
