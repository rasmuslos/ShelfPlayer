//
//  Environment+Keys.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

extension EnvironmentValues {
    @Entry var library: Library? = nil    
    @Entry var displayContext: DisplayContext = .unknown
    
    @Entry var connectionID: ItemIdentifier.ConnectionID? = nil
    
    @Entry var playbackBottomOffset: CGFloat = 0
}

enum DisplayContext {
    case unknown
    case author(author: Author)
    case series(series: Series)
}

extension RFNotification.Notification {
    static var focusSearchField: RFNotification.Notification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayer.focusSearchField") }
    
    static var navigateNotification: Notification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.one") }
    static var _navigateNotification: Notification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.two") }
    
    static var changeLibrary: Notification<Library> { .init("io.rfk.shelfPlayer.changeLibrary") }
    static var changeOfflineMode: Notification<Bool> { .init("io.rfk.shelfPlayer.changeOfflineMode") }
}
