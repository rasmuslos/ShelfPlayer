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
    
    /*
    public var url: URL {
        switch type {
        case .author:
            AudiobookshelfClient.shared.serverURL.appending(path: "author").appending(path: primaryID)
        case .series:
            AudiobookshelfClient.shared.serverURL.appending(path: "library").appending(path: libraryID!).appending(path: "series").appending(path: primaryID)
        default:
            AudiobookshelfClient.shared.serverURL.appending(path: "item").appending(path: primaryID)
        }
     }
     */
}
