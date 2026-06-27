import SwiftUI
import SwiftData

struct OrderEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: SaleRecord

    @State private var saleType: SaleType
    @State private var ageGroup: AgeGroup
    @State private var quantity: Int
    @State private var discountPriceText: String
    @State private var soldAt: Date
    @State private var errorMessage: String?
    @State private var showSaveConfirmation = false

    init(record: SaleRecord) {
        self.record = record
        _saleType = State(initialValue: record.saleType)
        _ageGroup = State(initialValue: record.ageGroup)
        _quantity = State(initialValue: record.quantity)
        _discountPriceText = State(initialValue: String(format: "%.2f", record.unitPrice))
        _soldAt = State(initialValue: record.soldAt)
    }

    private var product: Product? { record.product }

    private var maxQuantity: Int {
        guard let product else { return record.quantity }
        return product.stockQuantity + record.quantity
    }

    private var unitPrice: Double {
        switch saleType {
        case .original:
            return product?.sellPrice ?? record.unitPrice
        case .discount:
            return Double(discountPriceText.replacingOccurrences(of: ",", with: ".")) ?? record.unitPrice
        case .gift:
            return 0
        }
    }

    private var totalPrice: Double {
        Double(quantity) * unitPrice
    }

    var body: some View {
        NavigationStack {
            Group {
                if product == nil {
                    ContentUnavailableView(
                        "无法编辑",
                        systemImage: "exclamationmark.triangle",
                        description: Text("关联商品已删除")
                    )
                } else {
                    editForm
                }
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("编辑订单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { showSaveConfirmation = true }
                        .disabled(product == nil || (saleType == .discount && discountPriceText.isEmpty))
                }
            }
            .alert("保存修改？", isPresented: $showSaveConfirmation) {
                Button("保存") { save() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将同步更新库存与成交数据")
            }
        }
        .presentationDetents([.large])
    }

    private var editForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let product {
                    HStack(spacing: 14) {
                        ProductThumbnailView(product: product, size: 72, cornerRadius: 16)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.title)
                                .font(.headline)
                                .lineLimit(2)
                            Text("修改后可用库存 \(maxQuantity) 件")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accentDark)
                        }
                        Spacer()
                    }
                    .appCard()
                }

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
                        Text("数量")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(quantity) 件")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accentDark)
                    }
                    Stepper(value: $quantity, in: 1...max(1, maxQuantity)) {
                        EmptyView()
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("成交时间")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    DatePicker("成交时间", selection: $soldAt, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .appCard()

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

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
    }

    private func save() {
        do {
            try OrderEditService.update(
                record: record,
                saleType: saleType,
                ageGroup: ageGroup,
                quantity: quantity,
                unitPrice: unitPrice,
                soldAt: soldAt
            )
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let product = Product(
        title: "测试商品",
        spec: "规格",
        costPrice: 2,
        sellPrice: 5,
        stockQuantity: 8
    )
    let record = SaleRecord(
        saleType: .original,
        ageGroup: .age10to20,
        quantity: 2,
        unitPrice: 5,
        product: product
    )
    return OrderEditView(record: record)
        .modelContainer(for: [Product.self, SaleRecord.self], inMemory: true)
}
