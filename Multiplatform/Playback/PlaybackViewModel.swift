//
//  PlaybackState.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayerKit

@Observable @MainActor
final class PlaybackViewModel {
    var dragOffset: CGFloat
    
    var isExpanded: Bool {
        didSet {
            dragOffset = .zero
        }
    }
    
    init() {
        dragOffset = .zero
        isExpanded = false
    }
    
    var areSlidersInUse: Bool {
        false
    }
    
    var pushAmount: Percentage {
        if dragOffset > 0 {
            return 1 - (1 - min(300, max(0, dragOffset)) / Percentage(300)) * 0.1
        }
        
        return isExpanded ? 0.9 : 1
    }
    var isPushing: Bool {
        pushAmount < 1
    }
    
    var backgroundCornerRadius: CGFloat {
        if isExpanded {
            UIScreen.main.displayCornerRadius
        } else {
            16
        }
    }
}
