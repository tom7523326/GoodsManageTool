import Foundation

enum PriceFormatter {
    static func string(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }
}

extension Product {
    var stockStatusText: String {
        if isOutOfStock {
            return "缺货"
        }
        if isLowStock {
            return "库存紧张"
        }
        return "库存 \(stockQuantity)"
    }

    var stockStatusColorName: String {
        if isOutOfStock {
            return "red"
        }
        if isLowStock {
            return "orange"
        }
        return "green"
    }
}
