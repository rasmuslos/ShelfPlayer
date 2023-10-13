//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI

struct AudiobooksSort: View {
    @Binding var display: DisplayType {
        didSet {
            UserDefaults.standard.set(display.rawValue, forKey: "audiobooks.display")
        }
    }
    @Binding var sort: SortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            Button {
                display = .list
            } label: {
                Label("List", systemImage: "list.bullet")
            }
            Button {
                display = .grid
            } label: {
                Label("Grid", systemImage: "square.grid.2x2")
            }
            
            Divider()
            
            ForEach(SortOrder.allCases, id: \.hashValue) { order in
                Button {
                    sort = order
                    UserDefaults.standard.set(sort.rawValue, forKey: "audiobooks.sort")
                } label: {
                    if sort == order {
                        Label(order.rawValue, systemImage: "checkmark")
                    } else {
                        Text(order.rawValue)
                    }
                }
            }
            
            Divider()
            Button {
                ascending.toggle()
                UserDefaults.standard.set(ascending, forKey: "audiobooks.sort.ascending")
            } label: {
                if ascending {
                    Label("Ascending", systemImage: "checkmark")
                } else {
                    Text("Ascending")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
        }
    }
}

// MARK: Types

extension AudiobooksSort {
    enum DisplayType: String {
        case grid = "grid"
        case list = "list"
    }
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case author = "Author"
        case released = "Released"
        case added = "Added"
        case duration = "Duration"
    }
}

// MARK: Persistence

extension AudiobooksSort {
    static func getDisplayType() -> DisplayType {
        if let stored = UserDefaults.standard.string(forKey: "audiobooks.display"), let parsed = DisplayType(rawValue: stored) {
            return parsed
        }
        return .grid
    }
    static func getSortOrder() -> SortOrder {
        if let stored = UserDefaults.standard.string(forKey: "audiobooks.sort"), let parsed = SortOrder(rawValue: stored) {
            return parsed
        }
        return .name
    }
    static func getAscending() -> Bool {
        UserDefaults.standard.bool(forKey: "audiobooks.sort.ascending")
    }
}

// MARK: Sort

extension AudiobooksSort {
    static func sort(audiobooks: [Audiobook], order: SortOrder, ascending: Bool) -> [Audiobook] {
        let sorted = audiobooks.sorted {
            switch order {
            case .name:
                return $0.sortName < $1.sortName
            case .author:
                if $0.author == nil {
                    return false
                }
                if $1.author == nil {
                    return true
                }
                
                return $0.author! < $1.author!
            case .released:
                if $0.released == nil {
                    return false
                }
                if $1.released == nil {
                    return true
                }
                
                return $0.released! < $1.released!
            case .added:
                return $0.addedAt < $1.addedAt
            case .duration:
                return $0.duration < $1.duration
            }
        }
        
        if ascending {
            return sorted
        } else {
            return sorted.reversed()
        }
    }
}

#Preview {
    AudiobooksSort(display: .constant(.grid), sort: .constant(.name), ascending: .constant(false))
}
