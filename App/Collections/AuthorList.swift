//
//  AuthorList.swift
//  ShelfPlayer
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
            NavigationLink(value: NavigationDestination.item(person)) {
                ItemCompactRow(item: person, context: showImage ? .author : .narrator)
            }
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
            .modifier(ItemStatusModifier(item: person, hoverEffect: nil))
            .onAppear {
                onAppear(person)
            }
        }
    }
}
