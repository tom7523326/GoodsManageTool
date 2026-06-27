//
//  ContentView.swift
//  GoodsManageTool
//
//  Created by 汤寿麟 on 2026/6/21.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Product.self, SaleRecord.self, StockRecord.self], inMemory: true)
}
