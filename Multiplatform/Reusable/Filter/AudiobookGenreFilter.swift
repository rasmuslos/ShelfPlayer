//
//  AudiobookGenreFilter.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.02.24.
//

import SwiftUI

struct AudiobookGenreFilterModifier: ViewModifier {
    let genres: [String]
    @Binding var selected: [String]
    
    @State private var filterSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        filterSheetPresented.toggle()
                    } label: {
                        Label("filter.genres", systemImage: "rectangle.stack.fill")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $filterSheetPresented) {
                List {
                    ForEach(genres.sorted(by: <), id: \.hashValue) { genre in
                        let active = selected.contains(where: { $0 == genre })
                        
                        HStack {
                            Button {
                                withAnimation {
                                    if active {
                                        selected.removeAll { $0 == genre }
                                    } else {
                                        selected.append(genre)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(genre)
                                    
                                    Spacer()
                                    
                                    if active {
                                        Label("active", systemImage: "checkmark")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}
