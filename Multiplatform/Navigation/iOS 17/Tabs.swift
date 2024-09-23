//
//  Tabs.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

@available(iOS, deprecated: 18.0, message: "Use `TabRouter` instead.")
internal struct Tabs: View {
    let current: Library
    
    var body: some View {
        TabView {
            ForEach(TabValue.tabs(for: current)) { tab in
                tab.content
                    .tag(tab)
                    .tabItem {
                        Label(tab.label, systemImage: tab.image)
                    }
            }
        }
    }
}
