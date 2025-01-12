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
    @Entry var libraries = [Library]()
    @Entry var displayContext: DisplayContext = .unknown
    
    @Entry var namespace: NamespaceWrapper!
}

enum DisplayContext {
    case unknown
    case author(author: Author)
    case series(series: Series)
}

@Observable @MainActor
final class NamespaceWrapper {
    var namespace: Namespace.ID
    
    init(_ namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    func callAsFunction() -> Namespace.ID {
        namespace
    }
}
