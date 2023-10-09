//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation

extension AudiobookshelfClient {
    func setFinished(itemId: String, episodeId: String?, finished: Bool) async throws {
        let episodeId = episodeId != nil ? "/\(episodeId!)" : ""
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(episodeId)", method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
}
