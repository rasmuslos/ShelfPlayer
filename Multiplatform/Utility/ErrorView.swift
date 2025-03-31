//
//  ErrorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct ErrorView: View {
    var itemID: ItemIdentifier?
    
    private var icon: String {
        if let itemID {
            itemID.type.icon
        } else {
            "xmark"
        }
    }
    private var label: LocalizedStringKey {
        if let itemID {
            itemID.type.errorLabel
        } else {
            "error.unavailable"
        }
    }
    
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView(label, systemImage: icon, description: Text("error.unavailable.text"))
        }
    }
}

#if DEBUG
#Preview {
    ErrorView()
}
#Preview {
    ErrorView(itemID: .fixture)
}
#endif
