//
//  CarPlayItemController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.04.25.
//
import Foundation
@preconcurrency import CarPlay

protocol CarPlayItemController: AnyObject {
    var row: CPListItem { get }
}
