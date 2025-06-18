import SwiftUI

@main
struct TODOprojectApp: App {
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var profileVM = UserProfileViewModel()
    @StateObject private var achievementVM = AchievementViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var stickerVM = StickerViewModel()
    @StateObject private var viewRouter = ViewRouter()
    @StateObject private var challengeVM = ChallengeViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskVM)
                .environmentObject(profileVM)
                .environmentObject(achievementVM)
                .environmentObject(themeManager)
                .environmentObject(stickerVM)
                .environmentObject(viewRouter)
                .environmentObject(challengeVM)
                .preferredColorScheme(themeManager.selectedTheme == .dark ? .dark : (themeManager.selectedTheme == .light ? .light : nil))
        }
    }
}
