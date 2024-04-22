//
//  ViewBookmarkTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.04.24.
//

import TipKit

struct ViewBookmarkTip: Tip {
    var title: Text {
        .init("tip.bookmark.view")
    }
    var message: Text? {
        .init("tip.bookmark.view.message")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(5),
    ]}
}
