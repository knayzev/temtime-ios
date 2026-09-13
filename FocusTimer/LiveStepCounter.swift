import Foundation
import CoreMotion

@MainActor
final class LiveStepCounter: ObservableObject {
    @Published var steps: Int?
    private let pedometer = CMPedometer()

    func start() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let data else { return }
            DispatchQueue.main.async {
                self?.steps = data.numberOfSteps.intValue
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
        steps = nil
    }
}
