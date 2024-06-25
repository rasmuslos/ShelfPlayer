//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.03.24.
//

import Foundation

public extension Audiobook.ReducedSeries {
    static func convert(seriesName: String) -> [Self] {
        let series = seriesName.split(separator: ", ")
        
        return series.map {
            if $0.contains(" #") {
                let parts = $0.split(separator: " #")
                let name = parts[0...parts.count - 2].joined(separator: " #")
                
                if let sequence = Float(parts[parts.count - 1]) {
                    return Audiobook.ReducedSeries(id: nil, name: name, sequence: sequence)
                } else {
                    return Audiobook.ReducedSeries(id: nil, name: name.appending(" #").appending(parts[parts.count - 1]), sequence: nil)
                }
            } else {
                return Audiobook.ReducedSeries(id: nil, name: String($0), sequence: nil)
            }
        }
    }
}
