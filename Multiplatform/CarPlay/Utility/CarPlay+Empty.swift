//
//  CarPlay+Empty.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 24.02.26.
//

import CarPlay

extension CPListTemplate {
    func applyCarPlayLoadingState() {
        updateSections([])
        emptyViewTitleVariants = []
        emptyViewSubtitleVariants = []
        
        if #available(iOS 18.4, *) {
            showsSpinnerWhileEmpty = true
        }
    }
    func applyCarPlayEmptyState() {
        emptyViewTitleVariants = [String(localized: "item.empty")]
        emptyViewSubtitleVariants = [String(localized: "item.empty.description")]
        
        if #available(iOS 18.4, *) {
            showsSpinnerWhileEmpty = false
        }
    }
}

