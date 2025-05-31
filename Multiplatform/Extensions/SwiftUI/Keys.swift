//
//  Environment+Keys.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

extension EnvironmentValues {
    @Entry var library: Library? = nil    
    @Entry var displayContext: DisplayContext = .unknown
    
    @Entry var connectionID: ItemIdentifier.ConnectionID? = nil
    
    @Entry var playbackBottomOffset: CGFloat = 0
}

enum DisplayContext {
    case unknown
    case person(person: Person)
    case series(series: Series)
}
