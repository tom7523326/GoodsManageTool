import SwiftUI
import SwiftData

struct SellSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var saleType: SaleType = .original
    @State private var ageGroup: AgeGroup = .age10to20
    @State private var quantity = 1
    @State private var discountPriceText = ""
    @State private var showConfirmation = false

    private var unitPrice: Double {
        switch saleType {
        case .original:
            return product.sellPrice
        case .discount:
            return Double(discountPriceText.replacingOccurrences(of: ",", with: ".")) ?? product.sellPrice
        case .gift:
            return 0
        }
    }

    private var totalPrice: Double {
        Double(quantity) * unitPrice
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    productHeader

                    VStack(alignment: .leading, spacing: 16) {
                        ChipSelector(title: "销售方式", items: SaleType.allCases, selection: $saleType)

                        if saleType == .discount {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("折扣单价")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("¥")
                                        .foregroundStyle(.secondary)
                                    TextField("输入成交单价", text: $discountPriceText)
                                        .keyboardType(.decimalPad)
                                }
                                .padding(14)
                                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .appCard()

                    ChipSelector(title: "购买人群", items: AgeGroup.allCases, selection: $ageGroup)
                        .appCard()

                    VStack(spacing: 14) {
                        HStack {
                            Text("卖出数量")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(quantity) 件")
                                .font(.headline)
                                .foregroundStyle(AppTheme.accentDark)
                        }

                        Stepper(value: $quantity, in: 1...max(product.stockQuantity, 1)) {
                            EmptyView()
                        }
                    }
                    .appCard()

                    checkoutCard
                }
                .padding()
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("确认卖出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmButton
            }
            .onAppear {
                discountPriceText = String(format: "%.2f", product.sellPrice)
            }
            .alert("确认卖出？", isPresented: $showConfirmation) {
                Button("确认", role: .destructive) { completeSale() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("\(product.title)\n\(saleType.rawValue) · \(ageGroup.rawValue)\n\(quantity) 件 · 合计 \(PriceFormatter.string(totalPrice))")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var productHeader: some View {
        HStack(spacing: 14) {
            ProductThumbnailView(product: product, size: 72, cornerRadius: 16)
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(product.spec)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("库存 \(product.stockQuantity) 件")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accentDark)
            }
            Spacer()
        }
        .appCard()
    }

    private var checkoutCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("单价")
                Spacer()
                Text(PriceFormatter.string(unitPrice))
            }
            .foregroundStyle(.secondary)

            HStack {
                Text("合计")
                    .font(.headline)
                Spacer()
                Text(PriceFormatter.string(totalPrice))
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.accentDark)
            }
        }
        .appCard()
    }

    private var confirmButton: some View {
        Button {
            showConfirmation = true
        } label: {
            Text("确认卖出")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(AppTheme.heroGradient)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(product.stockQuantity < quantity || (saleType == .discount && discountPriceText.isEmpty))
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func completeSale() {
        let record = SaleRecord(
            saleType: saleType,
            ageGroup: ageGroup,
            quantity: quantity,
            unitPrice: unitPrice,
            product: product
        )
        product.stockQuantity -= quantity
        modelContext.insert(record)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let product = Product(
        title: "测试商品",
        spec: "规格",
        costPrice: 2,
        sellPrice: 5,
        stockQuantity: 10
    )
    return SellSheetView(product: product)
        .modelContainer(for: Product.self, inMemory: true)
}
