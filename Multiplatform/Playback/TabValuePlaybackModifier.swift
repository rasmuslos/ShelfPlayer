//
//  TabValuePlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI

struct TabValuePlaybackModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
        }
    }
}
