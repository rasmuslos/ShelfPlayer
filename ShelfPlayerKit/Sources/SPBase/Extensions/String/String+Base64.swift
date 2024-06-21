//
//  String+Base64.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

internal extension String {
    var base64: String {
        Data(self.utf8).base64EncodedString()
    }
}
