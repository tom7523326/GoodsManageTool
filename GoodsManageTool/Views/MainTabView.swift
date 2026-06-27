import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var authStore = AdminAuthStore()
    @State private var selectedTab = 0

    private let profitTab = 3
    private let inventoryTab = 4

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductListView()
                .tabItem { Label("卖货", systemImage: "cart.fill") }
                .tag(0)

            CustomerShowcaseView()
                .tabItem { Label("展示", systemImage: "sparkles") }
                .tag(1)

            OrdersView()
                .tabItem { Label("订单", systemImage: "doc.text.fill") }
                .tag(2)

            PasswordProtectedView(authStore: authStore, title: "盘账") {
                ProfitDashboardView()
            }
            .tabItem { Label("盘账", systemImage: "chart.bar.fill") }
            .tag(profitTab)

            PasswordProtectedView(authStore: authStore, title: "库存") {
                InventoryManageView()
            }
            .tabItem { Label("库存", systemImage: "archivebox.fill") }
            .tag(inventoryTab)
        }
        .tint(AppTheme.accent)
        .environment(authStore)
        .onChange(of: selectedTab) { oldValue, _ in
            if oldValue == profitTab || oldValue == inventoryTab {
                authStore.lock()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Product.self, SaleRecord.self, StockRecord.self], inMemory: true)
}
