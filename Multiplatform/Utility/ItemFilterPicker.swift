//
//  ItemFilterPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemFilterPicker: View {
    @Binding var filter: ItemFilter
    
    func binding(for filter: ItemFilter) -> Binding<Bool> {
        .init() { self.filter == filter } set: {
            if $0 {
                self.filter = filter
            } else {
                self.filter = .all
            }
        }
    }
    
    var body: some View {
        ForEach([ItemFilter]([.finished, .active])) { filter in
            Toggle(filter.label, systemImage: filter.icon, isOn: binding(for: filter))
                .tag(filter)
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
