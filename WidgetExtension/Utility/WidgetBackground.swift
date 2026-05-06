//
//  WidgetBackground.swift
//  WidgetExtension
//
//  Created by Rasmus Krämer on 02.06.25.
//

import SwiftUI
import ShelfPlayerKit

struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var tintColor: TintColor {
        AppSettings.shared.tintColor
    }

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
