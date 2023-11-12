//
//  NowPlayingSheet+BottomButtons.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import AVKit

extension NowPlayingSheet {
    struct BottomButtons: View {
        @Binding var showChaptersSheet: Bool
        
        var body: some View {
            HStack {
                PlaybackSpeedSelector()
                    .foregroundStyle(.secondary)
                
                Spacer()
                SleepTimerButton()
                    .foregroundStyle(.secondary)
                
                Spacer()
                AirPlayView()
                    .frame(width: 45)
                    .padding(.vertical, -100)
                
                Spacer()
                Button {
                    showChaptersSheet.toggle()
                } label: {
                    Image(systemName: "list.dash")
                }
                .foregroundStyle(.secondary)
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 45)
            .padding(.horizontal, 15)
            .padding(.top, 20)
            .padding(.bottom, 45)
        }
    }
}

// MARK: Airplay view

extension NowPlayingSheet {
    struct AirPlayView: UIViewRepresentable {
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
