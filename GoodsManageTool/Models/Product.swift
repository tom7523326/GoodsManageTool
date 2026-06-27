import Foundation
import SwiftData

@Model
final class Product {
    var title: String
    var spec: String
    var costPrice: Double
    var sellPrice: Double
    var stockQuantity: Int
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \SaleRecord.product)
    var saleRecords: [SaleRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \StockRecord.product)
    var stockRecords: [StockRecord] = []

    init(
        title: String,
        spec: String,
        costPrice: Double,
        sellPrice: Double,
        stockQuantity: Int,
        imageData: Data? = nil,
        sortOrder: Int = 0
    ) {
        self.title = title
        self.spec = spec
        self.costPrice = costPrice
        self.sellPrice = sellPrice
        self.stockQuantity = stockQuantity
        self.imageData = imageData
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var isLowStock: Bool {
        stockQuantity <= 3
    }

    var isOutOfStock: Bool {
        stockQuantity <= 0
    }
}
