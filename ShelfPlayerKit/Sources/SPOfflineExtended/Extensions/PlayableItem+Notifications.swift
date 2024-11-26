//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 16.01.24.
//

import Foundation
import Combine
import SPFoundation

public extension PlayableItem {
    static let downloadStatusUpdatedSubject = PassthroughSubject<(ItemIdentifier), Never>()
    static var downloadStatusUpdatedPublisher: AnyPublisher<(ItemIdentifier), Never> {
        downloadStatusUpdatedSubject.eraseToAnyPublisher()
    }
}
