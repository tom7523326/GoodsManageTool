import Foundation
import SwiftData

enum ModelContainerFactory {
    static func makeSharedContainer() -> ModelContainer {
        let schema = Schema([
            Product.self,
            SaleRecord.self,
            StockRecord.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }
}
