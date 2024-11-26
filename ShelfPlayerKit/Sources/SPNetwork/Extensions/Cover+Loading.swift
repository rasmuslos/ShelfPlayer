//
//  Cover+Image.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.09.24.
//

import Foundation
import Nuke
import SPFoundation

#if canImport(UIKit)
import UIKit
#endif

public extension Cover {
    var data: Data? {
        get async {
            nil
        }
    }
    
    var platformImage: PlatformImage? {
        get async {
            guard let data = await data else {
                return nil
            }
            
            return PlatformImage(data: data)
        }
    }
    
    #if canImport(UIKit)
    typealias PlatformImage = UIImage
    #endif
}
