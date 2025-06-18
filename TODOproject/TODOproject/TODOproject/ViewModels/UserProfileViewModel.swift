import SwiftUI

class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    
    init() {
        self.userProfile = UserProfile(name: "Player")
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskCompletion),
            name: .taskCompleted,
            object: nil
        )
    }
    
    @objc private func handleTaskCompletion() {
        userProfile.totalTasksCompleted += 1
        updateMood()
        checkAchievements()
    }
    
    private func updateMood() {
        if userProfile.totalTasksCompleted > 0 && userProfile.totalTasksCompleted % 5 == 0 {
            userProfile.mood = .accomplished
        } else if userProfile.currentStreak > 3 {
            userProfile.mood = .happy
        } else {
            userProfile.mood = .neutral
        }
    }
    
    private func checkAchievements() {
        if userProfile.totalTasksCompleted == 1 {
            unlockAchievement(
                Achievement(
                    title: "Первый шаг",
                    description: "Завершите свою первую задачу",
                    isUnlocked: true,
                    imageName: "figure.walk"
                )
            )
        }
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        if !userProfile.achievements.contains(where: { $0.id == achievement.id }) {
            userProfile.achievements.append(achievement)
        }
    }
    
} 
