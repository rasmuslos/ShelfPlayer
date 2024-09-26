//
//  NavigationController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.09.24.
//

import Foundation
import SwiftUI

internal class NavigationController: ObservableObject {
    @Published var paths: [TabValue: NavigationPath]
    
    init() {
        paths = [:]
    }
    
    subscript(position: TabValue) -> NavigationPath {
        get {
            if paths[position] == nil {
                paths[position] = .init()
            }
            
            return paths[position]!
        }
        set {
            paths[position] = newValue
        }
    }
}
