//
//  View+ReverseMask.swift
//  ShelfPlayer
//

import SwiftUI
import Foundation

extension View {
    @inlinable
    func reverseMask<Mask: View>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}
