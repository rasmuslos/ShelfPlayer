//
//  HideFromContinueListeningEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 10.08.24.
//

import Foundation
import Defaults

public struct HideFromContinueListeningEntity: Codable, _DefaultsSerializable {
    public let itemId: String
    public let episodeId: String?
}
