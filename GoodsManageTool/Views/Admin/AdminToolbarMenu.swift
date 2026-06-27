import SwiftUI

struct AdminToolbarMenu: View {
    @Environment(AdminAuthStore.self) private var authStore
    @State private var showingChangePassword = false
    var hasSampleProducts = false
    var onClearSamples: (() -> Void)?

    var body: some View {
        Menu {
            if hasSampleProducts, let onClearSamples {
                Button("清除示例数据", role: .destructive) {
                    onClearSamples()
                }
            }
            Button("修改密码") {
                showingChangePassword = true
            }
            Button("锁定", role: .destructive) {
                authStore.lock()
            }
        } label: {
            Image(systemName: "lock.open.fill")
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView(authStore: authStore)
        }
    }
}
