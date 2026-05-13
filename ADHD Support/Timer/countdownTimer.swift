//
//  Timer.swift
//  ADHD Support
//
//  Created by Peter McMichael on 11/18/25.
//



import SwiftUI

struct countdownTimer: View {
    
    private let initialFocusMinutes: Int
    private let initialBreakMinutes: Int
    
    //MARK: - recomendation
    
    private let recommendedFocusMinutes: Int?
    private let recommendedBreakMinutes: Int?
    private let recommendedLabel: String?
    
    
    
    
    let theme: AppTheme
    
    @State private var timerActive = false
    @State private var focusMinutes: Int
    @State private var breakMinutes: Int
    @State private var sessionType: SessionType = .focusTime
    @State private var isPressed = false
    //    @State private var localMute: Bool = false
    @AppStorage("ambientLocallyMuted") private var localMute: Bool = false //change to global
    
    @AppStorage("vibrateOnSessionEnd") private var vibrateOnSessionEnd: Bool = true
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd: Bool = true
    @AppStorage("autoStartNextSession") private var autoStartNextSession: Bool = false
    @AppStorage("AmbientEnabled") private var ambientEnabled: Bool = true
    
    
    init(
        theme: AppTheme,
        initialFocusMinutes: Int = 25,
        initialBreakMinutes: Int = 5,
        recommendedFocusMinutes: Int? = nil,
        recommendedBreakMinutes: Int? = nil,
        recommendedLabel: String? = nil
    ) {
        self.theme = theme
        
        self.initialFocusMinutes = initialFocusMinutes
        self.initialBreakMinutes = initialBreakMinutes
        
        self.recommendedFocusMinutes = recommendedFocusMinutes
        self.recommendedBreakMinutes = recommendedBreakMinutes
        self.recommendedLabel = recommendedLabel
        
        _focusMinutes = State(initialValue: initialFocusMinutes)
        _breakMinutes = State(initialValue: initialBreakMinutes)
        _timeRemaining = State(initialValue: initialFocusMinutes * 60)
    }
    
    enum SessionType {
        case focusTime
        case breakTime
        
        var displayName: String {
            switch self {
            case .focusTime:
                return "Focus"
            case .breakTime:
                return "Break"
            }
        }
    }
    
    private var sessionColor: Color {
        sessionType == .focusTime ? theme.focusColor : theme.breakColor
    }
    
    private var totalSeconds: Int {
        switch sessionType {
        case .focusTime:
            return max(focusMinutes, 1) * 60
        case .breakTime:
            return max(breakMinutes, 1) * 60
        }
    }
    
    
    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(totalSeconds)
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var timeRemaining: Int
    
