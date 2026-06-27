import Foundation
import SwiftData

enum SampleDataService {
    private static let bannerDismissedKey = "sampleBannerDismissed"

    static var isBannerDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: bannerDismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: bannerDismissedKey) }
    }

    static func hasSampleProducts(in products: [Product]) -> Bool {
        products.contains(where: \.isSample)
    }

    static func clearSampleProducts(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Product>()
        let products = try context.fetch(descriptor)
        products.filter(\.isSample).forEach { context.delete($0) }
        try context.save()
        isBannerDismissed = false
    }

    static func product(matchingBarcode barcode: String, in products: [Product]) -> Product? {
        let normalized = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return products.first {
            guard let value = $0.barcode?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return false
            }
            return value.caseInsensitiveCompare(normalized) == .orderedSame
        }
    }

    static func isBarcodeTaken(
        _ barcode: String,
        excluding product: Product? = nil,
        in products: [Product]
    ) -> Bool {
        let normalized = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }

        return products.contains { candidate in
            if let product, candidate.persistentModelID == product.persistentModelID {
                return false
            }
            guard let value = candidate.barcode?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return false
            }
            return value.caseInsensitiveCompare(normalized) == .orderedSame
        }
    }
}
