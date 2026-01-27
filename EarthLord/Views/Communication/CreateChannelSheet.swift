//
//  CreateChannelSheet.swift
//  EarthLord
//
//  创建频道页面
//

import SwiftUI

struct CreateChannelSheet: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "plus.circle").font(.system(size: 50)).foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))
            Text(LocalizedString.createChannel).font(.title3).fontWeight(.medium).foregroundColor(ApocalypseTheme.textPrimary)
            Text(LocalizedString.day33Implementation).font(.caption).foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
}

#Preview {
    CreateChannelSheet()
}
