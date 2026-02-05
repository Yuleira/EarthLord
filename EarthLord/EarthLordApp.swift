//
//  EarthLordApp.swift
//  EarthLord
//
//  Created by Yu Lei on 23/12/2025.
//

import SwiftUI
import GoogleSignIn

@main
struct EarthLordApp: App {
    
    /// Language manager for locale injection at root level
    @StateObject private var languageManager = LanguageManager.shared

    init() {
        // Validate configuration (DEBUG only)
        AppConfig.validateConfiguration()
        // Start StoreKit 2 transaction listener at launch (for real-device IAP)
        _ = StoreKitManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Late-Binding Localization: inject locale at the very root
                .environment(\.locale, languageManager.currentLocale)
                .id(languageManager.refreshID)
                // Google Sign-In URL callback
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

/// App launch phase state machine
private enum LaunchPhase {
    case splash      // Playing cinematic video
    case mainApp     // Auth / Main tab visible
}

/// Root container view — splash → auth/main → onboarding (first-run)
struct ContentView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var launchPhase: LaunchPhase = .splash
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // Main app layer (always mounted so auth state listener runs)
            mainAppView
                .opacity(launchPhase == .mainApp ? 1 : 0)

            // Splash layer (on top, removed after fade)
            if launchPhase == .splash {
                SplashVideoView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        launchPhase = .mainApp
                    }
                    // Trigger onboarding after splash if authenticated + first run
                    if authManager.isAuthenticated && !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showOnboarding = true
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var mainAppView: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            // Post-splash: if user logs in for the first time, show onboarding
            if isAuth && !hasCompletedOnboarding && launchPhase == .mainApp {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        #if DEBUG
        .onAppear {
            print("🏠 [ContentView] Locale: \(LanguageManager.shared.currentLocale.identifier)")
        }
        #endif
    }
}
