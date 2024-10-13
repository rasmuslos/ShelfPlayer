//
//  FeedbackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 13.10.24.
//

import Foundation
import SwiftUI

internal extension NowPlaying {
    struct FeedbackModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        func body(content: Content) -> some View {
            content
                .sensoryFeedback(.selection, trigger: viewModel.notifyForwards)
                .sensoryFeedback(.selection, trigger: viewModel.notifyPlaying)
                .sensoryFeedback(.selection, trigger: viewModel.notifyBackwards)
                .sensoryFeedback(.error, trigger: viewModel.notifyError)
                .sensoryFeedback(.alignment, trigger: viewModel.notifyBookmark)
        }
    }
}
