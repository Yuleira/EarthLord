//
//  RootView.swift
//  EarthLord
//
//  Created by Yu Lei on 24/12/2025.
//

import SwiftUI

/// 根视图：控制启动页、登录页与主界面的切换
///
/// 页面流转逻辑：
/// 1. 启动时显示 SplashView，同时检查会话状态
/// 2. 启动完成后根据 isAuthenticated 显示不同页面：
///    - 已登录 → MainTabView
///    - 未登录 → AuthView
/// 3. 监听认证状态变化，自动切换页面
struct RootView: View {
    /// 认证管理器（使用 @StateObject 确保状态响应）
    @StateObject private var authManager = AuthManager.shared
    /// 语言管理器
    @StateObject private var languageManager = LanguageManager.shared

    /// 启动页是否完成
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 启动页：显示 Logo 和加载动画，同时检查会话
                SplashView(authManager: authManager, isFinished: $splashFinished)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // 已登录且完成所有流程 → 主界面
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // 未登录或需要设置密码 → 认证页面
                // 注意：只保留一个 AuthView 实例，避免状态变化导致重新创建
                AuthView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: splashFinished)
        .animation(.easeInOut(duration: 0.4), value: authManager.isAuthenticated)
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                    .scaleEffect(1.5)

                Text("加载中...".localized)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }
}

// MARK: - 环境对象包装器
/// 在 App 入口处使用，确保语言变化时整个视图树刷新
struct LocalizationWrapper<Content: View>: View {
    @StateObject private var languageManager = LanguageManager.shared
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .id(languageManager.refreshID)
    }
}

#Preview {
    RootView()
}
