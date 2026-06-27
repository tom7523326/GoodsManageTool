import Foundation

enum PriceFormatter {
    static func string(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }
}

enum AppDateFormatter {
    private static let chineseLocale = Locale(identifier: "zh_Hans_CN")

    static func orderSectionTitle(for date: Date) -> String {
        date.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .weekday(.wide)
                .locale(chineseLocale)
        )
    }

    static func orderTime(for date: Date) -> String {
        date.formatted(
            .dateTime
                .hour()
                .minute()
                .locale(chineseLocale)
        )
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
