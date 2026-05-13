//
//  timer_settings.swift
//  ADHD Support
//
//  Created by Peter McMichael on 12/16/25.
//

import SwiftUI


//settings screen keeps all timer preferences in one place
struct TimerSettings: View {
    //MARK: - properties
    //using appstorage here means the toggles automatically sync with the timer view
    @EnvironmentObject private var todoStorage: TodoStorage
    
    @AppStorage("moveTasksDown") private var moveTasksDown: Bool = true
    
    
    @AppStorage("vibrateOnSessionEnd") private var vibrateOnSessionEnd: Bool = true
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd: Bool = true
    @AppStorage("autoStartNextSession") private var autoStartNextSession: Bool = false
    @AppStorage("AmbientEnabled") private var ambientEnabled: Bool = true
    
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.classic.rawValue
    
    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .classic},
            set: { appThemeRaw = $0.rawValue }
            )
    }
    
    private var moveTasksDownBinding: Binding<Bool> {
        
        Binding(
        get: { moveTasksDown },
        
        set: { newValue in
            moveTasksDown = newValue
            todoStorage.setMoveTasksDown(newValue)
        }
        )
    }
   
    //MARK: - body
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Theme", selection: selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            
            
            
            Section(header: Text("Session End Feedback")) {
                Toggle("Vibrate when session ends", isOn: $vibrateOnSessionEnd)
                Toggle("Play sound when session ends", isOn: $soundOnSessionEnd)
                //these options matter for sensory needs so users can turn feedback up or down
            }
           
            Section(header: Text("Timer Behavior")) {
                Toggle("Automatically start next session", isOn: $autoStartNextSession)
                //removes one decision between blocks which can help adhd users stay in flow
            }
            Section(header: Text("Ambience")) {
                Toggle("Play ambient sound", isOn: $ambientEnabled)
            }
            Section(header: Text("To Do List")) {
                Toggle("Move completed tasks to the bottom", isOn: moveTasksDownBinding)
            }
           
            Section(footer: Text("Sounds and vibration still respect the iPhone mute switch and system Focus settings.")) {
                EmptyView()
            }
            

        }
        
        .navigationTitle("Settings")
    }
}


    

