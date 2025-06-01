//
//  DownloadStatus.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation

public enum DownloadStatus: Int, Identifiable, Equatable, Codable, Hashable, Sendable, CaseIterable {
    case none
    case downloading
    case completed
    
    public var id: Int {
        rawValue
    }
}
