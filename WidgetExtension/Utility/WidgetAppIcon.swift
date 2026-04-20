//
//  WidgetAppIcon.swift
//  WidgetExtension
//
//  Created by Rasmus Krämer on 01.06.25.
//

import SwiftUI
import ShelfPlayerKit

struct WidgetAppIcon: View {
    @Environment(\.colorScheme) private var colorScheme

    private var tintColor: TintColor { AppSettings.shared.tintColor }

    var body: some View {
        Button(intent: CreateBookmarkIntent()) {
            Label(String("ShelfPlayer"), image: "shelfPlayer.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(colorScheme == .dark ? tintColor.color : .black)
        }
        .buttonStyle(.plain)
    }
}
