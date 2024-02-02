//
//  LocalizedStringKey+Key.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.11.23.
//

import Foundation
import SwiftUI

extension LocalizedStringKey {
    // stupid
    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }
}
