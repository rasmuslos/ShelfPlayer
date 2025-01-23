//
//  View+Modify.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.10.24.
//

import Foundation
import SwiftUI

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
    
    func previewEnvironment() -> some View {
        self
    }
}
