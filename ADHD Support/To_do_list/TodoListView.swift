
//  TodoListView.swift
//  ADHD Support


import SwiftUI

struct TodoListView: View {
   @EnvironmentObject private var store: TodoStorage
   @EnvironmentObject private var achievementStore: AchievementStore


   let theme: AppTheme
    
//    @State private var draftTitle: String = ""
//    @State private var chosenPriorityOverride: Priority? = nil
    @State private var showClearCompletedAlert = false
    

   var body: some View {
       ZStack {
           //background is its own small view so SwiftUI can decide
           //whether the background actually changed before rebuilding it (.equatable)
           TodoBackground(theme: theme)
               .equatable()
           
   

           VStack(spacing: 0) {
               //composer owns the typing state
               //prevents every keystroke from refreshing the whole task list
               TodoComposer(theme: theme, onAddTask: addTask)
                   .padding(.horizontal, 16)
                   .padding(.top, 12)
                   .padding(.bottom, 4)
               
               
               if store.sections.isEmpty{
                   TodoEmptyState(theme: theme)
                       .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
               }

               //list receives the finished task sections to display
               TodoTaskList(
                   sections: store.sections,
                   theme: theme,
                   onToggle: { task in
                       store.toggleDone(for: task, achievementStore: achievementStore)
                   },
                   onSetPriorityOverride: { task, newOverride in
                       store.setUserPriorityOverride(newOverride, for: task)
                   },
                   onSetDone: { task, isDone in
                       store.setDone(isDone, for: task, achievementStore: achievementStore)
                   },
                   onSetInProgress: { task, inProgress in
                       store.setInProgress(inProgress, for: task)
                   },
                   onSetDueDate: { task, date in
                       store.setDueDate(date, for: task)
                   },
                   onSetPlannedDate: { task, date in
                       store.setPlannedDate(date, for: task)
                   },
                   onDelete: { offsets, sectionTasks in
                       store.deleteTasks(at: offsets, in: sectionTasks)
                   }
               )
               .equatable()
           }
       }
       .toolbar {
           ToolbarItem(placement: .topBarTrailing) {
               Button { showClearCompletedAlert = true } label: {
                   Image(systemName: "trash")
               }
           }
       }
       .alert("Delete Completed Tasks?", isPresented: $showClearCompletedAlert) {
           Button("Cancel", role: .cancel) { }
           Button("Delete", role: .destructive) {
               store.clearCompleted()
           }
       } message: {
           Text("Are you sure you want to delete all completed tasks?")
       }
   }
    

   // MARK: - Actions
   private func addTask(title: String, chosenPriorityOverride: Priority?) {
       store.addTask(
           title: title,
           userPriorityOverride: chosenPriorityOverride,
           achievementStore: achievementStore
       )
   }
}


// MARK: - Background
private struct TodoBackground: View, Equatable {
   let theme: AppTheme

   var body: some View {
       theme.background
   }
}


// MARK: - Composer
private struct TodoComposer: View {
   let theme: AppTheme
   let onAddTask: (String, Priority?) -> Void

   //these states stay here instead of in TodoListView
   //so typing changes this view only not the whole screen
   @State private var draftTitle = ""
   @State private var chosenPriorityOverride: Priority? = nil

   var body: some View {
       VStack(alignment: .leading, spacing: 10) {
           TextField(
               "",
               text: $draftTitle,
               prompt: Text("Add a task...").foregroundStyle(.white)
           )
           .padding(.horizontal, 10)
           .frame(minHeight: 65)
           .background(.white.opacity(0.08))
           .clipShape(RoundedRectangle(cornerRadius: 10))
           .contentShape(Rectangle())
           .font(.largeTitle)
           .onSubmit { submit() }
           .submitLabel(.done)
           .foregroundStyle(.white)

           HStack(spacing: 12) {
               Menu {
                   Button { chosenPriorityOverride = nil } label: { Text("Auto") }
                   Divider()

                   ForEach(Priority.allCases) { priority in
                       Button { chosenPriorityOverride = priority } label: {
                           Text(priority.title)
                       }
                   }
               } label: {
                   Label(chosenPriorityOverride?.title ?? "Auto", systemImage: "flag.fill")
               }
               .foregroundColor(.white)

               Button(action: submit) {
                   Label("Add", systemImage: "plus.circle.fill")
                       .foregroundColor(.white)
               }
           }
       }
       .padding(.vertical, 6)
   }

   private func submit() {
       let cleanTitle = draftTitle.trimmed
       guard !cleanTitle.isEmpty else { return }

       //sends the finished task up to TodoListView.
       onAddTask(cleanTitle, chosenPriorityOverride)

       //clears the input after adding the task.
       draftTitle = ""
       chosenPriorityOverride = nil
   }
}

private struct TodoEmptyState: View {
    let theme: AppTheme
    
    var body: some View {
        Text("No tasks yet. Add one above to get started.")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .foregroundColor(theme.focusColor)
    }
}

// MARK: - Task list
private struct TodoTaskList: View, Equatable {
   let sections: [TodoStorage.TodoSection]
   let theme: AppTheme
   let onToggle: (TodoItem) -> Void
   let onSetPriorityOverride: (TodoItem, Priority?) -> Void
    let onSetDone: (TodoItem, Bool) -> Void
    let onSetInProgress: (TodoItem, Bool) -> Void
    let onSetDueDate: (TodoItem, Date?) -> Void
    let onSetPlannedDate: (TodoItem, Date?) -> Void
   let onDelete: (IndexSet, [TodoItem]) -> Void

   //this tells SwiftUI what counts as a real visual change for this view
   //if task sections and theme are same -> list should look the same == no update
   static func == (lhs: TodoTaskList, rhs: TodoTaskList) -> Bool {
       lhs.sections == rhs.sections && lhs.theme == rhs.theme
   }
    // lhs = the old TodoTaskList
    // rhs = the new TodoTaskList
    //
    // lhs.sections == rhs.sections checks whether the task data changed
    // lhs.theme == rhs.theme checks whether the list styling changed

   var body: some View {
       List {
           ForEach(sections) { section in
               Section {
                   ForEach(section.tasks) { task in
                       TodoRow(
                           task: task,
                           theme: theme,
                           onToggle: { onToggle(task) },
                           onSetPriorityOverride: { newOverride in
                               onSetPriorityOverride(task, newOverride)
                           },
                           onSetDone: { isDone in
                               onSetDone(task, isDone)
                           },
                           onSetInProgress: { inProgress in
                               onSetInProgress(task, inProgress)
                           },
                           onSetDueDate: { date in
                               onSetDueDate(task, date)
                           },
                           onSetCompletedDate: { date in
                               onSetPlannedDate(task, date)
                           }
                       )
                       //SwiftUI can skip rebuilding this row if the row data did not change.
                       .equatable()
                       .clearRowStyle()
                   }
                   .onDelete { offsets in
                       onDelete(offsets, section.tasks)
                   }
               } header: {
                   Text(section.title)
                       .font(.headline)
                       .foregroundStyle(.white)
               }
               .clearSectionStyle()
           }
       }
       .scrollContentBackground(.hidden)
       .listStyle(.plain)
       .tint(theme.focusColor)
   }
}


// MARK: - Helpers
private extension View {
   func clearRowStyle() -> some View {
       self
           .listRowBackground(Color.clear)
           .listRowSeparator(.hidden)
   }

   func clearSectionStyle() -> some View {
       self
           .listRowBackground(Color.clear)
           .listRowSeparator(.hidden)
   }
}

private extension String {
   var trimmed: String {
       trimmingCharacters(in: .whitespacesAndNewlines)
   }
}
