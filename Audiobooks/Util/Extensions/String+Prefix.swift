//
//  String+Prefix.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension String {
    mutating func prefix(_ prefix: String) {
        self = prefix + self
    }
}
