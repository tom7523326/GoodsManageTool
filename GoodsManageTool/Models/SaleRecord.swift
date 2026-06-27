import Foundation
import SwiftData

@Model
final class SaleRecord {
    var saleTypeRaw: String
    var ageGroupRaw: String
    var quantity: Int
    var unitPrice: Double
    var totalPrice: Double
    var soldAt: Date
    var product: Product?

    init(
        saleType: SaleType,
        ageGroup: AgeGroup,
        quantity: Int,
        unitPrice: Double,
        product: Product
    ) {
        self.saleTypeRaw = saleType.rawValue
        self.ageGroupRaw = ageGroup.rawValue
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = Double(quantity) * unitPrice
        self.soldAt = Date()
        self.product = product
    }

    var saleType: SaleType {
        SaleType(rawValue: saleTypeRaw) ?? .original
    }

    var ageGroup: AgeGroup {
        AgeGroup(rawValue: ageGroupRaw) ?? .age10to20
    }
}
