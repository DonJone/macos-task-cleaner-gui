import SwiftUI
import AppKit

@main
struct TaskCleanerApp: App {
    @StateObject private var viewModel = TaskCleanerViewModel()

    var body: some Scene {
        MenuBarExtra {
            TaskCleanerMenuView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "broom.fill")
                if let count = viewModel.summary?.target_count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
