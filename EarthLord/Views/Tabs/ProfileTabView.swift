//
//  ProfileTabView.swift
//  EarthLord
//
//  Created by Yu Lei on 24/12/2025.
//

import SwiftUI
import Supabase

/// 个人页面
/// 显示用户信息、统计数据和账号操作
struct ProfileTabView: View {
    /// 认证管理器（使用 @ObservedObject 确保状态响应）
    @ObservedObject private var authManager = AuthManager.shared

    /// 是否显示退出确认弹窗
    @State private var showLogoutAlert = false

    /// 是否正在退出
    @State private var isLoggingOut = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 用户信息区域
                Section {
                    userInfoCard
                }

                // MARK: - 统计数据（待实现数据获取后显示）
                // TODO: 从数据库获取用户统计数据后取消注释
                // Section("我的数据") {
                //     Label("领地数量: \(territoryCount)", systemImage: "flag.fill")
                //     Label("总面积: \(totalArea) m²", systemImage: "square.dashed")
                //     Label("发现 POI: \(poiCount)", systemImage: "mappin.circle.fill")
                // }

                // MARK: - 设置选项
                Section("设置".localized) {
                    NavigationLink {
                        Text("账号安全（待开发）".localized)
                    } label: {
                        Label("账号安全".localized, systemImage: "shield.fill")
                    }

                    NavigationLink {
                        Text("通知设置（待开发）".localized)
                    } label: {
                        Label("通知设置".localized, systemImage: "bell.fill")
                    }

                    NavigationLink {
                        Text("关于我们（待开发）".localized)
                    } label: {
                        Label("关于我们".localized, systemImage: "info.circle.fill")
                    }
                }

                // MARK: - 退出登录
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Label("退出登录".localized, systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                            if isLoggingOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(isLoggingOut)
                }
            }
            .navigationTitle("个人".localized)
            .alert("确认退出".localized, isPresented: $showLogoutAlert) {
                Button("取消".localized, role: .cancel) { }
                Button("退出".localized, role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("确定要退出登录吗？退出后需要重新登录。".localized)
            }
        }
    }

    // MARK: - 用户信息卡片
    private var userInfoCard: some View {
        HStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
                    // TODO: 加载网络头像
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // 用户名
                Text(username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                // 邮箱
                Text(email)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                // 用户ID（可选显示）
                if let userId = authManager.currentUser?.id {
                    Text("ID: \(userId.uuidString.prefix(8))...")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            Spacer()

            // 编辑按钮
            Button {
                // TODO: 打开编辑资料页面
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(ApocalypseTheme.primary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 计算属性

    /// 用户名
    private var username: String {
        // 优先从 userMetadata 获取用户名
        if let name = authManager.currentUser?.userMetadata["username"]?.stringValue, !name.isEmpty {
            return name
        }
        // 其次使用邮箱前缀
        if let email = authManager.currentUser?.email {
            return String(email.split(separator: "@").first ?? "幸存者")
        }
        return "幸存者"
    }

    /// 邮箱
    private var email: String {
        authManager.currentUser?.email ?? "未设置邮箱"
    }

    /// 头像URL
    private var avatarUrl: String? {
        authManager.currentUser?.userMetadata["avatar_url"]?.stringValue
    }

    // MARK: - 方法

    /// 执行退出登录
    private func performLogout() {
        isLoggingOut = true
        Task {
            await authManager.signOut()
            // signOut 完成后，authManager.isAuthenticated 会变为 false
            // RootView 会自动切换到登录页面
            await MainActor.run {
                isLoggingOut = false
            }
        }
    }
}

#Preview {
    ProfileTabView()
}
