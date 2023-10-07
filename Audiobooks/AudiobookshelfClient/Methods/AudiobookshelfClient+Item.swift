//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation

extension AudiobookshelfClient {
    func setFinished(itemId: String, additionalId: String?, finished: Bool) async throws {
        let additional = additionalId != nil ? "/\(additionalId!)" : ""
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(additional)", method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
}
