//
//  ItemIDLoadLink.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemIDLoadLink: View {
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
            let _ = fatalError("Unsupported display context")
        } else {
            NavigationLink(destination: ItemIDLoadView(name: name, type: type)) {
                labelContent
            }
        }
    }
}
