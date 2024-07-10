//
//  HomeRow.swift
//  
//
//  Created by Rasmus Krämer on 09.07.24.
//

import Foundation

public struct HomeRow<T: Item>: Identifiable {
    public let id: String
    public let label: String
    public let entities: [T]
    
    public init(id: String, label: String, entities: [T]) {
        self.id = id
        self.label = label
        self.entities = entities
    }
}
