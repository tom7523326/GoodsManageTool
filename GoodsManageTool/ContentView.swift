import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasCompletedOnboarding = OnboardingStore.hasCompletedOnboarding

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                WelcomeView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .onAppear {
            OnboardingStore.migrateLegacyInstallIfNeeded()
            if OnboardingStore.hasCompletedOnboarding {
                hasCompletedOnboarding = true
            }
            SeedData.prepareOnLaunch(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Product.self, SaleRecord.self, StockRecord.self], inMemory: true)
}
