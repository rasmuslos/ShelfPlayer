//
//  AuthorsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPFoundation

struct AuthorGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let authors: [Author]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 80.0 : 120.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
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
                    ForEach(authors) { author in
                        NavigationLink(destination: AuthorView(author)) {
                            AuthorGridItem(author: author)
                                .frame(width: size)
                                .padding(.leading, gap)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

extension AuthorGrid {
    struct AuthorGridItem: View {
        let author: Author
        
        var body: some View {
            VStack(spacing: 0) {
                ItemImage(cover: author.cover, cornerRadius: 10000)
                    .padding(.bottom, 5)
                    .hoverEffect(.highlight)
                
                Text(author.name)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AuthorGrid(authors: [
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
            Author.fixture,
        ])
    }
}
#endif
