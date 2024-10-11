//
//  Alignment+Text.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI

internal extension HorizontalAlignment {
    var textAlignment: TextAlignment {
        switch self {
            case .leading:
                    .leading
            case .trailing:
                    .trailing
            default:
                    .center
        }
    }
}
