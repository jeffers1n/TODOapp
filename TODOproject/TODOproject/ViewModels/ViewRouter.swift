import SwiftUI

class ViewRouter: ObservableObject {
    enum Tab {
        case home
        case tasks
        case challenges
        case achievements
        case profile
    }
    
    @Published var currentTab: Tab = .home
} 