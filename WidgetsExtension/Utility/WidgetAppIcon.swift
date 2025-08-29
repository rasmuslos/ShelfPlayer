//
//  WidgetAppIcon.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import SwiftUI
import ShelfPlayerKit

struct WidgetAppIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(intent: CreateBookmarkIntent()) {
            Label(String("ShelfPlayer"), systemImage: "shelfPlayer.fill")
                .foregroundStyle(colorScheme == .light ? .black : .white)
        }
    }
}
