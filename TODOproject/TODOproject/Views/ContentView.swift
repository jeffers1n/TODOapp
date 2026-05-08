import SwiftUI

struct ContentView: View {
    @EnvironmentObject var achievementVM: AchievementViewModel
    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        TabView(selection: $viewRouter.currentTab) {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(ViewRouter.Tab.home)
            
            TaskListView()
                .tabItem {
                    Label("Задачи", systemImage: "list.bullet")
                }
                .tag(ViewRouter.Tab.tasks)

            ChallengesView()
                .tabItem {
                    Label("Испытания", systemImage: "flame.fill")
                }
                .tag(ViewRouter.Tab.challenges)
            
            AchievementsView(achievementVM: achievementVM)
                .tabItem {
                    Label("Достижения", systemImage: "star.fill")
                }
                .tag(ViewRouter.Tab.achievements)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
                .tag(ViewRouter.Tab.profile)
        }
        .withTabBarAppearance()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TaskViewModel())
            .environmentObject(UserProfileViewModel())
            .environmentObject(AchievementViewModel())
            .environmentObject(ChallengeViewModel())
            .environmentObject(StickerViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(ViewRouter())
    }
} 