//
//  Episode+Fixture.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation

extension Episode {
    static let fixture = Episode(
        id: "fixture",
        additionalId: "fixture",
        libraryId: "fixture",
        name: "A podcast episode",
        author: "Tagesschau",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Sed vulputate odio ut enim. Cras semper auctor neque vitae. Tortor vitae purus faucibus ornare suspendisse. Sed vulputate mi sit amet mauris. Morbi leo urna molestie at elementum eu facilisis. Condimentum vitae sapien pellentesque habitant morbi tristique senectus. Viverra ipsum nunc aliquet bibendum enim. Aliquet nec ullamcorper sit amet risus nullam eget felis eget. Feugiat nibh sed pulvinar proin. Mauris rhoncus aenean vel elit. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Integer enim neque volutpat ac tincidunt vitae semper. Vitae tortor condimentum lacinia quis vel eros donec ac. Ornare aenean euismod elementum nisi quis eleifend quam adipiscing vitae. Interdum posuere lorem ipsum dolor sit amet consectetur. Mattis molestie a iaculis at erat pellentesque. Sed faucibus turpis in eu. Elit eget gravida cum sociis natoque penatibus et. Nisi quis eleifend quam adipiscing vitae proin.",
        image: Item.Image.init(url: URL(string: "https://yt3.ggpht.com/a/AATXAJzzBYy7X230jcXQOXOOsHRLsEjwMluIvn1IVg%3ds900-c-k-c0xffffffff-no-rj-mo")!),
        genres: [],
        addedAt: Date(),
        released: "Fri, 22 Sep 2023 15:00:00 +0200",
        size: 0)
}
