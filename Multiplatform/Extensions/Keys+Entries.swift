//
//  Defaults+Keys.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import Foundation
import Defaults
import ShelfPlayerKit

extension Defaults.Keys {
    static let lastTabValue = Key<TabValue?>("lastTabValue")
    
    static let tintColor = Key("tintColor", default: TintPicker.TintColor.shelfPlayer)
    
    static let carPlayTabBarLibraries = Key<[Library]?>("carPlayTabBarLibraries", default: nil)
    static let carPlayShowListenNow = Key<Bool>("carPlayShowListenNow", default: true)
    static let carPlayShowOtherLibraries = Key<Bool>("carPlayShowOtherLibraries", default: true)
}

extension RFNotification.IsolatedNotification {
    static var focusSearchField: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayer.focusSearchField") }
    
    static var navigate: IsolatedNotification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.one") }
    static var navigateConditionMet: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayer.navigate.notify") }
    static var _navigate: IsolatedNotification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.two") }
    
    static var changeLibrary: IsolatedNotification<Library> { .init("io.rfk.shelfPlayer.changeLibrary") }
    static var changeOfflineMode: IsolatedNotification<Bool> { .init("io.rfk.shelfPlayer.changeOfflineMode") }
    
    static var performBackgroundSessionSync: IsolatedNotification<ItemIdentifier.ConnectionID?> { .init("io.rfk.shelfPlayer.performBackgroundSessionSync") }
}
