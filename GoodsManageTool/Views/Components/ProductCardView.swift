import SwiftUI

struct ProductThumbnailView: View {
    let product: Product
    var size: CGFloat = 56
    var cornerRadius: CGFloat = 10

    var body: some View {
        Group {
            if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.2), AppTheme.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(String(product.title.prefix(1)))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.accentDark)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ProductHeroImageView: View {
    let product: Product

    var body: some View {
        Color(.secondarySystemGroupedBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.accent.opacity(0.5))
                }
            }
            .clipped()
    }
}

struct ProductCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let product: Product
    let onSell: () -> Void

    var body: some View {
        Button(action: onSell) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack(alignment: .topLeading) {
                        ProductThumbnailView(product: product, size: 80, cornerRadius: 16)
                        if product.isSample {
                            SampleBadge()
                                .padding(4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.title)
                            .font(.headline)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.primary)

                        Text(product.spec)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        HStack(spacing: 10) {
                            Text(PriceFormatter.string(product.sellPrice))
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.accentDark)

                            stockBadge
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)

                Divider().padding(.horizontal, 16)

                HStack {
                    Image(systemName: "bolt.fill")
                    Text(product.isOutOfStock ? "暂无库存" : "快速卖出")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(product.isOutOfStock ? Color.secondary : Color.white)
                .background {
                    if product.isOutOfStock {
                        Color(.tertiarySystemFill)
                    } else {
                        AppTheme.heroGradient
                    }
                }
            }
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.28 : 0.07),
                radius: colorScheme == .dark ? 8 : 14,
                x: 0,
                y: colorScheme == .dark ? 2 : 5
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(product.isOutOfStock)
    }

    @ViewBuilder
    private var stockBadge: some View {
        let color: Color = {
            if product.isOutOfStock { return AppTheme.danger }
            if product.isLowStock { return AppTheme.warning }
            return AppTheme.success
        }()

        Text(product.stockStatusText)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }
}
