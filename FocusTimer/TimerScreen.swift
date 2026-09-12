import SwiftUI

struct TimerScreen: View {
    @ObservedObject var viewModel: TimerViewModel

    private var minutes: Int { viewModel.secondsLeft / 60 }
    private var seconds: Int { viewModel.secondsLeft % 60 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(viewModel.phase == .work ? "Работа" : "Отдых")
                .font(.title.bold())

            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 16) {
                Button(viewModel.isRunning ? "Пауза" : "Старт") {
                    if viewModel.isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Стоп") {
                    viewModel.stop()
                }
                .buttonStyle(.bordered)
            }

            if !viewModel.isRunning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Время работы: \(viewModel.workMinutes) мин")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.workMinutes) },
                            set: { viewModel.setWorkMinutes(Int($0)) }
                        ),
                        in: 5...100,
                        step: 5
                    )

                    Text("Время отдыха: \(viewModel.restMinutes) мин")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.restMinutes) },
                            set: { viewModel.setRestMinutes(Int($0)) }
                        ),
                        in: 5...100,
                        step: 5
                    )
                }
                .padding(.top, 24)
            }

            Spacer()
        }
        .padding(24)
    }
}
