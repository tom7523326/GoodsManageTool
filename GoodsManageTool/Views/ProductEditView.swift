import SwiftUI
import SwiftData
import PhotosUI

enum ProductEditMode {
    case add
    case edit(Product)
}

struct ProductEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Product.sortOrder) private var products: [Product]

    let mode: ProductEditMode

    @State private var title = ""
    @State private var spec = ""
    @State private var costPriceText = ""
    @State private var sellPriceText = ""
    @State private var stockQuantity = 1
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("商品信息") {
                    TextField("商品标题", text: $title)
                    TextField("规格说明", text: $spec)
                }

                Section("价格") {
                    HStack {
                        Text("进价（单件）")
                        Spacer()
                        TextField("0.00", text: $costPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("卖价（单件）")
                        Spacer()
                        TextField("0.00", text: $sellPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("库存") {
                    Stepper("初始库存 \(stockQuantity)", value: $stockQuantity, in: 0...9999)
                }

                Section("商品图") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .frame(width: 60, height: 60)
                                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                            }
                            Text(imageData == nil ? "选择图片" : "更换图片")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑商品" : "添加商品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExistingData)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Double(costPriceText.replacingOccurrences(of: ",", with: ".")) != nil
            && Double(sellPriceText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func loadExistingData() {
        guard case .edit(let product) = mode else { return }
        title = product.title
        spec = product.spec
        costPriceText = String(format: "%.2f", product.costPrice)
        sellPriceText = String(format: "%.2f", product.sellPrice)
        stockQuantity = product.stockQuantity
        imageData = product.imageData
    }

    private func save() {
        guard
            let costPrice = Double(costPriceText.replacingOccurrences(of: ",", with: ".")),
            let sellPrice = Double(sellPriceText.replacingOccurrences(of: ",", with: "."))
        else { return }

        switch mode {
        case .add:
            let product = Product(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                spec: spec.trimmingCharacters(in: .whitespacesAndNewlines),
                costPrice: costPrice,
                sellPrice: sellPrice,
                stockQuantity: stockQuantity,
                imageData: imageData,
                sortOrder: products.count
            )
            modelContext.insert(product)
        case .edit(let product):
            product.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            product.spec = spec.trimmingCharacters(in: .whitespacesAndNewlines)
            product.costPrice = costPrice
            product.sellPrice = sellPrice
            product.stockQuantity = stockQuantity
            product.imageData = imageData
        }

        try? modelContext.save()
        dismiss()
    }
}

struct ProductDetailManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var showingEdit = false
    @State private var showingStockAdjust = false
    @State private var stockChangeType: StockChangeType = .stockIn

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ProductThumbnailView(product: product, size: 88)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.title)
                                .font(.title3.bold())
                            Text(product.spec)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("价格与库存") {
                    LabeledContent("进价", value: PriceFormatter.string(product.costPrice))
                    LabeledContent("卖价", value: PriceFormatter.string(product.sellPrice))
                    LabeledContent("当前库存", value: "\(product.stockQuantity)")
                }

                Section("库存操作") {
                    Button {
                        stockChangeType = .stockIn
                        showingStockAdjust = true
                    } label: {
                        Label("进货", systemImage: "arrow.down.circle.fill")
                    }

                    Button {
                        stockChangeType = .stockOut
                        showingStockAdjust = true
                    } label: {
                        Label("出货", systemImage: "arrow.up.circle.fill")
                    }
                }

                if !product.saleRecords.isEmpty {
                    Section("最近销售") {
                        ForEach(recentSales) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(record.saleType.rawValue) × \(record.quantity)")
                                    .font(.subheadline.bold())
                                Text("\(record.ageGroup.rawValue) · \(record.soldAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("合计 \(PriceFormatter.string(record.totalPrice))")
                                    .font(.caption)
                            }
                        }
                    }
                }

                if !product.stockRecords.isEmpty {
                    Section("库存变动") {
                        ForEach(recentStockRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(record.changeType.rawValue) \(record.quantity) 件")
                                    .font(.subheadline.bold())
                                if !record.note.isEmpty {
                                    Text(record.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(record.changedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("商品详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") { showingEdit = true }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEdit) {
                ProductEditView(mode: .edit(product))
            }
            .sheet(isPresented: $showingStockAdjust) {
                StockAdjustView(product: product, changeType: stockChangeType)
            }
        }
    }

    private var recentSales: [SaleRecord] {
        product.saleRecords.sorted { $0.soldAt > $1.soldAt }.prefix(5).map { $0 }
    }

    private var recentStockRecords: [StockRecord] {
        product.stockRecords.sorted { $0.changedAt > $1.changedAt }.prefix(5).map { $0 }
    }
}

struct StockAdjustView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product
    let changeType: StockChangeType

    @State private var quantity = 1
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(product.title)
                        .font(.headline)
                    Text("当前库存：\(product.stockQuantity)")
                        .foregroundStyle(.secondary)
                }

                Section("操作") {
                    Stepper("\(changeType.rawValue)数量：\(quantity)", value: $quantity, in: 1...9999)
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle(changeType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") { applyChange() }
                        .disabled(changeType == .stockOut && quantity > product.stockQuantity)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyChange() {
        let record = StockRecord(
            changeType: changeType,
            quantity: quantity,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            product: product
        )

        switch changeType {
        case .stockIn:
            product.stockQuantity += quantity
        case .stockOut:
            product.stockQuantity = max(0, product.stockQuantity - quantity)
        }

        modelContext.insert(record)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ProductEditView(mode: .add)
        .modelContainer(for: Product.self, inMemory: true)
}
