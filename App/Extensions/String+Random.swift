//
//  String+Random.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.02.24.
//

import Foundation

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
