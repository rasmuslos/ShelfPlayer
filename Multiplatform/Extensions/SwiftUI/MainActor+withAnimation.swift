//
//  MainActor+withAnimation.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import SwiftUI

extension MainActor {
    static func withAnimation<T: Sendable>(_ animation: Animation? = nil, _ body: @MainActor () -> T) async {
        let _ = await MainActor.run {
            SwiftUI.withAnimation(animation) {
                body()
            }
        }
    }
}
