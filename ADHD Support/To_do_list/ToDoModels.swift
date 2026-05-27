//
//  ToDoModels.swift
//  ADHD Support
//
//  Created by Peter McMichael on 1/20/26.
//

import Foundation

enum Priority: String, Codable, CaseIterable, Identifiable, Equatable {
    case low
    case medium
    case high
    case URGENT
    
    var id: String {rawValue}
    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .URGENT: return "URGENT"
        }
    }
    var sortRank: Int {
        switch self {
        case .URGENT: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        
        }
    }
}


enum TodoCategory: String, Codable, CaseIterable, Identifiable {
    case homework = "Homework"
    case testPrep = "TestPrep"
    case longProject = "LongProject"
    case extracurricular = "Extracurricular"
    case chores = "Chores"
    case events = "Events"
    case errands = "Errands"
    case personal = "Personal"
    case social = "Social"
    case entertainment = "Entertainment"
    case health_fitness = "Health/Fitness"
    case other = "Other"
    
    var id: String { rawValue }
    
    static let displayOrder: [TodoCategory] = [
        .personal,
        .testPrep,
        .social,
        .errands,
        .events,
        .extracurricular,
        .longProject,
        .homework,
        .chores,
        .health_fitness,
        .entertainment,
        .other
    ]
    
    var displayTitle: String {
        switch self {
        case .homework: return "Homework"
        case .testPrep: return "Test Prep"
        case .longProject: return "Long Project"
        case .extracurricular: return "Extracurricular"
        case .chores: return "Chores"
        case .events: return "Events"
        case .errands: return "Errands"
        case .personal: return "Personal"	
        case .social: return "Social"
        case .entertainment: return "Entertainment"
        case .health_fitness: return "Health/Fitness"
        case .other: return "Other"
        }
    }
    
    init(rawLabel: String) {
        let trimmed = rawLabel.trimmed
        guard !trimmed.isEmpty, trimmed != "Unknown" else {
            self = .other
            return
        }
        
        let normalized = trimmed
            .lowercased()
            .replacingOccurrences(of: "", with: "")
            .replacingOccurrences(of: "_", with: "")
        
        switch normalized {
        case "homework", "hw":
            self = .homework
        case "testprep", "testpreparation":
            self = .testPrep
        case "longproject", "longtermproject", "project":
            self = .longProject
        case "extracurricular", "extracurr":
            self = .extracurricular
        case "chores", "chore":
            self = .chores
        case "events", "event":
            self = .events
        case "errands", "errand":
            self = .errands
        case "personal":
            self = .personal
        case "social":
            self = .social
        case "entertainment", "fun":
            self = .entertainment
        case "healthfitness", "health", "fitness":
            self = .health_fitness
        default: // if not in a category or unrecognized
            self = .other
        }
        
    }
}


struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var isInProgress: Bool
    var dueDate: Date?
    var plannedDate: Date?
    
    var predictedPriority: Priority
    var priorityConfidence: Double
    
    
    var categoryLabel: String
    var categoryConfidence: Double
    
    var userPriorityOverride: Priority?
    
    
    init(title: String, predictedPriority: Priority, priorityConfidence: Double, categoryLabel: String, categoryConfidence: Double, userPriorityOverride: Priority?) {
        self.id = UUID()
        self.title = title
        self.isDone = false
        self.isInProgress = false
        self.dueDate = nil
        self.plannedDate = nil
        self.predictedPriority = predictedPriority
        self.priorityConfidence = priorityConfidence
        self.createdAt = Date()
        self.categoryLabel = categoryLabel
        self.categoryConfidence = categoryConfidence
        self.userPriorityOverride = userPriorityOverride
    }
    
    var effectivePriority: Priority {
        userPriorityOverride ?? predictedPriority
    }
    
    var plannerStatus: String {
        if isDone { return "Finished" }
        if isInProgress { return "In Progress"}
        return "Not Started"
    }
    
    var category: TodoCategory {
        TodoCategory(rawLabel: categoryLabel)
    }
}




private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
