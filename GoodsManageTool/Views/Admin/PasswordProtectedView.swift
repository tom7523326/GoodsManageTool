import SwiftUI

struct PasswordProtectedView<Content: View>: View {
    @Bindable var authStore: AdminAuthStore
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if authStore.isUnlocked {
                content()
            } else {
                AdminLoginView(authStore: authStore, title: title)
            }
        }
    }
}

private struct AdminLoginView: View {
    @Bindable var authStore: AdminAuthStore
    let title: String

    @State private var password = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 8) {
                Text("\(title)已锁定")
                    .font(.title2.bold())
                Text("请输入管理密码进入")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if authStore.shouldShowDefaultPasswordHint {
                    Text("默认密码：\(AdminAuthStore.defaultPassword)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            SecureField("管理密码", text: $password)
                .textContentType(.password)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .padding(14)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 32)

            if showError {
                Text("密码错误，请重试")
                    .font(.caption)
                    .foregroundStyle(AppTheme.danger)
            }

            Button("解锁") {
                if authStore.unlock(with: password) {
                    showError = false
                    password = ""
                } else {
                    showError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .disabled(password.isEmpty)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .onAppear { isFocused = true }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var authStore: AdminAuthStore

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("当前密码", text: $currentPassword)
                        .keyboardType(.numberPad)
                    SecureField("新密码", text: $newPassword)
                        .keyboardType(.numberPad)
                    SecureField("确认新密码", text: $confirmPassword)
                        .keyboardType(.numberPad)
                } footer: {
                    if authStore.shouldShowDefaultPasswordHint {
                        Text("密码至少 4 位，初始密码为 \(AdminAuthStore.defaultPassword)")
                    } else {
                        Text("密码至少 4 位")
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(AppTheme.danger)
                    }
                }
            }
            .navigationTitle("修改密码")
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
        }
        .presentationDetents([.medium])
    }

    private var canSave: Bool {
        !currentPassword.isEmpty && newPassword.count >= 4 && newPassword == confirmPassword
    }

    private func save() {
        guard newPassword == confirmPassword else {
            errorMessage = "两次输入的新密码不一致"
            return
        }
        guard authStore.changePassword(current: currentPassword, new: newPassword) else {
            errorMessage = "当前密码错误或新密码不符合要求"
            return
        }
        dismiss()
    }
}
