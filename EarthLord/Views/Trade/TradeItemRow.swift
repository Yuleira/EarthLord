//
//  TradeItemRow.swift
//  EarthLord
//
//  交易物品行组件
//  在发布挂单表单中显示单个物品
//

import SwiftUI

struct TradeItemRow: View {
    let item: TradeItem
    let onDelete: () -> Void

    @StateObject private var inventoryManager = InventoryManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // 物品图标
            Image(systemName: inventoryManager.resourceIconName(for: item.itemId))
                .foregroundColor(ApocalypseTheme.info)
                .frame(width: 30)
                .font(.title3)

            // 物品名称和数量
            VStack(alignment: .leading, spacing: 2) {
                Text(inventoryManager.resourceDisplayName(for: item.itemId))
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text("×\(item.quantity)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 删除按钮
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(ApocalypseTheme.danger)
                    .font(.body)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    List {
        TradeItemRow(
            item: TradeItem(itemId: "wood", quantity: 30),
            onDelete: {}
        )
        TradeItemRow(
            item: TradeItem(itemId: "stone", quantity: 20),
            onDelete: {}
        )
    }
}
