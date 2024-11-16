import Foundation

extension String: @retroactive Identifiable {
    public var id: Int {
        hashValue
    }
}
