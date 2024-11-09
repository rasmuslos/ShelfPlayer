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

internal extension EnvironmentValues {
    @Entry var libraries = [Library]()
    @Entry var displayContext: DisplayContext = .unknown
}

internal enum DisplayContext {
    case unknown
    case series(series: Series)
}
