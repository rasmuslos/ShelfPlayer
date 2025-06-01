//
//  ConvenienceDownloadPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.05.25.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct ConvenienceDownloadPreferences: View {
    @Default(.enableListenNowDownloads) private var enableConvenienceDownloads
    @Default(.enableConvenienceDownloads) private var enableListenNowDownloads
    
    var body: some View {
        List {
            Toggle("preferences.convenienceDownload.enable", isOn: $enableConvenienceDownloads)
            Toggle("preferences.convenienceDownload.enableListenNowDownloads", isOn: $enableListenNowDownloads)
            
            Section("preferences.convenienceDownload.configurations") {
                
            }
        }
        .navigationTitle("preferences.convenienceDownload")
    }
}

#Preview {
    ConvenienceDownloadPreferences()
}
