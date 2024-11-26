//
//  Untitled.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import SPFoundation

extension ItemIdentifier {
    var urlValue: String {
        var url = "\(primaryID)"
        
        if let episodeID {
            url.append("/\(episodeID)")
        }
        
        return url
    }
}
