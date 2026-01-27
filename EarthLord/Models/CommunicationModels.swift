//
//  CommunicationModels.swift
//  EarthLord
//
//  通讯系统数据模型
//  支持多种通讯设备：收音机、对讲机、营地电台、卫星通讯
//

import Foundation

// MARK: - 设备类型

/// 通讯设备类型
enum DeviceType: String, Codable, CaseIterable {
    case radio = "radio"
    case walkieTalkie = "walkie_talkie"
    case campRadio = "camp_radio"
    case satellite = "satellite"

    /// 显示名称（本地化）
    var displayName: String {
        switch self {
        case .radio: return String(localized: "device_radio")
        case .walkieTalkie: return String(localized: "device_walkie_talkie")
        case .campRadio: return String(localized: "device_base_station")
        case .satellite: return String(localized: "device_satellite")
        }
    }

    /// SF Symbol 图标名称
    var iconName: String {
        switch self {
        case .radio: return "radio"
        case .walkieTalkie: return "walkie.talkie.radio"
        case .campRadio: return "antenna.radiowaves.left.and.right"
        case .satellite: return "antenna.radiowaves.left.and.right.circle"
        }
    }

    /// 设备描述（本地化）
    var description: String {
        switch self {
        case .radio: return String(localized: "desc_receive_only")
        case .walkieTalkie: return String(format: String(localized: "desc_comm_range_format"), 3)
        case .campRadio: return String(format: String(localized: "desc_broadcast_range_format"), 30)
        case .satellite: return String(format: String(localized: "desc_contact_range_format"), 100)
        }
    }

    /// 通讯范围（公里）
    var range: Double {
        switch self {
        case .radio: return Double.infinity
        case .walkieTalkie: return 3.0
        case .campRadio: return 30.0
        case .satellite: return 100.0
        }
    }

    /// 范围文字描述（本地化）
    var rangeText: String {
        switch self {
        case .radio: return String(localized: "range_unlimited_receive_only")
        case .walkieTalkie: return String(format: String(localized: "range_format"), 3)
        case .campRadio: return String(format: String(localized: "range_format"), 30)
        case .satellite: return String(format: String(localized: "range_format"), 100) + "+"
        }
    }

    /// 是否可以发送消息
    var canSend: Bool {
        self != .radio
    }

    /// 解锁条件说明（本地化）
    var unlockRequirement: String {
        switch self {
        case .radio, .walkieTalkie: return String(localized: "unlock_default_owned")
        case .campRadio: return String(localized: "unlock_require_base_station")
        case .satellite: return String(localized: "unlock_require_comm_tower")
        }
    }
}

// MARK: - 设备模型

/// 通讯设备数据模型
struct CommunicationDevice: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let deviceType: DeviceType
    var deviceLevel: Int
    var isUnlocked: Bool
    var isCurrent: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deviceType = "device_type"
        case deviceLevel = "device_level"
        case isUnlocked = "is_unlocked"
        case isCurrent = "is_current"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 导航枚举

/// 通讯系统导航区块
enum CommunicationSection: String, CaseIterable {
    case messages
    case channels
    case call
    case devices

    /// 显示名称（本地化）
    var displayName: String {
        switch self {
        case .messages: return String(localized: "nav_messages")
        case .channels: return String(localized: "nav_channels")
        case .call: return String(localized: "nav_calls")
        case .devices: return String(localized: "nav_devices")
        }
    }

    /// SF Symbol 图标名称
    var iconName: String {
        switch self {
        case .messages: return "bell.fill"
        case .channels: return "dot.radiowaves.left.and.right"
        case .call: return "phone.fill"
        case .devices: return "gearshape.fill"
        }
    }
}
