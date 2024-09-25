//
//  NavigationStacks.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI

@Observable
internal class NavigationState {
    private var paths: [TabValue: NavigationPath]
    
    private init() {
        paths = [:]
    }
    
    public subscript(index: TabValue) -> NavigationPath {
        set {
            paths[index] = newValue
        }
        get {
            if paths[index] == nil {
                paths[index] = .init()
            }
            
            return paths[index]!
        }
    }
    
    static let shared = NavigationState()
}
