//
//  Defaults+Keys.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import Foundation
import ShelfPlayback

extension Defaults.Keys {
    static let lastTabValue = Key<TabValue?>("lastTabValue")
    
    static let carPlayTabBarLibraries = Key<[Library]?>("carPlayTabBarLibraries", default: nil)
    static let carPlayShowListenNow = Key<Bool>("carPlayShowListenNow", default: true)
    static let carPlayShowOtherLibraries = Key<Bool>("carPlayShowOtherLibraries", default: true)
}

extension RFNotification.IsolatedNotification {
    static var setGlobalSearch: IsolatedNotification<(String, SearchViewModel.SearchScope)> { .init("io.rfk.shelfPlayer.setGlobalSearch") }
    
    static var navigateConditionMet: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayer.navigate.notify") }
    static var _navigate: IsolatedNotification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.two") }
}
