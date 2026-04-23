//
//  ExportBookmarksIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents
import UniformTypeIdentifiers

public struct ExportBookmarksIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.exportBookmarks.title"
    public static let description = IntentDescription("intent.exportBookmarks.description")

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.exportBookmarks.summary")
    }

    public func perform() async throws -> some ReturnsValue<IntentFile> {
        let entries = try await PersistenceManager.shared.bookmark.all

        var rows: [String] = ["Title,Authors,Item ID,Time (s),Note,Created"]

        for entry in entries {
            let resolved = try? await ResolveCache.shared.resolve(primaryID: entry.primaryID, groupingID: nil, connectionID: entry.connectionID)

            let title = resolved?.name ?? ""
            let authors = resolved?.authors.joined(separator: "; ") ?? ""
            let itemID = "\(entry.connectionID)::\(entry.primaryID)"
            let created = ISO8601DateFormatter().string(from: entry.created)

            rows.append([title, authors, itemID, "\(entry.time)", entry.note, created].map(csvEscape).joined(separator: ","))
        }

        let csv = rows.joined(separator: "\n") + "\n"
        let data = Data(csv.utf8)

        return .result(value: IntentFile(data: data, filename: "bookmarks.csv", type: .commaSeparatedText))
    }
}

private func csvEscape(_ field: String) -> String {
    if field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) {
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return field
}
