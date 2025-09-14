//
//  PlaybackDragGestureCatcher.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI

struct PlaybackDragGestureCatcher: ViewModifier {
    @Environment(PlaybackViewModel.self) private var viewModel
    
    let height: CGFloat
    
    var isActive: Bool {
        height > 0
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: isActive ? 10 : 1000, coordinateSpace: .global)
                    .onChanged {
                        viewModel.translationY = min(600, max(0, $0.translation.height))
                    }
                    .onEnded {
                        // Dragged more then half of the screen
                        if $0.translation.height >= height / 2 {
                            viewModel.toggleExpanded()
                        }
                        
                        // Dragged below lower screen third
                        else if $0.location.y >= (height / 3) * 2 {
                            viewModel.toggleExpanded()
                        }
                        
                        // High velocity drag
                        else if $0.velocity.height > 3000 {
                            viewModel.toggleExpanded()
                        }
                        
                        // Reset drag
                        else {
                            viewModel.translateYAnimationCount += 1
                            
                            withAnimation(.snappy) {
                                viewModel.translationY = 0
                            } completion: {
                                viewModel.translateYAnimationCount -= 1
                            }
                        }
                    }
            )
    }
}
