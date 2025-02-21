//
//  ActorArray.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation

final actor ActorArray<Element> {
    var elements: [Element] = []
    
    func append(_ element: Element) {
        elements.append(element)
    }
    
    func remove(at index: Int) {
        elements.remove(at: index)
    }
    func removeAll() {
        elements.removeAll()
    }
}
