//
//  PlaybackState.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import Defaults
import DefaultsMacros
import ShelfPlayerKit

@Observable @MainActor
final class PlaybackViewModel {
    private var _dragOffset: CGFloat
    
    var isExpanded: Bool {
        didSet {
            if isExpanded {
                _dragOffset = 0
            } else if _dragOffset == 0 {
                // this is stupid
                // this will trigger an view update
                // because the scaleEffect depends on this variable
                // and we need the NavigationStack to update
                // so it will not do so after the animation finishes, causing a ugly mess
                // if the user is dragging this already happens, so we trigger an update only when
                // the user isn't dragging (dragOffset == 0) by setting it to the same value (0)
                // If you are reading this, hire me
                _dragOffset = 0
            }
        }
    }
    
    @ObservableDefault(.skipBackwardsInterval) @ObservationIgnored
    var skipBackwardsInterval: Int
    
    private(set) var notifySkipBackwards = false
    private(set) var notifySkipForwards = false
    
    init() {
        _dragOffset = .zero
        isExpanded = false
        
        RFNotification[.skipped].subscribe { [weak self] forwards in
            if forwards {
                self?.notifySkipForwards.toggle()
            } else {
                self?.notifySkipBackwards.toggle()
            }
        }
    }
    
    var areSlidersInUse: Bool {
        false
    }
    
    var dragOffset: CGFloat {
        get {
            if isExpanded {
                return _dragOffset
            }
            
            return 0
        }
        set {
            _dragOffset = newValue
        }
    }
    var pushAmount: Percentage {
        // technically a CGFloat
        let dragHeight: Percentage = 300
        
        if dragOffset > 0 {
            return 1 - (1 - min(dragHeight, max(0, dragOffset)) / dragHeight) * 0.1
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
    var pushContainerCornerRadius: CGFloat {
        max(20, UIScreen.main.displayCornerRadius * (1 - ((1 - pushAmount) * 6)))
    }
}
