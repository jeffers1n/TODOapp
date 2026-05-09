import SwiftUI
import Charts

struct TaskStatsView: View {
    @EnvironmentObject var taskVM: TaskViewModel

    private var totalTasks: Int {
        taskVM.tasks.count
    }

    private var completedTasks: [TodoTask] {
        taskVM.tasks.filter(\.isCompleted)
    }

    private var completionRate: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(completedTasks.count) / Double(totalTasks) * 100).rounded())
    }

    private var pendingCount: Int {
        max(0, totalTasks - completedTasks.count)
    }

    private var categoryStats: [CategoryStat] {
        let grouped = Dictionary(grouping: completedTasks, by: \.category)
        return grouped
            .map { CategoryStat(category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statsGrid

                if categoryStats.isEmpty {
                    Text("Пока нет выполненных задач для построения диаграммы.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    Text("Распределение выполненных задач по категориям")
                        .font(.headline)

                    pieChart
                        .frame(height: 280)

                    legend
                }
            }
            .padding()
        }
        .navigationTitle("Статистика задач")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statsGrid: some View {
        VStack(spacing: 10) {
            statRow(title: "Всего задач", value: "\(totalTasks)")
            statRow(title: "Выполнено", value: "\(completedTasks.count)")
            statRow(title: "В процессе", value: "\(pendingCount)")
            statRow(title: "Процент выполнения", value: "\(completionRate)%")
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var pieChart: some View {
        Chart(categoryStats) { item in
            SectorMark(
                angle: .value("Выполнено", item.count),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(item.category.chartColor)
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(categoryStats) { item in
                HStack {
                    Circle()
                        .fill(item.category.chartColor)
                        .frame(width: 10, height: 10)
                    Text(item.category.rawValue)
                    Spacer()
                    Text("\(item.count)")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

private struct CategoryStat: Identifiable {
    let id = UUID()
    let category: TaskCategory
    let count: Int
}

private extension TaskCategory {
    var chartColor: Color {
        switch self {
        case .general: return .gray
        case .work: return .blue
        case .study: return .indigo
        case .programming: return .mint
        case .sport: return .green
        case .health: return .red
        case .home: return .orange
        case .hobby: return .purple
        case .music: return .pink
        case .personalGrowth: return .teal
        case .finance: return .yellow
        case .social: return .cyan
        }
    }
}

