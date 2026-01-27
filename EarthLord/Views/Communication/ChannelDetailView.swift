//
//  ChannelDetailView.swift
//  EarthLord
//
//  频道详情页面
//

import SwiftUI

struct ChannelDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "info.circle").font(.system(size: 50)).foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))
            Text(LocalizedString.channelDetails).font(.title3).fontWeight(.medium).foregroundColor(ApocalypseTheme.textPrimary)
            Text(LocalizedString.day33Implementation).font(.caption).foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
}

#Preview {
    ChannelDetailView()
}
