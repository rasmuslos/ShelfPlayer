//
//  SelectLibraryTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.04.24.
//

import TipKit

internal struct SelectLibraryTip: Tip {
    var title: Text {
        .init("tip.changeLibrary")
    }
    var message: Text? {
        .init("tip.changeLibrary.message")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(5),
    ]}
}

