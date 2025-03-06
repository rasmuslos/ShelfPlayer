//
//  ActorArray.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation

final actor ActorArray<Element> {
    var elements: [Element]
    
    init() {
        self.elements = []
    }
    init(elements: [Element]) {
        self.elements = elements
    }
    
    func append(_ element: Element) {
        elements.append(element)
    }
    
    func removeFirst() -> Element? {
        if elements.isEmpty {
            nil
        } else {
            elements.removeFirst()
        }
    }
    func remove(at index: Int) {
        elements.remove(at: index)
    }
    func removeSubrange(_ bounds: Range<Int>) {
        elements.removeSubrange(bounds)
    }
    func removeAll() {
        elements.removeAll()
    }
}
