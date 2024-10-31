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
    let series: [Audiobook.ReducedSeries]
    let libraryID: String
    let flat: Bool
    
    private var presentMenu: Bool {
        !flat && series.count > 1
    }
    var body: some View {
        if !series.isEmpty {
            if presentMenu {
                Menu {
                    ForEach(series, id: \.name) { series in
                        Button {
                            Navigation.navigate(seriesName: series.name, seriesID: series.id, libraryID: libraryID)
                        } label: {
                            Text(series.name)
                        }
                    }
                } label: {
                    Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                }
            } else {
                ForEach(self.series, id: \.name) { series in
                    Button {
                        Navigation.navigate(seriesName: series.name, seriesID: series.id, libraryID: libraryID)
                    } label: {
                        Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                        Text(series.name)
                    }
                }
            }
        }
    }
}
