import SwiftUI

enum MainTab: Hashable {
    case todo
    case timer
}

struct ContentView: View {
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.classic.rawValue
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var selectedTab: MainTab = .timer
    @State private var hasLoadedTodo = false

    
    
    
    @EnvironmentObject private var achievementStore: AchievementStore
    
    private var theme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .classic }
    
    var body: some View {
        TabView (selection: $selectedTab) {
            
            NavigationStack {
                Group {
                    if hasLoadedTodo || selectedTab == .todo {
                        TodoListView(theme: theme)
                            .onAppear {
                                hasLoadedTodo = true
                            }
                        
                        
                            .navigationTitle("To Do")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button { showAchievements = true } label: {
                                        Image(systemName: "trophy.fill")
                                            .foregroundStyle(theme.iconColor)
                                    }
                                }
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button { showSettings = true } label: {
                                        Image(systemName: "gearshape")
                                            .foregroundStyle(theme.iconColor)
                                    }
                                }
                            }
                            .toolbarBackground(theme.chromeColor, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbarColorScheme(.dark, for: .navigationBar)
                            .tint(.white)
                        
                        
                    }  else {
                        ZStack {
                            theme.background.ignoresSafeArea()
                            ProgressView()
                        }
                                .navigationTitle("To Do")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .topBarLeading) {
                                        Button { showAchievements = true } label: {
                                            Image(systemName: "trophy.fill")
                                                .foregroundStyle(theme.iconColor)
                                        }
                                    }
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button { showSettings = true } label: {
                                            Image(systemName: "gearshape")
                                                .foregroundStyle(theme.iconColor)
                                        }
                                    }
                                }
                                .toolbarBackground(theme.chromeColor, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                                .toolbarColorScheme(.dark, for: .navigationBar)
                                .tint(.white)
                        }
                    }
                }
                .tabItem { Label("To Do", systemImage: "checklist") }
                .tag(MainTab.todo)
                
                TimerTab(theme: theme, showSettings: $showSettings)
                    .tabItem { Label("Timer", systemImage: "timer") }
                    .tag(MainTab.timer)
            }
        
        .tabViewStyle(.page(indexDisplayMode: .never))
        
     
     
            .toolbarBackground(theme.chromeColor, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
            .tint(.white)
            .sheet(isPresented: $showSettings) {
                NavigationStack { TimerSettings() }
            }
            .sheet(isPresented: $showAchievements) {
                NavigationStack { AchievementsView(theme: theme) }
            }
            
            .overlay(alignment: .top) {
                if let achievementID = achievementStore.newlyUnlockedAchievement {
                    Button {
                        showAchievements = true
                        
                        achievementStore.clearNewlyUnlockedAchievements()
                        
                    } label: {
                        
                        AchievementBanner (
                            achievementID: achievementID,
                            theme: theme
                        )
                        .padding(.top, 14)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            achievementStore.clearNewlyUnlockedAchievements()
                        }
                    }
                    
                }
            }
            .overlay(alignment: .bottomTrailing) {
                AmbientMuteButton(theme: theme)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                    .offset(y: 12)
                    .offset(x: -8)
            }
        
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: achievementStore.newlyUnlockedAchievement)
        }
    
    
    
    private var TabButtons: some View {
        HStack {
            VStack {
                Image(systemName: "checklist")
                Text("To Do")
                    .font(.caption)
                
            }
            .onTapGesture {
                selectedTab = .todo
            }
        }
    }
    }
    
    private struct TimerTab: View {
        let theme: AppTheme
        @Binding var showSettings: Bool
        
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    theme.background.ignoresSafeArea()
                    
                    if theme.showsRainOverlay {
                        RainOverlay()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    
                    countdownTimer(theme: theme)
                        .padding(.top, 10)
                    
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                        //                        .font(.system(size: 18, weight: .semibold))
                        //                        .foregroundStyle(.white)
                        //                        .padding(12)
                        //                        .background(.white.opacity(0.14))
                            .foregroundStyle(theme.iconColor)
                    }
                    .padding(.trailing, 18)
                    .padding(.top, geo.safeAreaInsets.top + 10)
                }
            }
        }
    }
    
    private struct AchievementBanner: View {
        let achievementID: AchievementID
        let theme: AppTheme
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "rosette")
                    .font(.title2)
                    .foregroundStyle(theme.focusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(achievementID.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(achievementID.detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    
                }
                Spacer()
            }
            .padding(24)
            .background(.black.opacity(0.82))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.focusColor.opacity(0.45), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
        }
    }



private struct AmbientMuteButton: View {
    let theme: AppTheme
    @AppStorage("AmbientEnabled") private var ambientEnabled: Bool = true
    @AppStorage("ambientLocallyMuted") private var ambientLocallyMuted: Bool = false
    
    var body: some View {
        if ambientEnabled, theme.ambientSound != nil {
            Button {
                ambientLocallyMuted.toggle()
            } label: {
                Image(systemName: ambientLocallyMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(theme.controlTint)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
                    
            }
            .buttonStyle(.plain)
        }
    }
}

