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
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeSharedContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
