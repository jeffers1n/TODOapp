import SwiftUI
import Combine

class ChallengeViewModel: ObservableObject {
    @Published var challenges: [Challenge] = []
    private var cancellables = Set<AnyCancellable>()
    private let challengesKey = "savedChallenges"

    init() {
        loadChallenges()
        
        NotificationCenter.default.publisher(for: .taskCompleted)
            .compactMap { $0.object as? TodoTask }
            .sink { [weak self] completedTask in
                self?.updateChallengeProgress(for: completedTask.category)
            }
            .store(in: &cancellables)
    }

    func updateChallengeProgress(for category: TaskCategory) {
        if let index = challenges.firstIndex(where: { $0.category == category && !$0.isCompleted && !$0.isExpired }) {
            challenges[index].progress += 1
            saveChallenges()
        }
    }

    private func saveChallenges() {
        if let encoded = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(encoded, forKey: challengesKey)
        }
    }

    private func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: data) {
            challenges = decoded
            return
        }
        
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        challenges.append(Challenge(title: "Спортивная неделя", description: "Завершите 10 задач категории 'Спорт' за неделю", category: .sport, targetCount: 10, progress: 0, startDate: Date(), endDate: weekFromNow))
    }
} 
