import SwiftUI
import SwiftData

struct InventoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.sortOrder) private var products: [Product]

    @State private var showingAddProduct = false
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "暂无商品",
                        systemImage: "archivebox",
                        description: Text("点击右上角添加商品")
                    )
                } else {
                    VStack(spacing: 8) {
                        inventorySummary
                            .padding(.horizontal, 16)

                        List {
                            Section("全部商品") {
                                ForEach(products) { product in
                                    Button {
                                        selectedProduct = product
                                    } label: {
                                        InventoryRowView(product: product)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete(perform: deleteProducts)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .contentMargins(.top, 0, for: .scrollContent)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("库存管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AdminToolbarMenu()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(AppTheme.accent, AppTheme.accent.opacity(0.25))
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                ProductEditView(mode: .add)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailManageView(product: product)
            }
        }
    }

    private var inventorySummary: some View {
        HStack(spacing: 20) {
            summaryItem(title: "商品", value: "\(products.count)")
            summaryItem(title: "总库存", value: "\(products.reduce(0) { $0 + $1.stockQuantity })")
            summaryItem(title: "缺货", value: "\(products.filter(\.isOutOfStock).count)")
        }
        .padding(18)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(products[index])
        }
        try? modelContext.save()
    }
}

private struct InventoryRowView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            ProductThumbnailView(product: product, size: 56, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(product.spec)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("进 \(PriceFormatter.string(product.costPrice))")
                    Text("卖 \(PriceFormatter.string(product.sellPrice))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(product.stockQuantity)")
                    .font(.title3.bold())
                    .foregroundStyle(product.isOutOfStock ? AppTheme.danger : .primary)
                Text("库存")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InventoryManageView()
        .modelContainer(for: Product.self, inMemory: true)
}
