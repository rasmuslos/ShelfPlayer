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
    private var _isExpanded: Bool
    private var _dragOffset: CGFloat
    
    var seeking: Percentage?
    var volumePreview: Percentage?
    
    @ObservableDefault(.skipBackwardsInterval) @ObservationIgnored
    var skipBackwardsInterval: Int
    @ObservableDefault(.skipForwardsInterval) @ObservationIgnored
    var skipForwardsInterval: Int
    
    private(set) var notifySkipBackwards = false
    private(set) var notifySkipForwards = false
    
    init() {
        _dragOffset = .zero
        _isExpanded = false
        
        RFNotification[.skipped].subscribe { [weak self] forwards in
            if forwards {
                self?.notifySkipForwards.toggle()
            } else {
                self?.notifySkipBackwards.toggle()
            }
        }
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.isExpanded = false
            self?.dragOffset = 0
        }
    }
    
    var isExpanded: Bool {
        get {
            _isExpanded
        }
        set {
            _isExpanded = newValue
            
            if newValue {
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
        let dragHeight: Percentage = 500
        
        if dragOffset > 0 {
            return 1 - (1 - min(dragHeight, max(0, dragOffset)) / dragHeight) * 0.15
        }
        
        return isExpanded ? 0.85 : 1
    }
    
    var areSlidersInUse: Bool {
        seeking != nil || volumePreview != nil
    }
    
    var backgroundCornerRadius: CGFloat {
        if isExpanded {
            UIScreen.main.displayCornerRadius
        } else {
            16
        }
    }
    func pushContainerCornerRadius(leadingOffset: CGFloat) -> CGFloat {
        max(16, UIScreen.main.displayCornerRadius - leadingOffset)
    }
}
