//
//  Environment+Keys.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation
import SwiftUI

public extension EnvironmentValues {
    @Entry var library: Library? = nil
    @Entry var connectionID: ItemIdentifier.ConnectionID? = nil
    
    @Entry var displayContext: DisplayContext = .unknown
    
    @Entry var playbackBottomOffset: CGFloat = 0
}

public enum DisplayContext {
    case unknown
    case person(Person)
    case series(Series)
    case collection(ItemCollection)
}
