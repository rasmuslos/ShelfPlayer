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
    @Environment(\.library) private var library
    
    let name: String
    let type: ItemIdentifier.ItemType
    var footer: String? = nil
    
    @ViewBuilder
    private var labelContent: some View {
        Label(type.viewLabel, systemImage: type.icon)
        
        if let footer {
            Text(footer)
        }
    }
    
    var body: some View {
        if library == nil {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                let _ = fatalError("Cannot load itemIDs without a library.")
            }
            #endif
        } else {
            NavigationLink(destination: ItemIDLoadView(name: name, type: type)) {
                labelContent
            }
            .disabled(satellite.isOffline)
        }
    }
}
