//
//  MessageCenterView.swift
//  EarthLord
//
//  消息中心页面
//

import SwiftUI

struct MessageCenterView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.fill").font(.system(size: 50)).foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))
            Text(LocalizedString.messageCenter).font(.title3).fontWeight(.medium).foregroundColor(ApocalypseTheme.textPrimary)
            Text(LocalizedString.day34Implementation).font(.caption).foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
}

#Preview {
    MessageCenterView()
}
