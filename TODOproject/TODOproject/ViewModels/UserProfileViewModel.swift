import SwiftUI
import SwiftData

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.userProfile = UserProfile(name: "Player")
        loadProfile()
        setupNotifications()
    }

    /// In-memory init for previews/tests
    convenience init() {
        let schema = Schema([UserProfileEntity.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.init(modelContext: container.mainContext)
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
        let now = Date()
        userProfile.totalTasksCompleted += 1

        updateStreak(completionDate: now)
        updateMood()
        checkAchievements()
        saveProfile()
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

    private func updateStreak(completionDate: Date) {
        let calendar = Calendar.current

        guard let lastDate = userProfile.lastCompletedDate else {
            userProfile.currentStreak = 1
            userProfile.bestStreak = max(userProfile.bestStreak, userProfile.currentStreak)
            userProfile.lastCompletedDate = completionDate
            return
        }

        if calendar.isDate(lastDate, inSameDayAs: completionDate) {
            return
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: completionDate),
           calendar.isDate(lastDate, inSameDayAs: yesterday) {
            userProfile.currentStreak += 1
        } else {
            userProfile.currentStreak = 1
        }

        userProfile.bestStreak = max(userProfile.bestStreak, userProfile.currentStreak)
        userProfile.lastCompletedDate = completionDate
    }

    private func loadProfile() {
        do {
            let stored = try modelContext.fetch(FetchDescriptor<UserProfileEntity>())
            if let entity = stored.first {
                userProfile = UserProfile(
                    id: entity.id,
                    name: entity.name,
                    totalTasksCompleted: entity.totalTasksCompleted,
                    currentStreak: entity.currentStreak,
                    bestStreak: entity.bestStreak,
                    mood: UserProfile.Mood(rawValue: entity.moodRawValue) ?? .neutral,
                    lastCompletedDate: entity.lastCompletedDate,
                    achievements: []
                )
            } else {
                saveProfile()
            }
        } catch {
            print("Failed to load profile from SwiftData: \(error.localizedDescription)")
        }
    }

    private func saveProfile() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<UserProfileEntity>())
            existing.forEach { modelContext.delete($0) }

            let entity = UserProfileEntity(
                id: userProfile.id,
                name: userProfile.name,
                totalTasksCompleted: userProfile.totalTasksCompleted,
                currentStreak: userProfile.currentStreak,
                bestStreak: userProfile.bestStreak,
                moodRawValue: userProfile.mood.rawValue,
                lastCompletedDate: userProfile.lastCompletedDate
            )
            modelContext.insert(entity)
            try modelContext.save()
        } catch {
            print("Failed to save profile to SwiftData: \(error.localizedDescription)")
        }
    }
} 
