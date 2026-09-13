import Foundation
import AudioToolbox
import AVFAudio

enum TimerPhase {
    case work
    case rest
}

let motivationalQuotes = [
    "Успех — это способность идти от одной неудачи к другой, не теряя энтузиазма. — Уинстон Черчилль",
    "Единственный способ сделать великую работу — любить то, что ты делаешь. — Стив Джобс",
    "Не бойтесь совершенства — вам его не достичь. — Сальвадор Дали",
    "Дисциплина — это мост между целями и результатом. — Джим Рон",
    "Я не терпел неудачу. Я просто нашёл 10 000 способов, которые не работают. — Томас Эдисон",
    "Секрет продвижения вперёд — начать. — Марк Твен",
    "Тяжело в учении — легко в бою. — Александр Суворов",
    "Будущее принадлежит тем, кто верит в красоту своей мечты. — Элеонора Рузвельт",
    "Маленькие ежедневные улучшения со временем дают потрясающие результаты. — Робин Шарма",
    "Ты никогда не будешь готов на 100%. Начни с тем, что есть. — Наполеон Хилл",
    "Не считай дни, делай дни значимыми. — Мухаммед Али",
    "Лучшее время посадить дерево было 20 лет назад. Второе лучшее — сейчас. — китайская пословица",
    "Делай то, что можешь, с тем, что имеешь, там, где ты есть. — Теодор Рузвельт",
    "Мотивация — то, что заставляет тебя начать. Привычка — то, что заставляет продолжать. — Джим Рон",
    "Единственный, кто может остановить тебя, — это ты сам. — неизвестный автор"
]

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: TimerPhase = .work
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var secondsLeft: Int
    @Published private(set) var workMinutes: Int
    @Published private(set) var restMinutes: Int
    @Published var currentComment: String = ""
    @Published var currentCategory: String = ""
    @Published private(set) var motivationQuote: String?

    private var timer: Timer?
    private let prefs = PrefsManager.shared
    private var sessionStartTime: TimeInterval?
    private var announcedThisPhase = false
    private let speechSynthesizer = AVSpeechSynthesizer()

    init() {
        let work = prefs.workMinutes
        let rest = prefs.restMinutes
        workMinutes = work
        restMinutes = rest
        secondsLeft = work * 60
        currentCategory = prefs.categories.first ?? ""
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

    func dismissQuote() {
        motivationQuote = nil
    }

    func start() {
        guard !isRunning else { return }
        if sessionStartTime == nil {
            sessionStartTime = Date().timeIntervalSince1970
        }
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
        flushHistoryEntry(interrupted: true)
        announcedThisPhase = false
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
        maybeAnnounceUpcomingPhase()
        if secondsLeft == 0 {
            onPhaseFinished()
        }
    }

    private func maybeAnnounceUpcomingPhase() {
        guard prefs.voiceAnnounceEnabled, !announcedThisPhase else { return }
        let lead = prefs.voiceAnnounceLeadSeconds()
        guard lead > 0, secondsLeft <= lead else { return }
        announcedThisPhase = true
        let text = phase == .work ? "Приближается время отдыха" : "Приближается время работы"
        speak(text)
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        speechSynthesizer.speak(utterance)
    }

    private func onPhaseFinished() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        let finishedPhase = phase
        let quote = finishedPhase == .work ? motivationalQuotes.randomElement() : nil
        flushHistoryEntry(interrupted: false, quote: quote ?? "")
        phase = (finishedPhase == .work) ? .rest : .work
        secondsLeft = (phase == .work ? workMinutes : restMinutes) * 60
        announcedThisPhase = false
        if let quote {
            motivationQuote = quote
        }
        start()
        repeatAlert(times: finishedPhase == .work ? 3 : 1)
    }

    private func repeatAlert(times: Int) {
        Task { @MainActor in
            for index in 0..<times {
                alertUser()
                if index < times - 1 {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                }
            }
        }
    }

    private func flushHistoryEntry(interrupted: Bool, quote: String = "") {
        guard let start = sessionStartTime else { return }
        let plannedSeconds = (phase == .work ? workMinutes : restMinutes) * 60
        let elapsedSeconds = interrupted ? max(0, plannedSeconds - secondsLeft) : plannedSeconds
        let entry = SessionRecord(
            id: start,
            phase: phase == .work ? "WORK" : "REST",
            startTime: start,
            durationSeconds: elapsedSeconds,
            interrupted: interrupted,
            comment: currentComment,
            category: currentCategory,
            quote: quote
        )
        prefs.addHistoryEntry(entry)
        sessionStartTime = nil
        currentComment = ""
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
