import SwiftUI
import Combine
import SwiftData

@MainActor
class ChallengeViewModel: ObservableObject {
    @Published var challenges: [Challenge] = []
    private var cancellables = Set<AnyCancellable>()
    private let modelContext: ModelContext
    private let targetActiveChallenges = 6

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadChallenges()
        
        NotificationCenter.default.publisher(for: .taskCompleted)
            .compactMap { $0.object as? TodoTask }
            .sink { [weak self] completedTask in
                self?.updateChallengeProgress(for: completedTask.category)
            }
            .store(in: &cancellables)
    }
    
    /// Удобный инициализатор для превью/тестов (in-memory SwiftData)
    convenience init() {
        let schema = Schema([ChallengeEntity.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.init(modelContext: container.mainContext)
    }

    func updateChallengeProgress(for category: TaskCategory) {
        if let index = challenges.firstIndex(where: { $0.category == category && !$0.isCompleted && !$0.isExpired }) {
            challenges[index].progress += 1
            rotateFinishedChallengesIfNeeded()
            saveChallenges()
        }
    }

    func refreshDynamicChallenges() {
        rotateFinishedChallengesIfNeeded()
        saveChallenges()
    }

    private func saveChallenges() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<ChallengeEntity>())
            existing.forEach { modelContext.delete($0) }
            
            for challenge in challenges {
                let entity = ChallengeEntity(
                    id: challenge.id,
                    title: challenge.title,
                    challengeDescription: challenge.description,
                    categoryRawValue: challenge.category.rawValue,
                    targetCount: challenge.targetCount,
                    progress: challenge.progress,
                    startDate: challenge.startDate,
                    endDate: challenge.endDate
                )
                modelContext.insert(entity)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save challenges to SwiftData: \\(error)")
        }
    }

    private func loadChallenges() {
        do {
            let stored = try modelContext.fetch(FetchDescriptor<ChallengeEntity>())
            if stored.isEmpty {
                challenges = defaultChallenges()
            } else {
                challenges = stored.compactMap { entity in
                    guard let category = TaskCategory(rawValue: entity.categoryRawValue) else { return nil }
                    return Challenge(
                        id: entity.id,
                        title: entity.title,
                        description: entity.challengeDescription,
                        category: category,
                        targetCount: entity.targetCount,
                        progress: entity.progress,
                        startDate: entity.startDate,
                        endDate: entity.endDate
                    )
                }
            }
            rotateFinishedChallengesIfNeeded()
            saveChallenges()
        } catch {
            print("Failed to load challenges from SwiftData: \\(error)")
            challenges = defaultChallenges()
            saveChallenges()
        }
    }

    private func defaultChallenges() -> [Challenge] {
        let initialCategories: [TaskCategory] = [.general, .work, .study, .programming, .sport, .home]
        return initialCategories.map { createChallenge(for: $0) }
    }

    private func rotateFinishedChallengesIfNeeded() {
        challenges.removeAll { $0.isCompleted || $0.isExpired }

        while challenges.count < targetActiveChallenges {
            let nextCategory = nextCategoryForNewChallenge()
            challenges.append(createChallenge(for: nextCategory))
        }
    }

    private func nextCategoryForNewChallenge() -> TaskCategory {
        let activeCategories = Set(challenges.map(\.category))
        let available = TaskCategory.allCases.filter { !activeCategories.contains($0) }
        return available.randomElement() ?? TaskCategory.allCases.randomElement() ?? .general
    }

    private func createChallenge(for category: TaskCategory) -> Challenge {
        let now = Date()
        let duration = durationDays(for: category)
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: now) ?? now
        let target = targetCount(for: category, durationDays: duration)
        let title = titleFor(category: category)
        let description = "Завершите \(target) задач категории '\(category.rawValue)' за \(duration) дн."

        return Challenge(
            title: title,
            description: description,
            category: category,
            targetCount: target,
            progress: 0,
            startDate: now,
            endDate: endDate
        )
    }

    private func durationDays(for category: TaskCategory) -> Int {
        switch category {
        case .sport, .health:
            return [5, 7, 10].randomElement() ?? 7
        case .work, .study, .programming:
            return [7, 10, 14].randomElement() ?? 10
        case .hobby, .music, .personalGrowth:
            return [7, 14].randomElement() ?? 7
        case .finance, .social, .home, .general:
            return [4, 7, 10].randomElement() ?? 7
        }
    }

    private func targetCount(for category: TaskCategory, durationDays: Int) -> Int {
        let base: Double
        switch category {
        case .sport, .health:
            base = 0.9
        case .work, .study, .programming:
            base = 0.8
        case .hobby, .music, .personalGrowth:
            base = 0.6
        case .finance, .social, .home, .general:
            base = 0.7
        }
        return max(3, Int(round(Double(durationDays) * base)))
    }

    private func titleFor(category: TaskCategory) -> String {
        switch category {
        case .work: return ["Рабочий спринт", "Офисный прорыв", "Фокус на деле"].randomElement() ?? "Рабочий спринт"
        case .study: return ["Учебный рывок", "Сессия силы", "Академический темп"].randomElement() ?? "Учебный рывок"
        case .programming: return ["Код-марафон", "Багхантер", "Алгоритмический апгрейд"].randomElement() ?? "Код-марафон"
        case .sport: return ["Спортивный заряд", "Режим атлета", "Кардио-квест"].randomElement() ?? "Спортивный заряд"
        case .health: return ["Здоровый ритм", "Энергия дня", "Формула баланса"].randomElement() ?? "Здоровый ритм"
        case .home: return ["Домашний порядок", "Уютный апгрейд", "Чистый прогресс"].randomElement() ?? "Домашний порядок"
        case .hobby: return ["Творческий импульс", "Хобби-вдохновение", "Крафт-квест"].randomElement() ?? "Творческий импульс"
        case .music: return ["Музыкальная волна", "Ритм недели", "Саунд-квест"].randomElement() ?? "Музыкальная волна"
        case .personalGrowth: return ["Личностный скачок", "Рост 2.0", "Точка развития"].randomElement() ?? "Личностный скачок"
        case .finance: return ["Финансовая дисциплина", "Контроль бюджета", "Монетный баланс"].randomElement() ?? "Финансовая дисциплина"
        case .social: return ["Социальный заряд", "Связи в фокусе", "Комьюнити-квест"].randomElement() ?? "Социальный заряд"
        case .general: return ["Быстрый старт", "Универсальный квест", "Прогресс-мод"].randomElement() ?? "Быстрый старт"
        }
    }
} 
