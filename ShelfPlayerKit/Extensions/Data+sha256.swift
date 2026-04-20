//
//  Data+sha256.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 09.07.24.
//

import Foundation
import CryptoKit

extension Data {
    var sha256: Data {
        Data(SHA256.hash(data: self))
    }
}
