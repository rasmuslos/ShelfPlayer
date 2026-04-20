//
//  ItemShareButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.06.25.
//

import SwiftUI
import ShelfPlayback

struct ItemShareButton: View {
    let item: Item

    var body: some View {
        ShareLink(item: item, subject: Text(verbatim: item.name), message: Text(verbatim: item.transferableDescription), preview: SharePreview(item.name, image: item))
    }
}
