import Foundation
import SwiftData

enum SeedData {
    private static let seededKey = "hasSeededInitialProducts"
    private static let imagesAttachedKey = "hasAttachedProductImages_v3"

    static func seedIfNeeded(context: ModelContext) {
        seedProductsIfNeeded(context: context)
        attachProductImagesIfNeeded(context: context)
    }

    private static func seedProductsIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let descriptor = FetchDescriptor<Product>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        initialProducts.enumerated().forEach { index, item in
            context.insert(
                Product(
                    title: item.title,
                    spec: item.spec,
                    costPrice: item.costPrice,
                    sellPrice: item.sellPrice,
                    stockQuantity: item.stockQuantity,
                    imageData: loadImageData(named: item.imageName),
                    sortOrder: index
                )
            )
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
        UserDefaults.standard.set(true, forKey: imagesAttachedKey)
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

        try? context.save()
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
    }

    private static let initialProducts: [SeedProduct] = [
        SeedProduct(
            title: "网红儿童玩具特工相机",
            spec: "12只装",
            costPrice: 2.94,
            sellPrice: 5,
            stockQuantity: 12,
            imageName: "product_camera"
        ),
        SeedProduct(
            title: "天然水晶宝石矿石标本套装",
            spec: "40种宝石标本不重复",
            costPrice: 0.96,
            sellPrice: 3,
            stockQuantity: 40,
            imageName: "product_crystal"
        ),
        SeedProduct(
            title: "方块磁铁益智积木",
            spec: "黑色抛光磁力方块",
            costPrice: 2.34,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_magnet_block"
        ),
        SeedProduct(
            title: "俄罗斯掌上方块游戏机",
            spec: "批发10个装，款式随机",
            costPrice: 3,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_game_console"
        ),
        SeedProduct(
            title: "三角洲磁力火车玩具",
            spec: "整盒20小袋",
            costPrice: 1.18,
            sellPrice: 3,
            stockQuantity: 20,
            imageName: "product_train"
        ),
        SeedProduct(
            title: "咔巴熊趣味躲猫猫中性笔",
            spec: "变脸中性笔全套",
            costPrice: 2.05,
            sellPrice: 5,
            stockQuantity: 10,
            imageName: "product_pen_cat"
        ),
        SeedProduct(
            title: "大学之约盲盒笔",
            spec: "985/211院校盲盒笔",
            costPrice: 1,
            sellPrice: 3,
            stockQuantity: 22,
            imageName: "product_blindbox_pen"
        )
    ]
}
