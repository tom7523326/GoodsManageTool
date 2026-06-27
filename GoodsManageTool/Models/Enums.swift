import Foundation

enum SaleType: String, Codable, CaseIterable, Identifiable {
    case original = "原价卖出"
    case discount = "折扣卖出"
    case gift = "赠送"

    var id: String { rawValue }
}

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case age0to5 = "0-5"
    case age5to10 = "5-10"
    case age10to20 = "10-20"
    case age20to50 = "20-50"
    case age50plus = "50+"

    var id: String { rawValue }
}

enum StockChangeType: String, Codable, CaseIterable, Identifiable {
    case stockIn = "进货"
    case stockOut = "出货"

    var id: String { rawValue }
}
