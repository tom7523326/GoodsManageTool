import Foundation
import SwiftData

enum SeedData {
    private static let seededKey = "hasSeededInitialProducts"
    private static let imagesAttachedKey = "hasAttachedProductImages_v3"
    private static let sampleFlagsBackfilledKey = "hasBackfilledSampleFlags"
    private static let costPriceBackfilledKey = "hasBackfilledCostPriceAtSale"

    static let sampleProductTitles: Set<String> = Set(initialProducts.map(\.title))

    static func prepareOnLaunch(context: ModelContext) {
        backfillSampleFlagsIfNeeded(context: context)
        backfillCostPriceAtSaleIfNeeded(context: context)
        attachProductImagesIfNeeded(context: context)
    }

    static func seedSampleProducts(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Product>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return false }

        initialProducts.enumerated().forEach { index, item in
            context.insert(
                Product(
                    title: item.title,
                    spec: item.spec,
                    costPrice: item.costPrice,
                    sellPrice: item.sellPrice,
                    stockQuantity: item.stockQuantity,
                    imageData: loadImageData(named: item.imageName),
                    sortOrder: index,
                    isSample: true,
                    barcode: item.barcode
                )
            )
        }

        guard (try? context.save()) != nil else { return false }
        UserDefaults.standard.set(true, forKey: seededKey)
        UserDefaults.standard.set(true, forKey: imagesAttachedKey)
        return true
    }

    private static func backfillCostPriceAtSaleIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: costPriceBackfilledKey) else { return }

        let descriptor = FetchDescriptor<SaleRecord>()
        guard let records = try? context.fetch(descriptor) else { return }

        var didUpdate = false
        for record in records {
            guard record.costPriceAtSale <= 0, let product = record.product else { continue }
            record.costPriceAtSale = product.costPrice
            didUpdate = true
        }

        guard didUpdate else {
            UserDefaults.standard.set(true, forKey: costPriceBackfilledKey)
            return
        }

        guard (try? context.save()) != nil else { return }
        UserDefaults.standard.set(true, forKey: costPriceBackfilledKey)
    }

    private static func backfillSampleFlagsIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: sampleFlagsBackfilledKey) else { return }

        let descriptor = FetchDescriptor<Product>()
        guard let products = try? context.fetch(descriptor) else { return }

        var didUpdate = false
        for product in products where sampleProductTitles.contains(product.title) {
            product.isSample = true
            didUpdate = true
        }

        guard didUpdate else {
            UserDefaults.standard.set(true, forKey: sampleFlagsBackfilledKey)
            return
        }

        guard (try? context.save()) != nil else { return }
        UserDefaults.standard.set(true, forKey: sampleFlagsBackfilledKey)
    }

    private static func attachProductImagesIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: imagesAttachedKey) else { return }

        let descriptor = FetchDescriptor<Product>()
        guard let products = try? context.fetch(descriptor) else { return }

        for product in products {
            guard let imageName = imageName(forTitle: product.title),
                  let imageData = loadImageData(named: imageName) else { continue }
            product.imageData = imageData
        }

        guard (try? context.save()) != nil else { return }
        UserDefaults.standard.set(true, forKey: imagesAttachedKey)
    }

    private static func imageName(forTitle title: String) -> String? {
        initialProducts.first { $0.title == title }?.imageName
    }

    private static func loadImageData(named name: String) -> Data? {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "jpg",
            subdirectory: "Resources/ProductImages"
        ) ?? Bundle.main.url(forResource: name, withExtension: "jpg")
        return url.flatMap { try? Data(contentsOf: $0) }
    }

    private struct SeedProduct {
        let title: String
        let spec: String
        let costPrice: Double
        let sellPrice: Double
        let stockQuantity: Int
        let imageName: String
        let barcode: String
    }

    private static let initialProducts: [SeedProduct] = [
        SeedProduct(
            title: "网红儿童玩具特工相机",
            spec: "12只装",
            costPrice: 2.94,
            sellPrice: 5,
            stockQuantity: 12,
            imageName: "product_camera",
            barcode: "690000100001"
        ),
        SeedProduct(
            title: "天然水晶宝石矿石标本套装",
            spec: "40种宝石标本不重复",
            costPrice: 0.96,
            sellPrice: 3,
            stockQuantity: 40,
            imageName: "product_crystal",
            barcode: "690000100002"
        ),
        SeedProduct(
            title: "方块磁铁益智积木",
            spec: "黑色抛光磁力方块",
            costPrice: 2.34,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_magnet_block",
            barcode: "690000100003"
        ),
        SeedProduct(
            title: "俄罗斯掌上方块游戏机",
            spec: "批发10个装，款式随机",
            costPrice: 3,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_game_console",
            barcode: "690000100004"
        ),
        SeedProduct(
            title: "三角洲磁力火车玩具",
            spec: "整盒20小袋",
            costPrice: 1.18,
            sellPrice: 3,
            stockQuantity: 20,
            imageName: "product_train",
            barcode: "690000100005"
        ),
        SeedProduct(
            title: "咔巴熊趣味躲猫猫中性笔",
            spec: "变脸中性笔全套",
            costPrice: 2.05,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_pen_cat",
            barcode: "690000100006"
        ),
        SeedProduct(
            title: "大学之约盲盒笔",
            spec: "985/211院校盲盒笔",
            costPrice: 1,
            sellPrice: 3,
            stockQuantity: 22,
            imageName: "product_blindbox_pen",
            barcode: "690000100007"
        )
    ]
}
