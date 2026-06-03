import SwiftUI

struct TodoRow: View, Equatable {
    let task: TodoItem
    let theme: AppTheme
    let onToggle: () -> Void
    
    

    //WHY: row needs a way to send changes back up
    //HOW: parent passes in a closure that updates storage
    let onSetPriorityOverride: (Priority?) -> Void
    
    
    let onSetDone: (Bool) -> Void
    let onSetInProgress: (Bool) -> Void
    let onSetDueDate: (Date?) -> Void
    let onSetPlannedDate: (Date?) -> Void

    //WHY: task is a value, so we keep local selection state for the picker
    //HOW: nil means Auto, otherwise it is the user override
    @State private var selectedOverride: Priority?
    
    @State private var showPlannerEditor = false

    static func == (lhs: TodoRow, rhs: TodoRow) -> Bool {
        lhs.task == rhs.task && lhs.theme == rhs.theme
    }
    
    init(
        task: TodoItem,
        theme: AppTheme,
        onToggle: @escaping () -> Void,
        onSetPriorityOverride: @escaping (Priority?) -> Void,
        onSetDone: @escaping (Bool) -> Void,
        onSetInProgress: @escaping (Bool) -> Void,
        onSetDueDate: @escaping (Date?) -> Void,
        onSetPlannedDate: @escaping (Date?) -> Void
    ) {
        self.task = task
        self.theme = theme
        self.onToggle = onToggle
        self.onSetPriorityOverride = onSetPriorityOverride
        self.onSetDone = onSetDone
        self.onSetInProgress = onSetInProgress
        self.onSetDueDate = onSetDueDate
        self.onSetPlannedDate = onSetPlannedDate
        _selectedOverride = State(initialValue: task.userPriorityOverride)
        
        
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isDone ? .secondary : theme.focusColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .white.opacity(0.6) : .white)

                //what the app is actually using
                Text("Priority: \(task.effectivePriority.title)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                Text(plannerSummary)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))

                // WHY: if the user manually overrides priority, the auto guess is just noise
                // HOW: only show auto guess when override is nil
                if task.userPriorityOverride == nil {
                    let pct = Int((task.priorityConfidence * 100).rounded())
                    Text("Auto: \(task.predictedPriority.title) (\(pct)%)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }


                //MARK: - priority picker
                //WHY: user can override, or return to Auto
                //HOW: Auto is nil, other options are Priority values
                Picker("Priority", selection: $selectedOverride) {
                    Text("Auto").tag(Priority?.none)
                    ForEach(Priority.allCases) { p in
                        Text(p.title).tag(Optional(p))
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.focusColor)
                .onChange(of: selectedOverride) { _, newValue in
                    onSetPriorityOverride(newValue)
                }
            }
            Spacer()
            //MARK: - play button
            
            Button {
                showPlannerEditor = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(theme.focusColor)
            }
            
            if !task.isDone {
                NavigationLink {
                    TaskPomodoroView(task: task, theme: theme)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(theme.focusColor)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPlannerEditor) {
            TaskPlannerEditorView(task: task, theme: theme, onSetDone: onSetDone, onSetInProgress: onSetInProgress, onSetDueDate: onSetDueDate, onSetPlannedDate: onSetPlannedDate)
        }
    }
    
    //step 5
    private var plannerSummary: String {
        var parts = [task.plannerStatus]
        
        if let plannedDate = task.plannedDate {
            parts.append("Plan: \(plannedDate.plannerShortText)")
        }
        
        if let dueDate = task.dueDate {
            parts.append("Due: \(dueDate.plannerShortText)")
        }
        
        return parts.joined(separator: " | ")
    }
} // todorow struct ends

private extension Date {
    var plannerShortText: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

