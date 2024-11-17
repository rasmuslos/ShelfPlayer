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
    
    @Entry var namespace: NamespaceWrapper!
}

internal enum DisplayContext {
    case unknown
    case author(author: Author)
    case series(series: Series)
}

@Observable
final class NamespaceWrapper {
    var namepace: Namespace.ID
    
    init(_ namepace: Namespace.ID) {
        self.namepace = namepace
    }
}
