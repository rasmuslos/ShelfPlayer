//
//  View+Modify.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.10.24.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
    
    #if DEBUG
    @ViewBuilder
    func previewEnvironment() -> some View {
        @Namespace var namespace
        
        self
            .environment(Satellite())
            .environment(ConnectionStore())
            .environment(\.namespace, namespace)
    }
    #endif
}
