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
    @ViewBuilder
    func modify<T: View>(if condition: Bool, @ViewBuilder _ modifier: (Self) -> T) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
    @ViewBuilder
    func modify<T: View, O: Any>(if optional: Optional<O>, @ViewBuilder _ modifier: (Self, O) -> T) -> some View {
        if let optional {
            modifier(self, optional)
        } else {
            self
        }
    }
}

#Preview {
    @Previewable @State var test = false
    
    Button(String("toggle")) {
        test.toggle()
    }
    .modify(if: test) {
        $0
            .foregroundStyle(.red)
    }
}
