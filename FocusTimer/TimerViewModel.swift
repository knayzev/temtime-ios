import Foundation
import AudioToolbox

enum TimerPhase {
    case work
    case rest
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: TimerPhase = .work
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var secondsLeft: Int
    @Published private(set) var workMinutes: Int
    @Published private(set) var restMinutes: Int

    private var timer: Timer?
    private let prefs = PrefsManager.shared

    init() {
        let work = prefs.workMinutes
        let rest = prefs.restMinutes
        workMinutes = work
        restMinutes = rest
        secondsLeft = work * 60
    }

    func setWorkMinutes(_ minutes: Int) {
        prefs.workMinutes = minutes
        workMinutes = minutes
        if !isRunning && phase == .work {
            secondsLeft = minutes * 60
        }
    }

    func setRestMinutes(_ minutes: Int) {
        prefs.restMinutes = minutes
        restMinutes = minutes
        if !isRunning && phase == .rest {
            secondsLeft = minutes * 60
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phase = .work
        secondsLeft = workMinutes * 60
    }

    private func tick() {
        guard secondsLeft > 0 else {
            onPhaseFinished()
            return
        }
        secondsLeft -= 1
        if secondsLeft == 0 {
            onPhaseFinished()
        }
    }

    private func onPhaseFinished() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        alertUser()
        phase = (phase == .work) ? .rest : .work
        secondsLeft = (phase == .work ? workMinutes : restMinutes) * 60
        start()
    }

    private func alertUser() {
        if prefs.vibrationEnabled {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        if prefs.soundEnabled {
            AudioServicesPlaySystemSound(1005)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
