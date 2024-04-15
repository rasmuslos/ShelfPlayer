//
//  CommonTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 15.04.24.
//

import Foundation
import TipKit

struct CommonTip: Tip {
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    
    var title: Text {
        Text(titleKey)
    }
    
    var message: Text? {
        Text(messageKey)
    }
    
    var options: [TipOption] = [
        MaxDisplayCount(5)
    ]
}

extension LocalizedStringKey: @unchecked Sendable {}
