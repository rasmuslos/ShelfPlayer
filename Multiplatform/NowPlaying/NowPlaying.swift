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
}

extension NowPlaying {
    static let widthChangeNotification = NSNotification.Name("io.rfk.shelfplayer.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.shelfplayer.sidebar.offset.changed")
}

extension NowPlaying {
    struct AirPlayPicker: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let routePickerView = AVRoutePickerView()
            routePickerView.backgroundColor = UIColor.clear
            routePickerView.activeTintColor = UIColor(Color.accentColor)
            routePickerView.tintColor = UIColor(Color.secondary)
            
            return routePickerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
}
