import SwiftUI
import SwiftData

struct InventoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.sortOrder) private var products: [Product]

    @State private var showingAddProduct = false
    @State private var selectedProduct: Product?
    @State private var showClearSamplesConfirm = false
    @State private var showClearSamplesSuccess = false
    @State private var showClearSamplesError = false
    @State private var productsPendingDelete: [Product] = []
    @State private var showDeleteConfirm = false
    @State private var deleteErrorMessage: String?

    private var hasSampleProducts: Bool {
        SampleDataService.hasSampleProducts(in: products)
    }

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

                        if hasSampleProducts {
                            sampleClearBanner
                                .padding(.horizontal, 16)
                        }

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
                                .onDelete(perform: requestDelete)
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
                    AdminToolbarMenu(
                        hasSampleProducts: hasSampleProducts,
                        onClearSamples: { showClearSamplesConfirm = true }
                    )
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
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("删除商品", role: .destructive) {
                    confirmDeleteProducts()
                }
                Button("取消", role: .cancel) {
                    productsPendingDelete = []
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .alert("删除失败", isPresented: .init(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }

    private var deleteConfirmationTitle: String {
        productsPendingDelete.count > 1 ? "删除 \(productsPendingDelete.count) 个商品？" : "删除商品？"
    }

    private var deleteConfirmationMessage: String {
        let saleCount = productsPendingDelete.reduce(0) { $0 + $1.saleRecords.count }
        if saleCount > 0 {
            return "将同时删除 \(saleCount) 笔关联订单记录，此操作不可撤销。"
        }
        return "删除后无法恢复，请确认。"
    }

    private func requestDelete(at offsets: IndexSet) {
        productsPendingDelete = offsets.map { products[$0] }
        showDeleteConfirm = true
    }

    private func confirmDeleteProducts() {
        for product in productsPendingDelete {
            modelContext.delete(product)
        }
        productsPendingDelete = []

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deleteErrorMessage = "删除失败，请重试"
        }
    }

    private func clearSampleProducts() {
        do {
            try SampleDataService.clearSampleProducts(context: modelContext)
            showClearSamplesSuccess = true
        } catch {
            showClearSamplesError = true
        }
    }

    private var sampleClearBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("含 \(products.filter(\.isSample).count) 款示例商品")
                    .font(.subheadline.weight(.semibold))
                Text("清除后可添加你自己的商品")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button("清除示例", role: .destructive) {
                showClearSamplesConfirm = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(AppTheme.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
}

private struct InventoryRowView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            ProductThumbnailView(product: product, size: 56, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(product.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if product.isSample {
                        SampleBadge()
                    }
                }

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
