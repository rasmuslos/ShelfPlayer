//
//  AudiobookGenreFilter.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.02.24.
//

import SwiftUI

struct AudiobookGenreFilter: ViewModifier {
    let genres: [String]
    @Binding var selected: [String]
    
    @State var genreFilterSheetVisible = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        genreFilterSheetVisible.toggle()
                    } label: {
                        Label("filter.genres", systemImage: "rectangle.stack.fill")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $genreFilterSheetVisible) {
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
                                        Image(systemName: "checkmark")
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
