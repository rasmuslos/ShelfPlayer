//
//  CompactToolbarModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.09.25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func largeTitleDisplayMode() -> some View {
        if #available(iOS 26, *) {
            self
                .toolbarTitleDisplayMode(.inlineLarge)
        } else {
            self
        }
    }
}
