//
//  WidgetAppIcon.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import SwiftUI

struct WidgetAppIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Image("shelfPlayer.fill")
            .foregroundStyle(colorScheme == .light ? .black : .white)
    }
}
