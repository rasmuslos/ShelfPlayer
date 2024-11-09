//
//  GestureModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.09.24.
//

import Foundation
import SwiftUI

internal extension NowPlaying {
    struct GestureModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        let active: Bool
        
        func body(content: Content) -> some View {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: active ? 0 : 1000, coordinateSpace: .global)
                        .onChanged {
                            guard !viewModel.controlsDragging else {
                                return
                            }
                            
                            if $0.velocity.height > 4000 {
                                viewModel.expanded = false
                            } else {
                                viewModel.dragOffset = min(1000, max(0, $0.translation.height))
                            }
                        }
                        .onEnded {
                            if $0.translation.height > 200 {
                                viewModel.expanded = false
                            } else {
                                withAnimation {
                                    viewModel.dragOffset = 0
                                }
                            }
                        }
                )
        }
    }
}
