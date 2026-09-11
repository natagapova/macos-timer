import SwiftUI

struct RootPanelView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var simpleTimer: TimerModel
    @EnvironmentObject private var pomodoro: PomodoroModel

    var body: some View {
        VStack(spacing: 4) {
            Picker("", selection: $coordinator.selectedPanel) {
                Text("timer").tag(AppCoordinator.PanelTab.simple)
                Text("pomodoro").tag(AppCoordinator.PanelTab.pomodoro)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)
            .padding(.top, 4)

            Group {
                switch coordinator.selectedPanel {
                case .simple:
                    TimerView()
                        .environmentObject(simpleTimer)
                case .pomodoro:
                    PomodoroView()
                        .environmentObject(pomodoro)
                        .environmentObject(coordinator)
                }
            }
            .frame(height: PanelLayout.contentHeight, alignment: .top)
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        if value.translation.width < -40 {
                            coordinator.selectedPanel = .pomodoro
                        } else if value.translation.width > 40 {
                            coordinator.selectedPanel = .simple
                        }
                    }
            )
        }
        .frame(width: PanelLayout.width, height: PanelLayout.height)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PanelLayout.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PanelLayout.cornerRadius, style: .continuous)
                .strokeBorder(TimerTheme.panelBorder, lineWidth: 0.75)
        }
        .onAppear {
            simpleTimer.requestNotificationPermission()
        }
    }
}
