//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 09.07.24.
//

import Foundation
import CommonCrypto

extension Data {
    var sha256: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        
        return Data(hash)
    }
}
