import SwiftUI
import Combine
import SwiftData

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    private var cancellables = Set<AnyCancellable>()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAchievements()
        
        NotificationCenter.default.publisher(for: .taskCompleted)
            .sink { [weak self] _ in
                self?.unlockAchievement(title: "Первый шаг")
            }
            .store(in: &cancellables)
    }
    
    /// Удобный инициализатор для превью/тестов (in-memory SwiftData)
    convenience init() {
        let schema = Schema([AchievementEntity.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.init(modelContext: container.mainContext)
    }
    
    func unlockAchievement(title: String) {
        if let index = achievements.firstIndex(where: { $0.title == title && !$0.isUnlocked }) {
            achievements[index].isUnlocked = true
            saveAchievements()
        }
    }
    
    private func saveAchievements() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<AchievementEntity>())
            existing.forEach { modelContext.delete($0) }
            
            for achievement in achievements {
                let entity = AchievementEntity(
                    id: achievement.id,
                    title: achievement.title,
                    achievementDescription: achievement.description,
                    isUnlocked: achievement.isUnlocked,
                    imageName: achievement.imageName
                )
                modelContext.insert(entity)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save achievements to SwiftData: \\(error)")
        }
    }
    
    private func loadAchievements() {
        do {
            let stored = try modelContext.fetch(FetchDescriptor<AchievementEntity>())
            if stored.isEmpty {
                self.achievements = defaultAchievements()
            } else {
                self.achievements = stored.map { entity in
                    Achievement(
                        id: entity.id,
                        title: entity.title,
                        description: entity.achievementDescription,
                        isUnlocked: entity.isUnlocked,
                        imageName: entity.imageName
                    )
                }
            }
        } catch {
            print("Failed to load achievements from SwiftData: \\(error)")
            self.achievements = defaultAchievements()
        }
    }

    private func defaultAchievements() -> [Achievement] {
        [
            Achievement(title: "Первый шаг", description: "Завершите свою первую задачу", isUnlocked: false, imageName: "figure.walk"),
            Achievement(title: "Разогрев", description: "Завершите 5 задач", isUnlocked: false, imageName: "flame.fill"),
            Achievement(title: "Мастер задач", description: "Завершите 10 задач", isUnlocked: false, imageName: "star.fill"),
            Achievement(title: "Фокус дня", description: "Завершите 3 задачи за один день", isUnlocked: false, imageName: "target"),
            Achievement(title: "Рабочий режим", description: "Закройте 7 задач категории 'Работа'", isUnlocked: false, imageName: "briefcase.fill"),
            Achievement(title: "Студент на максималках", description: "Закройте 7 задач категории 'Учеба'", isUnlocked: false, imageName: "graduationcap.fill"),
            Achievement(title: "Код-мастер", description: "Закройте 7 задач категории 'Программирование'", isUnlocked: false, imageName: "desktopcomputer"),
            Achievement(title: "Спортивный импульс", description: "Закройте 7 задач категории 'Спорт'", isUnlocked: false, imageName: "figure.run"),
            Achievement(title: "Дом в порядке", description: "Закройте 7 задач категории 'Дом'", isUnlocked: false, imageName: "house.fill"),
            Achievement(title: "Финансовый контроль", description: "Закройте 5 задач категории 'Финансы'", isUnlocked: false, imageName: "dollarsign.circle.fill"),
            Achievement(title: "Баланс жизни", description: "Завершите задачи минимум из 4 разных категорий", isUnlocked: false, imageName: "circle.grid.2x2.fill"),
            Achievement(title: "Коллекционер побед", description: "Откройте 5 достижений", isUnlocked: false, imageName: "trophy.fill")
        ]
    }
} 
