//
//  CarPlayItemController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.04.25.
//
import Foundation
@preconcurrency import CarPlay
protocol CarPlayItemController: AnyObject {
    var row: CPListItem { get }
}
extension CPListTemplate {
    func applyCarPlayLoadingState() {
        updateSections([])
        emptyViewTitleVariants = [""]
        emptyViewSubtitleVariants = [""]
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
