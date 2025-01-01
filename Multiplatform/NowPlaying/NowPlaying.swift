//
//  NowPlaying.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import UIKit
import AVKit

struct NowPlaying {
    private init() {}
    
    @MainActor
    static let routePickerView = AVRoutePickerView()
}

internal extension NowPlaying {
    @MainActor
    static func presentPicker() {
        for view in routePickerView.subviews {
            guard let button = view as? UIButton else {
                continue
            }
            
            button.sendActions(for: .touchUpInside)
            break
        }
    }
    
    struct NowPlayingButtonModifier: ViewModifier {
        var fixedWidth: Bool = true
        
        func body(content: Content) -> some View {
            content
                .bold()
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: fixedWidth ? 60 : nil)
        }
    }
}


internal extension NowPlaying {
    static let widthChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.offset.changed")
}
