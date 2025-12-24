//
//  ItemIDLoadLink.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import SwiftUI
import ShelfPlayback

struct ItemIDLoadLink: View {
    @Environment(Satellite.self) private var satellite
    @Environment(OfflineMode.self) private var offlineMode
    @Environment(\.navigationContext) private var navigationContext
    
    let name: String
    let type: ItemIdentifier.ItemType
    var footer: String? = nil
    
    @ViewBuilder
    private var labelContent: some View {
        if #available(iOS 26.0, *), false {
            if let footer {
                Label(footer, systemImage: type.icon)
            } else {
                Label(type.viewLabel, systemImage: type.icon)
            }
        } else {
            Label(type.viewLabel, systemImage: type.icon)
            
            if let footer {
                Text(footer)
            }
        }
    }
    
    var body: some View {
        if let navigationContext {
            Button {
                navigationContext.path.append(.itemName(name, type))
            } label: {
                labelContent
            }
            .disabled(offlineMode.isEnabled)
        } else {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                let _ = fatalError("Cannot load itemIDs without a library.")
            }
            #endif
        }
    }
}
