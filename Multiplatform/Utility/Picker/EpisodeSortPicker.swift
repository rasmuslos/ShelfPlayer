//
//  EpisodeSortPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.02.25.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeSortPicker: View {
    @Binding var sortOrder: EpisodeSortOrder
    @Binding var ascending: Bool
    
    private func binding(for sortOrder: EpisodeSortOrder) -> Binding<Bool> {
        .init() { self.sortOrder == sortOrder } set: {
            if $0 {
                self.sortOrder = sortOrder
            } else {
                ascending.toggle()
            }
        }
    }
    private func icon(for sortOrder: EpisodeSortOrder) -> String {
        if self.sortOrder == sortOrder {
            ascending ? "chevron.down.2" : "chevron.up.2"
        } else {
            sortOrder.icon
        }
    }
    
    var body: some View {
        ForEach(EpisodeSortOrder.allCases) {
            Toggle($0.label, systemImage: icon(for: $0), isOn: binding(for: $0))
                .tag($0)
        }
    }
}

extension EpisodeSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .name:
            "sort.name"
        case .index:
            "sort.index"
        case .released:
            "sort.released"
        case .duration:
            "sort.duration"
        }
    }
    
    var icon: String {
        switch self {
        case .name:
            "text.quote"
        case .index:
            "list.number"
        case .released:
            "calendar"
        case .duration:
            "clock"
        }
    }
}

#Preview {
    EpisodeSortPicker(sortOrder: .constant(.index), ascending: .constant(true))
}

#Preview {
    Menu(String("Options")) {
        EpisodeSortPicker(sortOrder: .constant(.index), ascending: .constant(false))
    }
}
