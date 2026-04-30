//
//  ItemFilterPicker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.01.25.
//

import SwiftUI
import ShelfPlayback

struct ItemFilterPicker: View {
    @Environment(\.library) private var library

    @Binding var filter: ItemFilter
    @Binding var restrictToPersisted: Bool

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
        ForEach([ItemFilter]([.finished, .active, .notFinished])) {
            Toggle($0.label, systemImage: $0.icon, isOn: binding(for: $0))
                .tag($0)
        }

        Toggle("item.filter.downloaded", systemImage: "arrow.down", isOn: $restrictToPersisted)
    }
}

extension ItemFilter {
    var label: LocalizedStringKey {
        switch self {
        case .all:
            "item.filter.all"
        case .active:
            "item.filter.active"
        case .finished:
            "item.filter.finished"
        case .notFinished:
            "item.filter.notFinished"
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

struct PodcastFilterPicker: View {
    @Binding var filter: PodcastFilter

    private func binding(for filter: PodcastFilter) -> Binding<Bool> {
        .init() { self.filter == filter } set: {
            if $0 {
                self.filter = filter
            } else {
                self.filter = .all
            }
        }
    }

    var body: some View {
        ForEach([PodcastFilter]([.unfinished, .finished])) {
            Toggle($0.label, systemImage: $0.icon, isOn: binding(for: $0))
                .tag($0)
        }
    }
}

extension PodcastFilter {
    var label: LocalizedStringKey {
        switch self {
        case .all:
            "item.filter.all"
        case .unfinished:
            "item.filter.unfinished"
        case .finished:
            "item.filter.finished"
        }
    }

    var icon: String {
        switch self {
        case .all:
            "circle"
        case .unfinished:
            "circle.bottomrighthalf.pattern.checkered"
        case .finished:
            "checkmark.circle"
        }
    }
}
