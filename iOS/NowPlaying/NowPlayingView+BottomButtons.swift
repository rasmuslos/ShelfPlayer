//
//  NowPlayingSheet+BottomButtons.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import AVKit

extension NowPlayingViewModifier {
    struct Buttons: View {
        @State private var notableMomentSheetPresented = false
        
        var body: some View {
            HStack {
                PlaybackSpeedButton()
                    .frame(width: 60)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                SleepTimerButton()
                    .frame(width: 60)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                AirPlayView()
                    .frame(width: 60)
                
                Spacer()
                
                Menu {
                    ChapterSelectMenu()
                } label: {
                    Image(systemName: "list.dash")
                } primaryAction: {
                    notableMomentSheetPresented.toggle()
                }
                .frame(width: 60)
                .foregroundStyle(.secondary)
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 45)
            .padding(.horizontal, 10)
            .padding(.top, 20)
            .padding(.bottom, 45)
            .sheet(isPresented: $notableMomentSheetPresented, content: {
                NotableMomentsSheet()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large, .medium])
            })
        }
    }
}

// MARK: Airplay view

extension NowPlayingViewModifier.Buttons {
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
