import SwiftUI

struct ChallengesView: View {
    @StateObject private var challengeVM = ChallengeViewModel()

    var body: some View {
        NavigationView {
            List(challengeVM.challenges) { challenge in
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ProgressView(value: Double(challenge.progress), total: Double(challenge.targetCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    
                    HStack {
                        Text("Прогресс: \(challenge.progress)/\(challenge.targetCount)")
                        Spacer()
                        if challenge.isCompleted {
                            Text("Выполнено!")
                                .foregroundColor(.green)
                        } else if challenge.isExpired {
                            Text("Время вышло")
                                .foregroundColor(.red)
                        } else {
                            Text("Осталось: \(Int(challenge.endDate.timeIntervalSinceNow / 86400)) дн.")
                        }
                    }
                    .font(.caption)
                }
                .padding(.vertical)
            }
            .navigationTitle("Испытания")
        }
    }
} 