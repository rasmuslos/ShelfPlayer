//
//  AudiobookFilterPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.02.25.
//

import SwiftUI
import SPFoundation

struct AudiobookSortOrderPicker: View {
    @Binding var sortOrder: AudiobookSortOrder
    @Binding var ascending: Bool
    
    private func binding(for sortOrder: AudiobookSortOrder) -> Binding<Bool> {
        .init() { self.sortOrder == sortOrder } set: {
            if $0 {
                self.sortOrder = sortOrder
            } else {
                ascending.toggle()
            }
        }
    }
    private func icon(for sortOrder: AudiobookSortOrder) -> String {
        if self.sortOrder == sortOrder {
            ascending ? "chevron.down.2" : "chevron.up.2"
        } else {
            sortOrder.icon
        }
    }
    
    var body: some View {
        ForEach(AudiobookSortOrder.allCases) {
            Toggle($0.label, systemImage: icon(for: $0), isOn: binding(for: $0))
                .tag($0)
        }
    }
}

extension AudiobookSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .sortName:
            "sort.name"
        case .authorName:
            "sort.author"
        case .released:
            "sort.released"
        case .added:
            "sort.added"
        case .duration:
            "sort.duration"
        case .lastPlayed:
            "sort.lastPlayed"
        }
    }
    
    var icon: String {
        switch self {
        case .sortName:
            "text.quote"
        case .authorName:
            "person"
        case .released:
            "calendar"
        case .added:
            "plus.square"
        case .duration:
            "clock"
        case .lastPlayed:
            "memories"
        }
    }
}

#Preview {
    AudiobookSortOrderPicker(sortOrder: .constant(.sortName), ascending: .constant(true))
}

#Preview {
    Menu(String("Options")) {
        AudiobookSortOrderPicker(sortOrder: .constant(.sortName), ascending: .constant(false))
    }
}
