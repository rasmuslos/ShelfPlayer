//
//  Bookmark.swift
//  
//
//  Created by Rasmus Krämer on 02.07.24.
//

import Foundation

public struct Bookmark: Codable {
    public let libraryItemId: String
    public let title: String
    public let time: Double
    public let createdAt: Double
}
