import SwiftUI
import SwiftData

@main
struct TODOprojectApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        let schema = Schema([
            TaskEntity.self,
            AchievementEntity.self,
            ChallengeEntity.self,
            StickerEntity.self,
            UserProfileEntity.self
        ])
        
        // Конфигурация SwiftData c синхронизацией через CloudKit (приватная база iCloud пользователя)
        // Используем дефолтный контейнер на основе Bundle ID
        let bundleID = Bundle.main.bundleIdentifier ?? "com.todoapp"
        let containerIdentifier = "iCloud.\(bundleID)"
        
        do {
            let cloudConfig = ModelConfiguration(
                cloudKitDatabase: .private(containerIdentifier)
            )
            modelContainer = try ModelContainer(for: schema, configurations: [cloudConfig])
            print("✅ CloudKit успешно настроен: \(containerIdentifier)")
        } catch {
            // Если CloudKit недоступен, используем локальное хранилище
            print("⚠️ CloudKit недоступен, используется локальное хранилище: \(error.localizedDescription)")
            do {
                let localConfig = ModelConfiguration()
                modelContainer = try ModelContainer(for: schema, configurations: [localConfig])
                print("✅ Локальное хранилище SwiftData успешно настроено")
            } catch {
                fatalError("❌ Критическая ошибка: не удалось создать ModelContainer: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            let context = modelContainer.mainContext
            
            ContentView()
                .environmentObject(TaskViewModel(modelContext: context))
                .environmentObject(UserProfileViewModel(modelContext: context))
                .environmentObject(AchievementViewModel(modelContext: context))
                .environmentObject(themeManager)
                .environmentObject(StickerViewModel(modelContext: context))
                .environmentObject(ViewRouter())
                .environmentObject(ChallengeViewModel(modelContext: context))
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    await NotificationManager.shared.requestAuthorizationIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }
}
