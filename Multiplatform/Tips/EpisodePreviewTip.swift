//
//  EpisodePreviewTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.04.24.
//

import TipKit

internal struct EpisodePreviewTip: Tip {
    var title: Text {
        .init("tip.episodePreview")
    }
    var message: Text? {
        .init("tip.episodePreview.message")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(5),
    ]}
}
