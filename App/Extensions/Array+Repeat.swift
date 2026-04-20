//
//  Array+Repeat.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.10.23.
//

import Foundation

extension Array {
    init(repeating: Element, count: Int) {
        self.init((0..<count).map { _ in repeating })
    }
}
