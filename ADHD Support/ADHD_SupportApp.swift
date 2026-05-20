//
//  ADHD_SupportApp.swift
//  ADHD Support
//
//  Created by Peter McMichael on 11/18/25.
//

import SwiftUI

@main
struct ADHD_SupportApp: App {
//    @StateObject private var todoStorage = TodoStorage()
//    @StateObject private var achievementStore = AchievementStore()
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
        }
    }
}


private struct SplashLoadingView: View {
    let progress: Double
    let message: String
    
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
            
            Text(message)
                .font(.caption)
                .foregroundColor(.cyan.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private struct SplashView: View {
    @State private var loadingProgress = 0.0
    @State private var loadingMessage = "Loading..." //display message
    @State private var didStartLoading = false
    @State private var todoStorage:  TodoStorage?
    @State private var achievementStore: AchievementStore?
    
    var body: some View {
        if let todoStorage, let achievementStore {
            ContentView()
                .environmentObject(todoStorage)
                .environmentObject(achievementStore)
        } else {
            SplashLoadingView(progress: loadingProgress, message: loadingMessage)
                .task{
                    guard !didStartLoading else { return }
                    didStartLoading = true
                    await loadForStartup()
                    
                    try? await Task.sleep(for: .milliseconds(200))
                    
                }
        }
    }
    
    @MainActor
    private func loadForStartup() async { //asnyc makes loadingProgress follow actual loading progress
        loadingMessage = "Starting app..."
        loadingProgress = 0.05 //changes loadingProgress based on how far progrss is
        try? await Task.sleep(for: .milliseconds(400)) //stop this task allow next loading message to be shown
        
        loadingMessage = "Loading tasks... "
        let loadedTodoStorage = TodoStorage() //load tasks
        loadedTodoStorage.loadForStartup()
        loadingProgress = 0.35
        try? await Task.sleep(for: .milliseconds(400))
        
        loadingMessage = "Loading achievements..."
        let loadedAchievementStore = AchievementStore()
        loadedAchievementStore.loadForStartup()
        loadingProgress = 0.65
        try? await Task.sleep(for: .milliseconds(400))
        
        loadingMessage = "Loading task model..."
        _ = TaskClassifier.shared //load the ML model for which category a task fits into.
        loadingProgress = 0.82
        try? await Task.sleep(for: .milliseconds(600))
        
        
        loadingMessage = "Loading priority model..."
        _ = PrioritiesClassifier.shared // load the ML model for which priority a task fits into.
        loadingProgress = 1.0
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(600))
//
        todoStorage  = loadedTodoStorage
        achievementStore = loadedAchievementStore
    }
}



