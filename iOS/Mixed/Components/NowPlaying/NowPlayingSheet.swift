//
//  NowPlayingSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase

struct NowPlayingSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    let item: PlayableItem
    @Binding var playing: Bool
    
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
            
            ItemImage(image: item.image)
                .scaleEffect(playing ? 1 : 0.8)
                .animation(.spring(duration: 0.25, bounce: 0.5), value: playing)
                .shadow(radius: 15)
            
            Spacer()
            
            Title(item: item)
            Controls(playing: $playing)
            BottomButtons(showChaptersSheet: $showChaptersSheet)
        }
        .padding(.horizontal, 30)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showChaptersSheet, content: {
            ChapterSheet(item: item)
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

#Preview {
    NowPlayingSheet(item: Audiobook.fixture, playing: .constant(true))
}

#Preview {
    NowPlayingSheet(item: Episode.fixture, playing: .constant(false))
}
