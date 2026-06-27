import Foundation
import SwiftData

struct ProductStats: Identifiable {
    let product: Product
    let soldQuantity: Int
    let revenue: Double
    let cost: Double
    let profit: Double
    let inventoryValue: Double

    var id: PersistentIdentifier { product.persistentModelID }
}

enum BusinessStats {
    static func soldQuantity(for product: Product) -> Int {
        product.saleRecords.reduce(0) { $0 + $1.quantity }
    }

    static func revenue(for product: Product) -> Double {
        product.saleRecords.reduce(0) { $0 + $1.totalPrice }
    }

    static func soldCost(for product: Product) -> Double {
        product.saleRecords.reduce(0) { $0 + Double($1.quantity) * product.costPrice }
    }

    static func profit(for product: Product) -> Double {
        revenue(for: product) - soldCost(for: product)
    }

    static func inventoryCostValue(for product: Product) -> Double {
        Double(product.stockQuantity) * product.costPrice
    }

    static func inventoryRetailValue(for product: Product) -> Double {
        Double(product.stockQuantity) * product.sellPrice
    }

    static func productStats(from products: [Product]) -> [ProductStats] {
        products.map { product in
            ProductStats(
                product: product,
                soldQuantity: soldQuantity(for: product),
                revenue: revenue(for: product),
                cost: soldCost(for: product),
                profit: profit(for: product),
                inventoryValue: inventoryCostValue(for: product)
            )
        }
    }

    static func totalRevenue(records: [SaleRecord]) -> Double {
        records.reduce(0) { $0 + $1.totalPrice }
    }

    static func totalProfit(products: [Product]) -> Double {
        products.reduce(0) { $0 + profit(for: $1) }
    }

    static func totalInventoryCost(products: [Product]) -> Double {
        products.reduce(0) { $0 + inventoryCostValue(for: $1) }
    }

    static func totalInventoryRetail(products: [Product]) -> Double {
        products.reduce(0) { $0 + inventoryRetailValue(for: $1) }
    }

    static func profit(for record: SaleRecord) -> Double {
        guard let product = record.product else { return record.totalPrice }
        return record.totalPrice - Double(record.quantity) * product.costPrice
    }
}
