//
//  ItemFilterPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemFilterPicker: View {
    @Environment(\.library) private var library
    
    @Binding var filter: ItemFilter
    
    private var options: [ItemFilter] {
        if library?.type == .podcasts {
            [.finished, .active, .notFinished]
        } else {
            [.finished, .active]
        }
    }
    
    private func binding(for filter: ItemFilter) -> Binding<Bool> {
        .init() { self.filter == filter } set: {
            if $0 {
                self.filter = filter
            } else {
                self.filter = .all
            }
        }
    }
    
    var body: some View {
        ForEach(options) {
            Toggle($0.label, systemImage: $0.icon, isOn: binding(for: $0))
                .tag($0)
        }
    }
}

extension ItemFilter {
    var label: LocalizedStringKey {
        switch self {
        case .all:
            "filter.all"
        case .active:
            "filter.active"
        case .finished:
            "filter.finished"
        case .notFinished:
            "filter.notFinished"
        }
    }
    
    var icon: String {
        switch self {
        case .active:
            "circle.bottomrighthalf.pattern.checkered"
        case .finished:
            "checkmark.circle"
        default:
            "circle"
        }
    }
}


#Preview {
    @Previewable @State var filter: ItemFilter = .all
    
    ItemFilterPicker(filter: $filter)
        .environment(\.library, .init(id: "fixture", connectionID: "fixture", name: "Fixture", type: .podcasts, index: -1))
}

#Preview {
    @Previewable @State var filter: ItemFilter = .all
    
    Menu(String("Filter")) {
        ItemFilterPicker(filter: $filter)
    }
}

#Preview {
    @Previewable @State var filter: ItemFilter = .all
    
    Picker(String("Filter"), selection: $filter) {
        ItemFilterPicker(filter: $filter)
    }
}
