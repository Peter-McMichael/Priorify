//
//  ADHD_SupportApp.swift
//  ADHD Support
//
//  Created by Peter McMichael on 11/18/25.
//

import SwiftUI

@main
struct ADHD_SupportApp: App {
    @StateObject private var todoStorage = TodoStorage()
    @StateObject private var achievementStore = AchievementStore()
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = .clear
        tabAppearance.shadowColor = .clear
        
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(todoStorage)
                .environmentObject(achievementStore)
        }
    }
}


private struct SplashLoadingView: View {
    let progress: Double
    
    private var progressPercent: Int {
        Int((progress * 100).rounded())
    }
    
    var body: some View {
        VStack(spacing: 28) {
            Image("splashscreen")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 220)
                .tint(.cyan)
            
            
            Text("\(progressPercent) %")
                .foregroundColor(.cyan)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private struct SplashView: View {
    @State private var isLoading = true
    @State private var loadingProgress = 0.0
    var body: some View {
        if isLoading {
            SplashLoadingView(progress: loadingProgress)
                .task{
                    for step in 1...100 {
                        loadingProgress = Double(step) / 100
                        try? await Task.sleep(for: .milliseconds(15))
                    }
                    isLoading = false
                }
        } else {
            ContentView()
            //is loaded
        }
    }
}

