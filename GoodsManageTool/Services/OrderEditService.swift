import Foundation

enum OrderEditError: LocalizedError {
    case missingProduct
    case insufficientStock(available: Int)
    case invalidQuantity
    case invalidPrice

    var errorDescription: String? {
        switch self {
        case .missingProduct:
            return "关联商品已不存在，无法修改此订单"
        case .insufficientStock(let available):
            return "库存不足，当前最多可售 \(available) 件"
        case .invalidQuantity:
            return "数量必须大于 0"
        case .invalidPrice:
            return "折扣单价必须大于 0"
        }
    }
}

enum OrderEditService {
    static func update(
        record: SaleRecord,
        saleType: SaleType,
        ageGroup: AgeGroup,
        quantity: Int,
        unitPrice: Double,
        soldAt: Date
    ) throws {
        guard quantity > 0 else { throw OrderEditError.invalidQuantity }
        guard saleType != .discount || unitPrice > 0 else { throw OrderEditError.invalidPrice }
        guard let product = record.product else { throw OrderEditError.missingProduct }

        let oldQuantity = record.quantity
        product.stockQuantity += oldQuantity

        guard product.stockQuantity >= quantity else {
            product.stockQuantity -= oldQuantity
            throw OrderEditError.insufficientStock(available: product.stockQuantity)
        }

        product.stockQuantity -= quantity

        // costPriceAtSale is intentionally unchanged — it records cost at original sale time.
        record.saleTypeRaw = saleType.rawValue
        record.ageGroupRaw = ageGroup.rawValue
        record.quantity = quantity
        record.unitPrice = unitPrice
        record.totalPrice = Double(quantity) * unitPrice
        record.soldAt = soldAt
    }

    /// Restores sold quantity to inventory before deleting the order.
    static func restoreStock(for record: SaleRecord) {
        guard let product = record.product else { return }
        product.stockQuantity += record.quantity
    }
}
