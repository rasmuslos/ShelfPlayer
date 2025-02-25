//
//  PlaybackDragGestureCatcher.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI

struct PlaybackDragGestureCatcher: ViewModifier {
    @Environment(PlaybackViewModel.self) private var viewModel
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: active ? 0 : 1000, coordinateSpace: .global)
                    .onChanged {
                        guard !viewModel.areSlidersInUse else {
                            return
                        }
                        
                        if $0.velocity.height > 4000 {
                            viewModel.isExpanded = false
                        } else {
                            viewModel.dragOffset = min(1000, max(0, $0.translation.height))
                        }
                    }
                    .onEnded {
                        if $0.translation.height > 200 {
                            viewModel.isExpanded = false
                        } else {
                            withAnimation {
                                viewModel.dragOffset = 0
                            }
                        }
                    }
            )
    }
}
