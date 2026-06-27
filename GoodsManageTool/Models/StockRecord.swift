import Foundation
import SwiftData

@Model
final class StockRecord {
    var changeTypeRaw: String
    var quantity: Int
    var note: String
    var changedAt: Date
    var product: Product?

    init(changeType: StockChangeType, quantity: Int, note: String = "", product: Product) {
        self.changeTypeRaw = changeType.rawValue
        self.quantity = quantity
        self.note = note
        self.changedAt = Date()
        self.product = product
    }

    var changeType: StockChangeType {
        StockChangeType(rawValue: changeTypeRaw) ?? .stockIn
    }
}
