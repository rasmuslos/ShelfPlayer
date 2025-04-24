//
//  ListenNowSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import ShelfPlayerKit

struct ListenNowSheet: View {
    @State private var isLoading = false
    @State private var listenNowItems = [PlayableItem]()
    
    var body: some View {
        if listenNowItems.isEmpty {
            if isLoading {
                LoadingView()
            }
        }
    }
}

#Preview {
    ListenNowSheet()
}
