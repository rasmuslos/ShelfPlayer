import SwiftUI
import Foundation

// Taken from: https://www.fivestars.blog/articles/reverse-masks-how-to/

internal extension View {
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
