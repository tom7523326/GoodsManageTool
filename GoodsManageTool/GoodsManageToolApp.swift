//
//  GoodsManageToolApp.swift
//  GoodsManageTool
//
//  Created by 汤寿麟 on 2026/6/21.
//

import SwiftUI
import SwiftData

@main
struct GoodsManageToolApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Product.self,
            SaleRecord.self,
            StockRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    SeedData.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
