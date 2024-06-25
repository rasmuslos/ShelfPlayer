//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation

internal extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
