//
//  ItemDisplayTypePicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemDisplayTypePicker: View {
    @Binding var displayType: ItemDisplayType
    
    var body: some View {
        ControlGroup {
            ForEach(ItemDisplayType.allCases) { displayType in
                Button(displayType.label, systemImage: displayType.icon) {
                    withAnimation {
                        self.displayType = displayType
                    }
                }
                .tag(displayType)
            }
        }
    }
}

extension ItemDisplayType {
    var label: LocalizedStringKey {
        switch self {
        case .grid:
            "item.display.grid"
        case .list:
            "item.display.list"
        }
    }
    
    var icon: String {
        switch self {
        case .grid:
            "square.grid.2x2"
        case .list:
            "list.bullet"
        }
    }
}

#Preview {
    ItemDisplayTypePicker(displayType: .constant(.list))
}

#Preview {
    Menu(String("Options")) {
        ItemDisplayTypePicker(displayType: .constant(.list))
    }
}
