//
//  AuthorList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayback

struct PersonList: View {
    let people: [Person]
    let showImage: Bool
    let onAppear: ((_: Person) -> Void)
    
    var body: some View {
        ForEach(people) { person in
            NavigationLink(destination: PersonView(person)) {
                HStack(spacing: 8) {
                    if showImage {
                        ItemImage(item: person, size: .tiny, cornerRadius: .infinity)
                            .frame(width: 52)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                        
                        Text("item.count.audiobooks \(person.bookCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
            .modifier(ItemStatusModifier(item: person))
            .onAppear {
                onAppear(person)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            PersonList(people: .init(repeating: .authorFixture, count: 7), showImage: true) { _ in }
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview {
    NavigationStack {
        List {
            PersonList(people: .init(repeating: .authorFixture, count: 7), showImage: false) { _ in }
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
