import SwiftUI
import SwiftData

struct CustomerShowcaseView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Product.sortOrder) private var products: [Product]

    private var rankedProducts: [ProductStats] {
        BusinessStats.todayProductStats(from: products)
            .sorted { lhs, rhs in
                if lhs.soldQuantity == rhs.soldQuantity {
                    return lhs.product.sortOrder < rhs.product.sortOrder
                }
                return lhs.soldQuantity > rhs.soldQuantity
            }
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
        return [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroHeader

                    if rankedProducts.isEmpty {
                        ContentUnavailableView(
                            "暂无商品展示",
                            systemImage: "sparkles",
                            description: Text("添加商品并完成销售后，这里会显示热销排行")
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(rankedProducts.enumerated()), id: \.element.id) { index, stats in
                                ShowcaseProductCard(stats: stats, rank: index + 1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(ShowcasePageBackground().ignoresSafeArea())
            .navigationTitle("商品展示")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("欢迎选购")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("看看哪些商品最受欢迎")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.9))
            }

            if let top = rankedProducts.first, top.soldQuantity > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("今日爆款：\(top.product.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.18), in: Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.top, 8)
    }
}

private struct ShowcaseProductCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let stats: ProductStats
    let rank: Int

    private var isHot: Bool { rank <= 3 && stats.soldQuantity > 0 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .topLeading) {
                ProductThumbnailView(product: stats.product, size: 96, cornerRadius: 14)

                Text("TOP \(rank)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(6)
            }
            .overlay(alignment: .topTrailing) {
                if stats.product.isSample {
                    SampleBadge()
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if isHot {
                        Label("热销", systemImage: "flame.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.accentDark)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    Text(stats.product.title)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if stats.product.isSample {
                        SampleBadge()
                    }
                }

                Text(stats.product.spec)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline) {
                    Text(PriceFormatter.string(stats.product.sellPrice))
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accentDark)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("已售 \(stats.soldQuantity) 件")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isHot ? AppTheme.accentDark : .secondary)
                        if stats.product.isOutOfStock {
                            Text("暂时缺货")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.danger)
                        } else {
                            Text("现货 \(stats.product.stockQuantity) 件")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.28 : 0.08),
            radius: colorScheme == .dark ? 8 : 12,
            x: 0,
            y: colorScheme == .dark ? 2 : 4
        )
    }
}

#Preview {
    CustomerShowcaseView()
        .modelContainer(for: Product.self, inMemory: true)
}
