//
//  View+Modify.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.10.25.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
}
