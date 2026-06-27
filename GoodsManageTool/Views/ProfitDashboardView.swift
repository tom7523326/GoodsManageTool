import SwiftUI
import SwiftData

struct ProfitDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Product.sortOrder) private var products: [Product]
    @Query(sort: \SaleRecord.soldAt, order: .reverse) private var orders: [SaleRecord]

    private var stats: [ProductStats] {
        BusinessStats.productStats(from: products)
    }

    private var totalRevenue: Double {
        BusinessStats.totalRevenue(records: orders)
    }

    private var totalProfit: Double {
        BusinessStats.totalProfit(products: products)
    }

    private var totalSoldCost: Double {
        stats.reduce(0) { $0 + $1.cost }
    }

    private var inventoryCost: Double {
        BusinessStats.totalInventoryCost(products: products)
    }

    private var inventoryRetail: Double {
        BusinessStats.totalInventoryRetail(products: products)
    }

    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        StatCardView(
                            title: "累计成交额",
                            value: PriceFormatter.string(totalRevenue),
                            icon: "yensign.circle.fill",
                            tint: AppTheme.accent
                        )
                        StatCardView(
                            title: "累计毛利润",
                            value: PriceFormatter.string(totalProfit),
                            subtitle: "已售 \(orders.reduce(0) { $0 + $1.quantity }) 件",
                            icon: "chart.line.uptrend.xyaxis",
                            tint: AppTheme.success
                        )
                        StatCardView(
                            title: "库存成本",
                            value: PriceFormatter.string(inventoryCost),
                            subtitle: "剩余 \(products.reduce(0) { $0 + $1.stockQuantity }) 件",
                            icon: "shippingbox.fill",
                            tint: .blue
                        )
                        StatCardView(
                            title: "库存零售值",
                            value: PriceFormatter.string(inventoryRetail),
                            subtitle: "潜在收入",
                            icon: "bag.fill",
                            tint: AppTheme.warning
                        )
                    }

                    overviewCard
                    productTable
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("成交总盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AdminToolbarMenu()
                }
            }
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("经营概览")
                .font(.headline)

            overviewRow(title: "已售成本", value: PriceFormatter.string(totalSoldCost))
            overviewRow(title: "已售利润", value: PriceFormatter.string(totalProfit), highlight: true)
            Divider()
            overviewRow(title: "库存成本合计", value: PriceFormatter.string(inventoryCost))
            overviewRow(title: "库存零售合计", value: PriceFormatter.string(inventoryRetail))
            overviewRow(
                title: "全盘资产（库存成本 + 已售利润）",
                value: PriceFormatter.string(inventoryCost + totalProfit)
            )
        }
        .appCard()
    }

    private func overviewRow(title: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(highlight ? .bold : .medium))
                .foregroundStyle(highlight ? AppTheme.success : .primary)
        }
    }

    private var productTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分商品明细")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                tableHeader

                ForEach(stats) { item in
                    Divider().padding(.leading, 12)
                    productRow(item)
                }
            }
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.28 : 0.06),
                radius: colorScheme == .dark ? 8 : 12,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
        }
    }

    private var tableHeader: some View {
        HStack {
            Text("商品").frame(maxWidth: .infinity, alignment: .leading)
            Text("库存").frame(width: 44)
            Text("已售").frame(width: 44)
            Text("利润").frame(width: 64, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemFill).opacity(0.5))
    }

    private func productRow(_ item: ProductStats) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ProductThumbnailView(product: item.product, size: 36)
                Text(item.product.title)
                    .font(.caption)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(item.product.stockQuantity)")
                .font(.caption.monospacedDigit())
                .frame(width: 44)

            Text("\(item.soldQuantity)")
                .font(.caption.monospacedDigit())
                .frame(width: 44)

            Text(PriceFormatter.string(item.profit))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(item.profit >= 0 ? AppTheme.success : AppTheme.danger)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

#Preview {
    ProfitDashboardView()
        .modelContainer(for: [Product.self, SaleRecord.self], inMemory: true)
}
