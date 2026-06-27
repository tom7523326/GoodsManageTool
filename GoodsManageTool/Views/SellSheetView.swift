import SwiftUI
import SwiftData

struct SellSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var saleType: SaleType = SellPreferences.loadSaleType()
    @State private var ageGroup: AgeGroup = SellPreferences.loadAgeGroup()
    @State private var quantity = 1
    @State private var discountPriceText = ""
    @State private var showConfirmation = false
    @State private var useCashPayment = false
    @State private var cashReceivedText = ""
    @State private var saveErrorMessage: String?

    private let quickQuantities = [1, 2, 3, 5, 10]

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

    private var cashReceived: Double? {
        Double(cashReceivedText.replacingOccurrences(of: ",", with: "."))
    }

    private var changeAmount: Double? {
        guard useCashPayment, let received = cashReceived else { return nil }
        return received - totalPrice
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

                    quantityCard

                    cashPaymentCard

                    checkoutCard

                    if let saveErrorMessage {
                        Text(saveErrorMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                Text(confirmationMessage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var productHeader: some View {
        HStack(spacing: 14) {
            ProductThumbnailView(product: product, size: 72, cornerRadius: 16)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(product.title)
                        .font(.headline)
                        .lineLimit(2)
                    if product.isSample {
                        SampleBadge()
                    }
                }
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

    private var quantityCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("卖出数量")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(quantity) 件")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentDark)
            }

            HStack(spacing: 8) {
                ForEach(quickQuantities, id: \.self) { value in
                    Button {
                        quantity = min(max(value, 1), max(product.stockQuantity, 1))
                    } label: {
                        Text("\(value)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                quantity == value ? AppTheme.accent.opacity(0.15) : Color(.tertiarySystemFill),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(quantity == value ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            }
                            .foregroundStyle(quantity == value ? AppTheme.accentDark : .primary)
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(value > product.stockQuantity)
                }
            }

            Stepper(value: $quantity, in: 1...max(product.stockQuantity, 1)) {
                EmptyView()
            }
        }
        .appCard()
    }

    private var cashPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("现金收款", isOn: $useCashPayment)

            if useCashPayment {
                HStack {
                    Text("收到")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("¥")
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $cashReceivedText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }

                if let changeAmount {
                    HStack {
                        Text("找零")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(PriceFormatter.string(max(changeAmount, 0)))
                            .font(.headline)
                            .foregroundStyle(changeAmount >= 0 ? AppTheme.success : AppTheme.danger)
                    }
                }
            }
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
        .disabled(!canConfirm)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var canConfirm: Bool {
        if product.stockQuantity < quantity { return false }
        if saleType == .discount {
            guard let price = parsedDiscountPrice, price > 0 else { return false }
        }
        if useCashPayment {
            guard let received = cashReceived else { return false }
            return received >= totalPrice
        }
        return true
    }

    private var parsedDiscountPrice: Double? {
        Double(discountPriceText.replacingOccurrences(of: ",", with: "."))
    }

    private var confirmationMessage: String {
        var message = "\(product.title)\n\(saleType.rawValue) · \(ageGroup.rawValue)\n\(quantity) 件 · 合计 \(PriceFormatter.string(totalPrice))"
        if useCashPayment, let changeAmount, changeAmount >= 0 {
            message += "\n找零 \(PriceFormatter.string(changeAmount))"
        }
        return message
    }

    private func completeSale() {
        saveErrorMessage = nil
        let record = SaleRecord(
            saleType: saleType,
            ageGroup: ageGroup,
            quantity: quantity,
            unitPrice: unitPrice,
            product: product
        )
        product.stockQuantity -= quantity
        modelContext.insert(record)

        do {
            try modelContext.save()
            SellPreferences.save(saleType: saleType, ageGroup: ageGroup)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = "保存失败，请重试"
        }
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
