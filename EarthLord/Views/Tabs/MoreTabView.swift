//
//  MoreTabView.swift
//  EarthLord
//
//  Created by Yu Lei on 24/12/2025.
//

import SwiftUI

struct MoreTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showDeleteAccountSheet = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // 设置
                Section("设置".localized) {
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        HStack {
                            Label("语言".localized, systemImage: "globe")
                            Spacer()
                            Text(languageManager.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("开发者工具".localized) {
                    NavigationLink {
                        SupabaseTestView()
                    } label: {
                        Label("Supabase 连接测试".localized, systemImage: "network")
                    }
                }

                Section("账户".localized) {
                    // 退出登录
                    Button {
                        Task {
                            await authManager.signOut()
                        }
                    } label: {
                        Label("退出登录".localized, systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // 删除账户放在底部单独的 Section
                Section {
                    Button(role: .destructive) {
                        print("📱 [删除账户] 用户点击删除账户按钮")
                        showDeleteAccountSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除账户".localized)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("删除账户后，您的所有数据将被永久删除且无法恢复。".localized)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("更多".localized)
            .id(languageManager.refreshID)
            .sheet(isPresented: $showDeleteAccountSheet) {
                DeleteAccountConfirmView(
                    isPresented: $showDeleteAccountSheet,
                    onError: { error in
                        deleteErrorMessage = error
                        showDeleteError = true
                    }
                )
            }
            .alert("删除失败", isPresented: $showDeleteError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
}

// MARK: - 删除账户确认视图
struct DeleteAccountConfirmView: View {
    @Binding var isPresented: Bool
    var onError: (String) -> Void

    @StateObject private var authManager = AuthManager.shared
    @State private var confirmText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let requiredText = "删除"

    private var canDelete: Bool {
        confirmText == requiredText
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 警告图标
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)

                // 标题
                Text("确认删除账户")
                    .font(.title2)
                    .fontWeight(.bold)

                // 说明文字
                VStack(spacing: 12) {
                    Text("此操作不可撤销！")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Text("删除账户后，以下数据将被永久删除：")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("您的个人资料信息", systemImage: "person.crop.circle")
                        Label("所有游戏进度和数据", systemImage: "gamecontroller")
                        Label("登录凭证和认证信息", systemImage: "key")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // 输入确认框
                VStack(alignment: .leading, spacing: 8) {
                    Text("请输入「\(requiredText)」以确认操作：")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("请输入\(requiredText)", text: $confirmText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 32)

                Spacer()

                // 按钮组
                VStack(spacing: 12) {
                    // 删除按钮
                    Button {
                        print("📱 [删除账户] 用户确认删除，开始执行删除操作")
                        Task {
                            do {
                                try await authManager.deleteAccount()
                                print("📱 [删除账户] 删除成功，关闭确认页面")
                                isPresented = false
                            } catch {
                                print("📱 [删除账户] 删除失败: \(error.localizedDescription)")
                                onError(authManager.errorMessage ?? "删除账户失败，请稍后重试")
                                isPresented = false
                            }
                        }
                    } label: {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("确认删除")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canDelete ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canDelete || authManager.isLoading)

                    // 取消按钮
                    Button {
                        print("📱 [删除账户] 用户取消删除操作")
                        isPresented = false
                    } label: {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                print("📱 [删除账户] 显示删除确认页面")
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 语言设置视图
struct LanguageSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        print("🌐 [语言设置] 用户选择: \(language.rawValue)")
                        languageManager.setLanguage(language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("切换语言后界面将立即更新".localized)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("语言设置".localized)
        .navigationBarTitleDisplayMode(.inline)
        .id(languageManager.refreshID)
    }
}

#Preview {
    MoreTabView()
}

#Preview("Delete Confirm") {
    DeleteAccountConfirmView(
        isPresented: .constant(true),
        onError: { _ in }
    )
}

#Preview("Language Settings") {
    NavigationStack {
        LanguageSettingsView()
    }
}
