//
//  CreateBookmarkTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.04.24.
//

import TipKit

internal struct CreateBookmarkTip: Tip {
    var title: Text {
        .init("tip.bookmark.create")
    }
    var message: Text? {
        .init("tip.bookmark.create.message")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(5),
    ]}
}
