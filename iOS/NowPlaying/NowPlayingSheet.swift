//
//  NowPlayingSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

struct NowPlayingSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var showChaptersSheet = false
    
    var body: some View {
        VStack {
            Spacer()
                .overlay(alignment: .top) {
                    Rectangle()
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 7)
                        .clipShape(RoundedRectangle(cornerRadius: 10000))
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            
            ItemImage(image: AudioPlayer.shared.item?.image)
                .scaleEffect(AudioPlayer.shared.playing ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.shared.playing)
                .shadow(radius: 15)
            
            Spacer()
            
            Title()
            Controls()
            BottomButtons(showChaptersSheet: $showChaptersSheet)
        }
        .padding(.horizontal, 30)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showChaptersSheet, content: {
            ChapterSheet()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large, .medium])
        })
        .gesture(
            DragGesture(minimumDistance: 150).onEnded { value in
                if value.location.y - value.startLocation.y > 150 {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        )
    }
}
