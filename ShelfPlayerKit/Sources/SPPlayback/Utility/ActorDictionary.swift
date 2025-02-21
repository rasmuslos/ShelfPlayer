//
//  ActorDictionary.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation

actor ActorDictionary<V: Hashable,T> {
    private var dictionary: [V: T]
    
    init(dict: [V: T] = [V:T]()) {
        self.dictionary = dict
    }

    var keys: Dictionary<V, T>.Keys {
        dictionary.keys
    }

    var values: Dictionary<V, T>.Values {
        dictionary.values
    }

    var startIndex: Dictionary<V, T>.Index {
        dictionary.startIndex
    }

    var endIndex: Dictionary<V, T>.Index {
        dictionary.endIndex
    }
    
    func index(after i: Dictionary<V, T>.Index) -> Dictionary<V, T>.Index {
        dictionary.index(after: i)
    }

    subscript(key: V) -> T? {
        set {
            dictionary[key] = newValue
        }
        get {
            self.dictionary[key]
        }
    }

    subscript(index: Dictionary<V, T>.Index) -> Dictionary<V, T>.Element {
        dictionary[index]
    }
    
    func removeValue(forKey key: V) {
        dictionary.removeValue(forKey: key)
    }

    func removeAll() {
        dictionary.removeAll()
    }

}
