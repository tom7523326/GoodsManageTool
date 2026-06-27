import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @State private var showSeedError = false

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "storefront.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)

                VStack(spacing: 10) {
                    Text("欢迎使用出摊帮手")
                        .font(.title.bold())
                    Text("离线管理卖货、库存与盘账")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    Button {
                        guard SeedData.seedSampleProducts(context: modelContext) else {
                            showSeedError = true
                            return
                        }
                        OnboardingStore.complete(withSampleExperience: true)
                        onComplete()
                    } label: {
                        VStack(spacing: 6) {
                            Text("先体验一下")
                                .font(.headline)
                            Text("加载 7 款示例商品，熟悉功能")
                                .font(.caption)
                                .opacity(0.9)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)

                    Button {
                        OnboardingStore.complete(withSampleExperience: false)
                        onComplete()
                    } label: {
                        VStack(spacing: 6) {
                            Text("从空白开始")
                                .font(.headline)
                            Text("自行添加商品，开始真实摆摊")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .alert("加载失败", isPresented: $showSeedError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("示例商品加载失败，请重试或选择从空白开始。")
        }
    }
}

#Preview {
    WelcomeView(onComplete: {})
        .modelContainer(for: Product.self, inMemory: true)
}
