//TodoStorage.swift
//this is the todo list "manager"
//it owns the tasks array, saving/loading,
// and the logic for grouping into sections
//views should not be doing sorting or saving,
// they should call functions in here
//keeping logic here makes it way easier to debug and explain


import Foundation
import Combine


@MainActor
final class TodoStorage: ObservableObject {
    // MARK: - Properties

    @Published private(set) var sections: [TodoSection] = []

    private var tasks: [TodoItem] = []

    //this is the key name we use in userdefaults
    private let storageKey = "todoItemsJSON"
    
    
    private let moveTasksDownKey = "moveTasksDown"
    private var moveTasksDown: Bool

    
    

    //MARK: - init
    init() {
        //load saved tasks when the app starts
        
        moveTasksDown =
        UserDefaults.standard.object(forKey: moveTasksDownKey) as? Bool ?? true
        
    }

    func loadForStartup() {
        loadTasks()

        rebuildSections()
        
    }
    
    func setMoveTasksDown(_ shouldMove: Bool) {
        guard moveTasksDown != shouldMove else { return }
        
        moveTasksDown = shouldMove
        
        UserDefaults.standard.set(shouldMove, forKey: moveTasksDownKey)
        
        rebuildSections()
    }

    //MARK: - actions
    func addTask(title: String, userPriorityOverride: Priority? = nil, achievementStore: AchievementStore? = nil) {
        //clean up the text so "   " does not become a fake task
        let cleanTitle = title.trimmed
        guard !cleanTitle.isEmpty else { return }


        //ask the ml model what category this task probably belongs to
        let categoryPrediction = TaskClassifier.shared.predictCategory(for: cleanTitle)
        
        let priorityPrediction = PrioritiesClassifier.shared.predictPriority(for: cleanTitle)
        let predicted = Priority(rawValue: priorityPrediction.label) ?? .medium


        //build the new task object we will store
        let newTask = TodoItem(
            title: cleanTitle,
            predictedPriority: predicted,
            priorityConfidence: priorityPrediction.confidence,
            categoryLabel: categoryPrediction.label,
            categoryConfidence: categoryPrediction.confidence,
            userPriorityOverride: userPriorityOverride
        )


        //new tasks go first so it feels instant
        tasks.insert(newTask, at: 0)
        //save happens automatically because tasks changed
        
        achievementStore?.recordTaskAdded()
        
        commitChanges()
    }
    
    func setUserPriorityOverride(_ override: Priority?, for task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id}) else { return }
        tasks[index].userPriorityOverride = override
        
        commitChanges()
    }
    
    func setInProgress(_ inProgress: Bool, for task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isInProgress = inProgress
        
        if inProgress {
            tasks[index].isDone = false
        }
        
        commitChanges()
    }
    
    func setDueDate(_ date: Date?, for task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].dueDate = date
        
        commitChanges()
    }
    
    func setPlannedDate(_ date: Date?, for task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].plannedDate = date
        
        commitChanges()
    }
    
    func setDone(_ isDone: Bool, for task: TodoItem, achievementStore: AchievementStore? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let wasDone = tasks[index].isDone
        tasks[index].isDone = isDone
        
        if isDone {
            tasks[index].isInProgress = false
        }
        
        if !wasDone && isDone {
            achievementStore?.recordTaskCompleted(task: tasks[index])
        }
        
        commitChanges()
    }

    func toggleDone(for task: TodoItem, achievementStore: AchievementStore? = nil) {
        //find the task in our main array (by id) and flip done/not done
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let wasDone = tasks[index].isDone
        
        tasks[index].isDone.toggle()
        //save happens automatically because tasks changed
        
        if !wasDone && tasks[index].isDone {
            achievementStore?.recordTaskCompleted(task: tasks[index])
        }
        
        commitChanges()
    }


    func markDone(for task: TodoItem, achievementStore: AchievementStore? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard !tasks[index].isDone else { return }
        
        tasks [index].isDone = true
                
        achievementStore?.recordTaskCompleted(task: tasks[index])
        
        commitChanges()
    }
    
    
    func deleteTasks(at offsets: IndexSet, in sectionTasks: [TodoItem]) {
        //the list gives us offsets for the section array, not the main tasks array
        //so we delete by id to avoid deleting the wrong thing
        let idsToDelete = offsets.map { sectionTasks[$0].id }
        tasks.removeAll { idsToDelete.contains($0.id) }
        //save happens automatically because tasks changed
        
        commitChanges()
    }




    //MARK: - sections for ui
    struct TodoSection: Identifiable, Equatable {
        let id: TodoCategory
        let title: String
        let tasks: [TodoItem]
    }
    
    struct PlannerDay: Identifiable, Equatable {
        let date: Date
        
        let tasks: [TodoItem]
        
        var id: Date {
            Calendar.current.startOfDay(for: date)
        }
    }


    //MARK: - sorting
    private func sortForDisplay(_ tasks: [TodoItem]) -> [TodoItem] {
        //this decides the order tasks appear inside a category
        
        
    
        
        tasks.sorted { a, b in
            
        
            //not done tasks first
            if moveTasksDown && a.isDone != b.isDone { return b.isDone }


            //higher priority first
            if a.effectivePriority.sortRank != b.effectivePriority.sortRank {
                return a.effectivePriority.sortRank < b.effectivePriority.sortRank
            }


            //newer first
            return a.createdAt > b.createdAt
        }
    }
    
    private func rebuildSections() {
        let grouped = Dictionary(grouping: tasks) { $0.category }

        // WHY: a stable section order which helps
        // when a single task changes.
        sections = TodoCategory.displayOrder.compactMap { category in
            guard let categoryTasks = grouped[category], !categoryTasks.isEmpty else { return nil }

            return TodoSection(
                id: category,
                title: category.displayTitle,
                tasks: sortForDisplay(categoryTasks)
            )
        }
    }


    //MARK: - persistence
    private func saveTasks() {
        //turn the tasks array into json data and store it in userdefaults
        //userdefaults is fine here because this is small data, not like photos or videos
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            //if saving fails, the app still runs, but tasks might not persist
            print("Todo save error: \(error)")
        }
    }


    private func loadTasks() {
        //grab saved json from userdefaults, and turn it back into [TodoItem]
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            tasks = try JSONDecoder().decode([TodoItem].self, from: data)
        } catch {
            //if decoding fails, we reset to empty so the app does not crash
            print("Todo load error: \(error)")
            tasks = []
        }
    }
    
    private func commitChanges() {
        rebuildSections()
        saveTasks()
    }
    
    func clearCompleted() {
        tasks.removeAll { $0.isDone }
        
        commitChanges()
    }
}


//MARK: - helpers
private extension String {
    var trimmed: String {
        //small helper so we do not repeat this line everywhere
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

