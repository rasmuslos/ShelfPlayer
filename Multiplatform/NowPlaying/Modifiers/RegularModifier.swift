//
//  Modifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal extension NowPlaying {
    struct RegularModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(ViewModel.self) private var viewModel
        
        func body(content: Content) -> some View {
            @Bindable var viewModel = viewModel
            
            if horizontalSizeClass != .compact {
                content
                    .modifier(RegularBarModifier())
                    .sheet(isPresented: $viewModel.expanded) {
                        RegularView()
                    }
            } else {
                content
            }
        }
    }
}
