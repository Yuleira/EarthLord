//
//  PTTCallView.swift
//  EarthLord
//
//  呼叫中心页面
//

import SwiftUI

struct PTTCallView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "phone.fill").font(.system(size: 50)).foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))
            Text(LocalizedString.callCenter).font(.title3).fontWeight(.medium).foregroundColor(ApocalypseTheme.textPrimary)
            Text(LocalizedString.day36Implementation).font(.caption).foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
}

#Preview {
    PTTCallView()
}
