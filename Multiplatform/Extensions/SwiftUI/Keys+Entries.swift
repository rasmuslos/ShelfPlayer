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
    @Entry var libraries = [Library]()
    @Entry var displayContext: DisplayContext = .unknown
}

enum DisplayContext {
    case unknown
    case author(author: Author)
    case series(series: Series)
}

extension RFNotification.Notification {
    static var focusSearchField: RFNotification.Notification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayer.focusSearchField")
    }
}
