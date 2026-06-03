//
//  Planner.swift
//  ADHD Support
//
//  Created by Peter McMichael on 6/2/26.
//

import SwiftUI

struct TaskPlannerEditorView: View {
    let task: TodoItem
    let theme: AppTheme
    let onSetDone: (Bool) -> Void
    let onSetInProgress: (Bool) -> Void
    let onSetDueDate: (Date?) -> Void
    let onSetPlannedDate: (Date?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDone: Bool
    @State private var isInProgress: Bool
    @State private var hasPlannedDate: Bool
    @State private var plannedDate: Date
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    init(
        task: TodoItem,
        theme: AppTheme,
        onSetDone: @escaping (Bool) -> Void,
        onSetInProgress: @escaping (Bool) -> Void,
        onSetDueDate: @escaping (Date?) -> Void,
        onSetPlannedDate: @escaping (Date?) -> Void
    ) {
        self.task = task
        self.theme = theme
        self.onSetDone = onSetDone
        self.onSetInProgress = onSetInProgress
        self.onSetDueDate = onSetDueDate
        self.onSetPlannedDate = onSetPlannedDate
        
        _isDone = State(initialValue: task.isDone)
        _isInProgress = State(initialValue: task.isInProgress)
        _hasPlannedDate = State(initialValue: task.plannedDate != nil)
        _plannedDate = State(initialValue: task.plannedDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Toggle("Finished", isOn: $isDone)
                        .onChange(of: isDone) { _, newValue in
                            onSetDone(newValue)
                            
                            if newValue {
                                isInProgress = false
                            }
                        }
                    Toggle("In Progress", isOn: $isInProgress)
                        .disabled(isDone)
                        .onChange(of: isInProgress) { _, newValue in
                            onSetInProgress(newValue)
                            
                            if newValue {
                                isDone = false
                            }
                        }
                }
                
                Section("Planner Dates") {
                    Toggle("Planned date", isOn: $hasPlannedDate)
                        .onChange(of: hasPlannedDate) { _, isEnabled in
                            onSetPlannedDate(isEnabled ? plannedDate : nil)
                        }
                    
                    if hasPlannedDate {
                        DatePicker("Start", selection: $plannedDate, displayedComponents: .date)
                            .onChange(of: plannedDate) { _, newValue in
                                onSetPlannedDate(newValue)
                            }
                    }
                    
                    Toggle("Due Date", isOn: $hasDueDate)
                        .onChange(of: hasDueDate) { _, isEnabled in
                            onSetDueDate(isEnabled ? dueDate : nil)
                        }
                    
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                            .onChange(of: dueDate) { _, newValue in
                                onSetDueDate(newValue)
                            }
                    }
                    
                }
            }
            .navigationTitle(task.title)
            .tint(theme.focusColor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

