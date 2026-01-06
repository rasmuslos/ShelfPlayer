//
//  SeriesList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayback

struct SeriesList: View {
    let series: [Series]
    let onAppear: ((_: Series) -> Void)
    
    var body: some View {
        ForEach(series) { item in
            NavigationLink(value: NavigationDestination.item(item)) {
                ListItem(series: item)
            }
            .buttonStyle(.plain)
            .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
            .onAppear {
                onAppear(item)
            }
        }
    }
}

extension SeriesList {
    struct ListItem: View {
        let name: String?
        let audiobookIDs: [ItemIdentifier]
        
        init(series: Series) {
            self.name = series.name
            self.audiobookIDs = series.audiobooks.map(\.id)
        }
        
        init(name: String?, audiobookIDs: [ItemIdentifier]) {
            self.name = name
            self.audiobookIDs = audiobookIDs
        }
        
        private var coverCount: Int {
            min(audiobookIDs.count, 4)
        }
        
        var body: some View {
            HStack(spacing: 0) {
                ZStack {
                    ForEach(0..<coverCount, id: \.hashValue) {
                        let index = $0
                        let factor: CGFloat = index == 0 ? 1 : index == 1 ? 0.9 : index == 2 ? 0.8 : index == 3 ? 0.7 : 0
                        let offset: CGFloat = index == 0 ? 0 : index == 1 ? 10  : index == 2 ? 20  : index == 3 ? 30  : 0
                        let radius: CGFloat = index == 0 ? 8 : index == 1 ? 7   : index == 2 ? 6   : index == 3 ? 5   : 0
                        
                        ItemImage(itemID: audiobookIDs[$0], size: .tiny, cornerRadius: radius)
                            .frame(height: 60)
                            .scaleEffect(factor)
                            .offset(x: offset)
                            .zIndex(1 / Double(index))
                    }
                }
                .frame(width: 80, height: 60, alignment: .leading)
                .hoverEffect(.highlight)
                .padding(.trailing, 12)
                
                VStack(alignment: .leading) {
                    if let name {
                        Text(name)
                            .lineLimit(2)
                            .bold()
                            .font(.callout)
                    }
                    
                    Text("item.count.audiobooks \(audiobookIDs.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(.rect)
        }
    }
}
    
#if DEBUG
#Preview {
    NavigationStack {
        List {
            SeriesList(series: .init(repeating: .fixture, count: 7)) { _ in }
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
