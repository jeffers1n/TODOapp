import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementVM: AchievementViewModel
    
    var body: some View {
        NavigationView {
            List(achievementVM.achievements) { achievement in
                HStack {
                    Image(systemName: achievement.imageName)
                        .font(.title)
                        .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                    VStack(alignment: .leading) {
                        Text(achievement.title)
                            .font(.headline)
                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            }
            .navigationTitle("Достижения")
        }
    }
} 