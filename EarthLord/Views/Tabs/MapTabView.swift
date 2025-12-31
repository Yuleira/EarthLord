//
//  MapTabView.swift
//  EarthLord
//
//  Created by Yu Lei on 24/12/2025.
//

import SwiftUI

struct MapTabView: View {
    var body: some View {
        PlaceholderView(
            icon: "map.fill",
            title: "地图".localized,
            subtitle: "探索和圈占领地".localized
        )
    }
}

#Preview {
    MapTabView()
}
