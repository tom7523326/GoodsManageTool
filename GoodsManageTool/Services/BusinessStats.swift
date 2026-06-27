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
    static func soldQuantity(for product: Product, on date: Date? = nil) -> Int {
        filteredRecords(product.saleRecords, on: date).reduce(0) { $0 + $1.quantity }
    }

    static func revenue(for product: Product, on date: Date? = nil) -> Double {
        filteredRecords(product.saleRecords, on: date).reduce(0) { $0 + $1.totalPrice }
    }

    static func soldCost(for product: Product, on date: Date? = nil) -> Double {
        filteredRecords(product.saleRecords, on: date).reduce(0) { total, record in
            total + Double(record.quantity) * record.effectiveCostPrice
        }
    }

    static func profit(for product: Product, on date: Date? = nil) -> Double {
        revenue(for: product, on: date) - soldCost(for: product, on: date)
    }

    static func inventoryCostValue(for product: Product) -> Double {
        Double(product.stockQuantity) * product.costPrice
    }

    static func inventoryRetailValue(for product: Product) -> Double {
        Double(product.stockQuantity) * product.sellPrice
    }

    static func productStats(from products: [Product], on date: Date? = nil) -> [ProductStats] {
        products.map { product in
            ProductStats(
                product: product,
                soldQuantity: soldQuantity(for: product, on: date),
                revenue: revenue(for: product, on: date),
                cost: soldCost(for: product, on: date),
                profit: profit(for: product, on: date),
                inventoryValue: inventoryCostValue(for: product)
            )
        }
    }

    static func todayProductStats(from products: [Product]) -> [ProductStats] {
        productStats(from: products, on: Date())
    }

    static func totalRevenue(records: [SaleRecord], on date: Date? = nil) -> Double {
        filteredRecords(records, on: date).reduce(0) { $0 + $1.totalPrice }
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
        record.totalPrice - Double(record.quantity) * record.effectiveCostPrice
    }

    private static func filteredRecords(_ records: [SaleRecord], on date: Date?) -> [SaleRecord] {
        guard let date else { return records }
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.soldAt, inSameDayAs: date) }
    }
}
