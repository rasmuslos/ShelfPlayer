//
//  SyncArray.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.09.24.
//

public actor SyncDictionary<K: Hashable, V> {
    private var buffer: [K: V]
    
    public init(_ elements: [K: V]) {
        buffer = elements
    }
    
    public func clear() {
        buffer.removeAll()
    }
    
    public func append(_ elements: [K: V]) {
        buffer.merge(elements) { $1 }
    }
    
    public subscript(index: K) -> V? {
        set {
            buffer[index] = newValue
        }
        get {
            buffer[index]
        }
    }
    
    // Sadly this is the only way
    public func set(_ key: K, value: V) {
        buffer[key] = value
    }
 
    public var disctory: [K: V] {
        buffer
    }
    public var count: Int {
        buffer.count
    }
}
