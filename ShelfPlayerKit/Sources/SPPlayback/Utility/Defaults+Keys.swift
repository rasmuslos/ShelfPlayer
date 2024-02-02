//
//  Defaults.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults

public extension Defaults.Keys {
    static let skipForwardsInterval = Key<Int>("skipForwardsInterval", default: 30)
    static let skipBackwardsInterval = Key<Int>("skipBackwardsInterval", default: 30)
    
    static let enableChapterTrack = Key<Bool>("enableChapterTrack", default: false)
}
