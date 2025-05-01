//
//  CarPlayItemRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.04.25.
//

import Foundation
import CarPlay

@MainActor
protocol CarPlayItemController: Sendable {
    var row: CPListItem { get }
}
