import SwiftUI
import SwiftData

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Product.sortOrder) private var products: [Product]

    @State private var selectedProduct: Product?
    @State private var searchText = ""
    @State private var showBarcodeScanner = false
    @State private var showSampleBanner = !SampleDataService.isBannerDismissed
    @State private var showClearSamplesConfirm = false
    @State private var showClearSamplesSuccess = false
    @State private var showClearSamplesError = false
    @State private var pendingSellProduct: Product?
    @State private var scanAlertMessage: String?
    @State private var showScanAlert = false
    @State private var showSeedError = false

    private var hasSampleProducts: Bool {
        SampleDataService.hasSampleProducts(in: products)
    }

    private var sortedProducts: [Product] {
        products.sorted { lhs, rhs in
            if lhs.isOutOfStock != rhs.isOutOfStock {
                return !lhs.isOutOfStock
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return sortedProducts }
        return sortedProducts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.spec.localizedCaseInsensitiveContains(searchText)
                || ($0.barcode?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var todayHotProducts: [ProductStats] {
        BusinessStats.todayProductStats(from: products)
            .filter { $0.soldQuantity > 0 }
            .sorted { $0.soldQuantity > $1.soldQuantity }
            .prefix(3)
            .map { $0 }
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 340, maximum: 440), spacing: 16)]
        }
        return [GridItem(.flexible())]
    }

    private var inStockCount: Int {
        products.filter { !$0.isOutOfStock }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchField

                    if showSampleBanner && hasSampleProducts {
                        sampleBanner
                    }

                    headerCard

                    if !todayHotProducts.isEmpty {
                        todayHotSection
                    }

                    if filteredProducts.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductCardView(product: product) {
                                    selectedProduct = product
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("摆摊卖货")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if hasSampleProducts {
                        Menu {
                            Button("清除示例数据", role: .destructive) {
                                showClearSamplesConfirm = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBarcodeScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .disabled(products.isEmpty)
                }
            }
            .sheet(item: $selectedProduct) { product in
                SellSheetView(product: product)
            }
            .sheet(isPresented: $showBarcodeScanner, onDismiss: {
                if let product = pendingSellProduct {
                    selectedProduct = product
                    pendingSellProduct = nil
                }
            }) {
                BarcodeScannerView { barcode in
                    pendingSellProduct = nil
                    showBarcodeScanner = false

                    guard let product = SampleDataService.product(matchingBarcode: barcode, in: products) else {
                        scanAlertMessage = "未找到匹配条码的商品"
                        showScanAlert = true
                        return
                    }

                    if product.isOutOfStock {
                        scanAlertMessage = "「\(product.title)」暂无库存"
                        showScanAlert = true
                        return
                    }

                    pendingSellProduct = product
                }
            }
            .confirmationDialog(
                "清除示例数据？",
                isPresented: $showClearSamplesConfirm,
                titleVisibility: .visible
            ) {
                Button("清除示例商品", role: .destructive) {
                    clearSampleProducts()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将删除所有示例商品及其销售、库存记录，此操作不可撤销。")
            }
            .alert("已清除示例数据", isPresented: $showClearSamplesSuccess) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("请添加你的商品，开始真实摆摊。")
            }
            .alert("操作失败", isPresented: $showClearSamplesError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("清除示例数据失败，请稍后重试。")
            }
            .alert("扫码结果", isPresented: $showScanAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(scanAlertMessage ?? "")
            }
            .alert("加载失败", isPresented: $showSeedError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("示例商品加载失败，请稍后重试。")
            }
        }
    }

    private func clearSampleProducts() {
        do {
            try SampleDataService.clearSampleProducts(context: modelContext)
            showSampleBanner = false
            showClearSamplesSuccess = true
        } catch {
            showClearSamplesError = true
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索商品名称或规格", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var sampleBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("当前含示例商品")
                        .font(.subheadline.weight(.semibold))
                    Text("体验熟悉功能后，可一键清除并添加自己的商品")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button {
                    showSampleBanner = false
                    SampleDataService.isBannerDismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive) {
                showClearSamplesConfirm = true
            } label: {
                Text("清除示例数据")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hasSampleProducts && products.allSatisfy(\.isSample) ? "示例摊位" : "今日摆摊")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(headerSummaryText)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "storefront.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("点击卡片卖出")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(18)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var headerSummaryText: String {
        if hasSampleProducts && products.allSatisfy(\.isSample) {
            return "\(products.count) 款示例商品 · \(inStockCount) 款有货"
        }
        return "\(products.count) 款商品 · \(inStockCount) 款有货"
    }

    private var todayHotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日热卖")
                .font(.headline)

            ForEach(todayHotProducts) { stats in
                HStack {
                    Text(stats.product.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("已售 \(stats.soldQuantity) 件")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accentDark)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label("暂无商品", systemImage: "shippingbox")
        } description: {
            Text("你可以加载示例体验，或前往库存添加商品")
        } actions: {
            Button("加载示例商品") {
                if SeedData.seedSampleProducts(context: modelContext) {
                    showSampleBanner = true
                    SampleDataService.isBannerDismissed = false
                } else {
                    showSeedError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(.top, 40)
    }
}

#Preview {
    ProductListView()
        .modelContainer(for: Product.self, inMemory: true)
}
