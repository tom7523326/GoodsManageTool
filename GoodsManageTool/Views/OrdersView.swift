import SwiftUI
import SwiftData

struct OrdersView: View {
    @Query(sort: \SaleRecord.soldAt, order: .reverse) private var orders: [SaleRecord]

    @State private var editingRecord: SaleRecord?

    private var groupedOrders: [(date: Date, records: [SaleRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: orders) { record in
            calendar.startOfDay(for: record.soldAt)
        }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.soldAt > $1.soldAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    ContentUnavailableView(
                        "暂无订单",
                        systemImage: "doc.text",
                        description: Text("完成第一笔销售后，订单会出现在这里")
                    )
                } else {
                    VStack(spacing: 8) {
                        summaryBanner
                            .padding(.horizontal, 16)

                        List {
                            ForEach(groupedOrders, id: \.date) { group in
                                Section(AppDateFormatter.orderSectionTitle(for: group.date)) {
                                    ForEach(group.records) { record in
                                        Button {
                                            editingRecord = record
                                        } label: {
                                            OrderRowView(record: record)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .contentMargins(.top, 0, for: .scrollContent)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("订单记录")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingRecord) { record in
                OrderEditView(record: record)
            }
        }
    }

    private var summaryBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("累计成交")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text(PriceFormatter.string(BusinessStats.totalRevenue(records: orders)))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("订单数")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(orders.count) 笔")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OrderRowView: View {
    let record: SaleRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let product = record.product {
                ProductThumbnailView(product: product, size: 56)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(record.product?.title ?? "已删除商品")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(AppDateFormatter.orderTime(for: record.soldAt))
                    Text("·")
                    Text(record.saleType.rawValue)
                    Text("·")
                    Text(record.ageGroup.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Text("× \(record.quantity)")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text(PriceFormatter.string(record.totalPrice))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentDark)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OrdersView()
        .modelContainer(for: [Product.self, SaleRecord.self], inMemory: true)
}
