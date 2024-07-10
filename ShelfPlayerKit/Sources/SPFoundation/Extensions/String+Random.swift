//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation

internal extension String {
    init(length: Int) {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        self.init((0..<length).map { _ in letters.randomElement()! })
    }
}
