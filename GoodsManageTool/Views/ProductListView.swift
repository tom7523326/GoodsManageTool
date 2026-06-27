import SwiftUI
import SwiftData

struct ProductListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Product.sortOrder) private var products: [Product]

    @State private var selectedProduct: Product?
    @State private var searchText = ""

    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.spec.localizedCaseInsensitiveContains(searchText)
        }
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
                    headerCard

                    if filteredProducts.isEmpty {
                        ContentUnavailableView(
                            "暂无商品",
                            systemImage: "shippingbox",
                            description: Text("请前往「库存」添加商品")
                        )
                        .padding(.top, 60)
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
            .sheet(item: $selectedProduct) { product in
                SellSheetView(product: product)
            }
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
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("今日摆摊")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(products.count) 款商品 · \(inStockCount) 款有货")
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
}

#Preview {
    ProductListView()
        .modelContainer(for: Product.self, inMemory: true)
}
