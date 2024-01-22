//
//  String+Padding.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension String {
    func leftPadding(toLength: Int, withPad: String) -> String {
        String(String(reversed()).padding(toLength: toLength, withPad: withPad, startingAt: 0).reversed())
    }
}
