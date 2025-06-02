//
//  WidgetBackground.swift
//  WidgetsExtension
//
//  Created by Rasmus Krämer on 02.06.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Default(.tintColor) private var tintColor
    
    var body: some View {
        if colorScheme == .light {
            Rectangle()
                .fill(tintColor.color.gradient)
        } else {
            Rectangle()
                .fill(.background.secondary)
        }
    }
}

#Preview {
    WidgetBackground()
}
