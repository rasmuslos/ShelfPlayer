//
//  SafeAreaModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPPlayback

// This is more or less copied from AmpFin

struct NowPlayingBarLeadingOffsetModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GeometryReader { reader in
                Color.clear
                    .onChange(of: reader.frame(in: .global).origin) {
                        if reader.size.width < 400 {
                            NotificationCenter.default.post(name: SidebarView.offsetChangeNotification, object: reader.frame(in: .global).origin.x + reader.size.width)
                        }
                    }
            }
            .frame(height: 0)
            content
        }
    }
}

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isVisible: Bool {
        AudioPlayer.shared.item != nil
    }
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .safeAreaPadding(.bottom, isVisible ? 75 : 0)
        } else {
            ZStack {
                GeometryReader { reader in
                    Color.clear
                        .onAppear {
                            NotificationCenter.default.post(name: SidebarView.widthChangeNotification, object: reader.size.width)
                        }
                        .onChange(of: reader.size.width) {
                            NotificationCenter.default.post(name: SidebarView.widthChangeNotification, object: reader.size.width)
                        }
                }
                .frame(height: 0)
                
                content
                    .safeAreaPadding(.bottom, isVisible ? 75 : 0)
            }
        }
    }
}

extension SidebarView {
    static let widthChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.offset.changed")
}
