import SwiftUI
import Combine

class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAchievements()
        
        NotificationCenter.default.publisher(for: .taskCompleted)
            .sink { [weak self] _ in
                self?.unlockAchievement(title: "Первый шаг")
            }
            .store(in: &cancellables)
    }
    
    func unlockAchievement(title: String) {
        if let index = achievements.firstIndex(where: { $0.title == title && !$0.isUnlocked }) {
            achievements[index].isUnlocked = true
            saveAchievements()
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "savedAchievements")
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "savedAchievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = decoded
            return
        }
        
        self.achievements = [
            Achievement(title: "Первый шаг", description: "Завершите свою первую задачу", isUnlocked: false, imageName: "figure.walk"),
            Achievement(title: "Мастер задач", description: "Завершите 10 задач", isUnlocked: false, imageName: "star.fill")
        ]
    }
} 
