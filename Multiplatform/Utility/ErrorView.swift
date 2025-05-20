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
    
    var body: some View {
        UnavailableWrapper {
            ErrorViewInner(label: itemID?.type.errorLabel, systemImage: itemID?.type.icon)
        }
    }
}

struct ErrorViewInner: View {
    var label: LocalizedStringKey? = nil
    var systemImage: String? = nil
    
    var body: some View {
        ContentUnavailableView(label ?? "error.unavailable", systemImage: systemImage ?? "xmark", description: Text("error.unavailable.text"))
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
