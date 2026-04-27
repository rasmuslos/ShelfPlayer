//
//  CombineEventSources.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Combine
import Foundation

public enum GlobalSearchScope: Int, Identifiable, Hashable, CaseIterable, Sendable {
    case library
    case global

    public var id: Int {
        rawValue
    }
}

public final class AppEventSource: @unchecked Sendable {
    public let scenePhaseDidChange = PassthroughSubject<Bool, Never>()
    public let shake = PassthroughSubject<TimeInterval, Never>()
    public let reloadImages = PassthroughSubject<ItemIdentifier?, Never>()
    public let appearanceDidChange = PassthroughSubject<Void, Never>()

    public static let shared = AppEventSource()

    private init() {}
}

public final class NavigationEventSource: @unchecked Sendable {
    public let navigate = PassthroughSubject<ItemIdentifier, Never>()
    public let deferredNavigate = PassthroughSubject<ItemIdentifier, Never>()
    public let setGlobalSearch = PassthroughSubject<(String, GlobalSearchScope), Never>()

    public static let shared = NavigationEventSource()

    private init() {}
}

public final class PlaybackLifecycleEventSource: @unchecked Sendable {
    public let finalizeReporting = PassthroughSubject<Void, Never>()
    public let invalidateTransientPanels = PassthroughSubject<Void, Never>()

    public static let shared = PlaybackLifecycleEventSource()

    private init() {}
}

public final class ListeningStatsEventSource: @unchecked Sendable {
    public let timeSpendListeningChanged = PassthroughSubject<Int, Never>()

    public static let shared = ListeningStatsEventSource()

    private init() {}
}

public final class CollectionEventSource: @unchecked Sendable {
    public let changed = PassthroughSubject<ItemIdentifier, Never>()
    public let deleted = PassthroughSubject<ItemIdentifier, Never>()

    public static let shared = CollectionEventSource()

    private init() {}
}

public final class ItemEventSource: @unchecked Sendable {
    public typealias Payload = (connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?)

    public let updated = PassthroughSubject<Payload, Never>()
    public let deleted = PassthroughSubject<Payload, Never>()

    public static let shared = ItemEventSource()

    private init() {}
}

public final class TabEventSource: @unchecked Sendable {
    public let invalidateTabs = PassthroughSubject<Void, Never>()
    public let enablePinnedTabs = PassthroughSubject<Void, Never>()

    public static let shared = TabEventSource()

    private init() {}
}
