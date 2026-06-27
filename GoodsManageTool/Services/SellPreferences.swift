import Foundation

enum SellPreferences {
    private static let saleTypeKey = "lastSaleType"
    private static let ageGroupKey = "lastAgeGroup"

    static func loadSaleType() -> SaleType {
        guard
            let raw = UserDefaults.standard.string(forKey: saleTypeKey),
            let value = SaleType(rawValue: raw)
        else { return .original }
        return value
    }

    static func loadAgeGroup() -> AgeGroup {
        guard
            let raw = UserDefaults.standard.string(forKey: ageGroupKey),
            let value = AgeGroup(rawValue: raw)
        else { return .age10to20 }
        return value
    }

    static func save(saleType: SaleType, ageGroup: AgeGroup) {
        UserDefaults.standard.set(saleType.rawValue, forKey: saleTypeKey)
        UserDefaults.standard.set(ageGroup.rawValue, forKey: ageGroupKey)
    }
}
