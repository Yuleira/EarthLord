//
//  ChannelCenterView.swift
//  EarthLord
//
//  频道中心页面
//

import SwiftUI

struct ChannelCenterView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 50)).foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))
            Text(LocalizedString.channelCenter).font(.title3).fontWeight(.medium).foregroundColor(ApocalypseTheme.textPrimary)
            Text(LocalizedString.day33Implementation).font(.caption).foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
}

#Preview {
    ChannelCenterView()
}
