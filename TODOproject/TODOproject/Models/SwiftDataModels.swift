import Foundation
import SwiftData
import CoreGraphics

// MARK: - TaskEntity

@Model
final class TaskEntity {
    var id: UUID
    var title: String
    var taskDescription: String
    var dueDate: Date
    var categoryRawValue: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String,
        dueDate: Date,
        categoryRawValue: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.categoryRawValue = categoryRawValue
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

// MARK: - AchievementEntity

@Model
final class AchievementEntity {
    var id: UUID
    var title: String
    var achievementDescription: String
    var isUnlocked: Bool
    var imageName: String

    init(
        id: UUID = UUID(),
        title: String,
        achievementDescription: String,
        isUnlocked: Bool,
        imageName: String
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.isUnlocked = isUnlocked
        self.imageName = imageName
    }
}

// MARK: - ChallengeEntity

@Model
final class ChallengeEntity {
    var id: UUID
    var title: String
    var challengeDescription: String
    var categoryRawValue: String
    var targetCount: Int
    var progress: Int
    var startDate: Date
    var endDate: Date

    init(
        id: UUID = UUID(),
        title: String,
        challengeDescription: String,
        categoryRawValue: String,
        targetCount: Int,
        progress: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.title = title
        self.challengeDescription = challengeDescription
        self.categoryRawValue = categoryRawValue
        self.targetCount = targetCount
        self.progress = progress
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - StickerEntity

@Model
final class StickerEntity {
    var id: UUID
    var imageData: Data
    var scale: Double
    var rotation: Double
    var positionX: Double
    var positionY: Double
    var isPlaced: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imageData: Data,
        scale: Double,
        rotation: Double,
        positionX: Double,
        positionY: Double,
        isPlaced: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.scale = scale
        self.rotation = rotation
        self.positionX = positionX
        self.positionY = positionY
        self.isPlaced = isPlaced
        self.createdAt = createdAt
    }
}

// MARK: - UserProfileEntity

@Model
final class UserProfileEntity {
    var id: UUID
    var name: String
    var totalTasksCompleted: Int
    var currentStreak: Int
    var bestStreak: Int
    var moodRawValue: String
    var lastCompletedDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        totalTasksCompleted: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        moodRawValue: String = UserProfile.Mood.neutral.rawValue,
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.totalTasksCompleted = totalTasksCompleted
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.moodRawValue = moodRawValue
        self.lastCompletedDate = lastCompletedDate
    }
}


