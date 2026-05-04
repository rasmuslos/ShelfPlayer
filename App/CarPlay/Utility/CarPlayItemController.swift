//
//  CarPlayItemController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.04.25.
//

import Foundation
@preconcurrency import CarPlay

@MainActor
protocol CarPlayItemController: AnyObject {
    var row: CPListItem { get }
}
