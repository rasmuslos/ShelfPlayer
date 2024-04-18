//
//  LongPressSeekTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.04.24.
//

import TipKit

struct LongPressSeekTip: Tip {
    var title: Text {
        .init("tip.player.longPress")
    }
    var message: Text? {
        .init("tip.player.longPress.message")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(5),
    ]}
}
