//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Rasmus Krämer on 29.05.25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        LastListenedWidget()
        ListenedTodayWidget()
        ListenNowWidget()
    }
}
