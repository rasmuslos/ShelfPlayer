//
//  SeriesMenu.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal struct SeriesMenu: View {
    let series: [Audiobook.SeriesFragment]
    let libraryID: String?
    
    @ViewBuilder
    private static func label(series: Audiobook.SeriesFragment?) -> some View {
        Label("series.view", systemImage: "rectangle.grid.2x2")
        
        if let series {
            Text(series.name)
        }
    }
    @ViewBuilder
    private static func button(series: Audiobook.SeriesFragment, libraryID: String?, @ViewBuilder buildLabel: (_ series: Audiobook.SeriesFragment) -> some View) -> some View {
        if let libraryID {
            Button {
                if let seriesID = series.id {
                    // Navigation.navigate(seriesID: seriesID, libraryID: libraryID)
                } else {
                    // Navigation.navigate(seriesName: series.name, libraryID: libraryID)
                }
            } label: {
                buildLabel(series)
            }
        } else {
            NavigationLink(destination: SeriesLoadView(series: series)) {
                buildLabel(series)
            }
        }
    }
    
    var body: some View {
        if series.count == 1, let series = series.first {
            Self.button(series: series, libraryID: libraryID, buildLabel: Self.label)
        } else if !series.isEmpty {
            Menu {
                SeriesMenuInner(series: series, libraryID: libraryID)
            } label: {
                Self.label(series: nil)
            }
        }
    }
    
    internal struct SeriesMenuInner: View {
        let series: [Audiobook.SeriesFragment]
        let libraryID: String?
        
        var body: some View {
            ForEach(series, id: \.self) { series in
                SeriesMenu.button(series: series, libraryID: libraryID) {
                    Text($0.name)
                }
            }
        }
    }
}
