//
//  AudiobookshelfClientError.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

enum AudiobookshelfClientError: Error {
    case invalidServerUrl
    case invalidHttpBody
    case invalidResponse
}
