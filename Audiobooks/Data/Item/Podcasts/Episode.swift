//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

class Episode: Item {
    lazy var releaseDate: Date? = {
        if let released = released {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            return dateFormatter.date(from: released)
        }
        
        return nil
    }()
}
