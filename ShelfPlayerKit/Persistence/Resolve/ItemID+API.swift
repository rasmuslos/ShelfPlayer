//
//  Untitled.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation


extension ItemIdentifier {
    var pathComponent: String {
        if let groupingID {
            "\(groupingID)/\(primaryID)"
        } else {
            primaryID
        }
    }
    
    var apiItemID: String {
        if let groupingID {
            groupingID
        } else {
            primaryID
        }
    }
    var apiEpisodeID: String? {
        if groupingID != nil {
            primaryID
        } else {
            nil
        }
    }
}
