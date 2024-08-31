//
//  Regular+Buttons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPFoundation
import SPPlayback

extension NowPlaying.RegularView {
    struct Buttons: View {
        @Binding var notableMomentsToggled: Bool
        
        @State private var notableMomentSheetPresented = false
        
        var body: some View {
            HStack {
                Spacer()
                
                PlaybackSpeedButton()
                    .font(.system(size: 21))
                    .foregroundStyle(.secondary)
                    .modifier(ButtonHoverEffectModifier())
                
                Text("sleep") // SleepTimerButton()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .modifier(ButtonHoverEffectModifier())
                    .padding(.leading, 20)
                
                if AudioPlayer.shared.item?.type == .audiobook {
                    Button {
                        notableMomentsToggled.toggle()
                    } label: {
                        Label("notableMoments", systemImage: "bookmark.square")
                            .labelStyle(.iconOnly)
                            .symbolVariant(notableMomentsToggled ? .fill : .none)
                    }
                    .font(.system(size: 23))
                    .foregroundStyle(.secondary)
                    .modifier(ButtonHoverEffectModifier())
                    .padding(.leading, 20)
                }
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 45)
        }
    }
}
