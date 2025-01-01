//
//  Search.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 15.11.24.
//

import Foundation
@preconcurrency import Combine
import ShelfPlayerKit

struct Search: Sendable {
    private let searchSubject: PassthroughSubject<(Library?, String), Never>
    
    private init() {
        searchSubject = .init()
    }
    
    func emit(library: Library?, search: String) {
        searchSubject.send((library, search))
    }
    
    var searchPublisher: AnyPublisher<(Library?, String), Never> {
        searchSubject.eraseToAnyPublisher()
    }
    
    static let shared = Search()
}
