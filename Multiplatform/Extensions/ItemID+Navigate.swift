//
//  ItemID+Navigate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation
import ShelfPlayerKit

extension ItemIdentifier {
    func navigate() {
        RFNotification[.navigateNotification].send(self)
    }
}