    var body: some View {
        GeometryReader { geo in
            let isHorizontal = geo.size.width > geo.size.height
            
            Group {
                if isHorizontal {
                    HStack (spacing: 28) {
                        timerCircle
                        
                        timerControls
                            .frame(maxWidth: 360)
                        
                    
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 24) {
                        timerCircle
                        
                        timerControls
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
            .onAppear {
                applyAmbience(for: theme)
            }
            .onChange(of: theme) {_, newTheme in
                applyAmbience(for: newTheme)
            }
            .onChange(of: ambientEnabled) { _, _ in //if ambiece is enabled in settings, apply ambience. Not saving when leave app
                applyAmbience(for: theme)
            }
            .onChange(of: localMute) {_,_ in // if mute is in seetings, mute. Not saving when leave app
                applyAmbience(for: theme)
            }
            .onReceive(timer) { _ in
                guard timerActive else { return }
                
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timerActive = false
                    toggleSession()
                    giveEndOfSessionFeedback()
                    
                    if autoStartNextSession {
                        timerActive = true
                    }
                }
            }
            .onChange(of: focusMinutes) {_, newValue in
                guard !timerActive, sessionType == .focusTime else { return }
                timeRemaining = newValue * 60
            }
            .onChange(of: breakMinutes) {_, newValue in
                guard !timerActive, sessionType == .breakTime else { return }
                timeRemaining = newValue * 60
            }
        }
        
        private var timerCircle: some View {
            ZStack {
                Circle()
                    .fill(
                        Color(red: 83/255, green: 104/255, blue: 114/255)
                    )
                
                    .frame(width: 260, height: 260)
                
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        sessionColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
                VStack {
                    Text("\(sessionType.displayName) Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(sessionColor)
                    
                    Text(formattedTime(seconds: timeRemaining))
                        .foregroundStyle(sessionColor)
                }
                
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            
            .frame(width: 260, height: 260)
            
            .contentShape(Circle())
            
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {
                startOrPause()
            })
        }
        
        private var resetButton: some View {
            HStack(spacing: 20) {
                
                
                Button {
                    resetCurrentSession()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundStyle(theme.focusColor)
                }
            }
        }
        
    @ViewBuilder
    private var recommendationView: some View {
        if let recFocus = recommendedFocusMinutes,
           let recBreak = recommendedBreakMinutes {
            
            
            VStack(spacing: 6) {
                let labelText = recommendedLabel ?? "Recommended"
                Text("\(labelText): \(recFocus)m focus / \(recBreak)m break")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                
                Button {
                    focusMinutes = recFocus
                    breakMinutes = recBreak
                    sessionType = .focusTime
                    timeRemaining = recFocus * 60
                } label: {
                    Text("Apply Recommended") //turn to image later
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(timerActive)
                .opacity(timerActive ? 0.5 : 1.0)
            }
            .padding(.bottom, 8)
        }
    }
    
    private var timerAdjusters: some View {
        VStack(spacing: 16) {
            timerAdjuster(
                title: "Focus (min)",
                value: $focusMinutes,
                range: 1...60
            )
            
            timerAdjuster(
                title: "Break (min)",
                value: $breakMinutes,
                range: 1...60
            )
        }
    }
    
    private var timerControls: some View {
        VStack(spacing: 16) {
            resetButton
            recommendationView
            timerAdjusters
        }
    }
    
    
            
            func formattedTime(seconds: Int) -> String {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return String(format: "%02d:%02d", minutes, remainingSeconds)
            }
            
            private func resetCurrentSession() {
                switch sessionType {
                case .focusTime:
                    timeRemaining = focusMinutes * 60
                case .breakTime:
                    timeRemaining = breakMinutes * 60
                }
                timerActive = false
            }
            
            private func toggleSession() {
                sessionType = (sessionType == .focusTime) ? .breakTime : .focusTime
                resetCurrentSession()
            }
            
            private func startOrPause() {
                if !timerActive && timeRemaining == 0 {
                    resetCurrentSession()
                }
                timerActive.toggle()
            }
            
            private func giveEndOfSessionFeedback() {
                if vibrateOnSessionEnd {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                if soundOnSessionEnd {
                    SoundManager.shared.playEndOfSessionSound()
                }
            }
            
            private func applyAmbience(for theme: AppTheme) {
                guard ambientEnabled, !localMute, let ambient = theme.ambientSound else {
                    SoundManager.shared.stopAmbience()
                    return
                }
                
                SoundManager.shared.startAmbience(name: ambient.name, ext: ambient.ext)
                
            }
            
            @ViewBuilder
            private func timerAdjuster(
                title: String,
                value: Binding<Int>,
                range: ClosedRange<Int>
            ) -> some View {
                
                let sliderValue = Binding<Double>(
                    get: {
                        Double(value.wrappedValue)
                    },
                    set: { newValue in
                        value.wrappedValue = Int(newValue.rounded()) //mins
                    }
                )
                VStack(spacing: 8) {
                    Text(title)
                        .foregroundStyle(theme.focusColor)
                    VStack(spacing: 10) {
                        HStack {
                            Text("\(value.wrappedValue)")
                                .foregroundStyle(theme.focusColor)
                                .padding(.leading, 175)
                            
                            
                            
                            Spacer()
                        }
                        .frame(alignment: .center)
                        
                        Slider(
                            value: sliderValue,
                            in: Double(range.lowerBound)...Double(range.upperBound),
                            step: 1
                        )
                        .tint(theme.focusColor)
                        .disabled(timerActive)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        
  
