//
//  String+Random.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation

extension String {
    private static let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    init(length: Int) {
        self.init((0..<length).map { _ in
            Self.letters.randomElement()!
        })
    }
}
