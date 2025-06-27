//
//  AuthorsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import ShelfPlayback

struct PersonGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let people: [Person]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 12
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimumSize = horizontalSizeClass == .compact ? 72.0 : 100.0
        
        let usable = width - padding * 2
        let paddedSize = minimumSize + gap
        
        let amount = CGFloat(Int(usable / paddedSize))
        let available = usable - gap * (amount - 1)
        
        return max(minimumSize, available / amount)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(people) { person in
                        NavigationLink(destination: PersonView(person)) {
                            VStack(spacing: 0) {
                                ItemImage(item: person, size: .small, cornerRadius: .infinity)
                                    .padding(.bottom, 4)
                                
                                Text(person.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(width: size)
                            .padding(.leading, gap)
                            .contentShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: person))
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, 20 - gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PersonGrid(people: .init(repeating: .authorFixture, count: 7))
    }
}
#endif
