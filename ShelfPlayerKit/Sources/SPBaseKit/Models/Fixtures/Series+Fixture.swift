//
//  Series+Fixture.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import Foundation

extension Series {
    public static let fixture = Series(
        id: "fxitrue",
        libraryId: "fixture",
        name: "The Witcher",
        author: nil,
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Sed vulputate odio ut enim. Cras semper auctor neque vitae. Tortor vitae purus faucibus ornare suspendisse. Sed vulputate mi sit amet mauris. Morbi leo urna molestie at elementum eu facilisis. Condimentum vitae sapien pellentesque habitant morbi tristique senectus. Viverra ipsum nunc aliquet bibendum enim. Aliquet nec ullamcorper sit amet risus nullam eget felis eget. Feugiat nibh sed pulvinar proin. Mauris rhoncus aenean vel elit. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Integer enim neque volutpat ac tincidunt vitae semper. Vitae tortor condimentum lacinia quis vel eros donec ac. Ornare aenean euismod elementum nisi quis eleifend quam adipiscing vitae. Interdum posuere lorem ipsum dolor sit amet consectetur. Mattis molestie a iaculis at erat pellentesque. Sed faucibus turpis in eu. Elit eget gravida cum sociis natoque penatibus et. Nisi quis eleifend quam adipiscing vitae proin.",
        image: nil,
        genres: [],
        addedAt: Date(),
        released: nil,
        images: [
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
            Item.Image(url: URL(string: "https://m.media-amazon.com/images/I/51r+po1oBdL._SL500_.jpg")!),
        ])
}
