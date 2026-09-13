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

let workDonePhrasesRU = [
    "Пора отдыхать! Выпейте чашку кофе или чая.",
    "Работа завершена. Самое время немного отдохнуть.",
    "Отличная работа! Теперь можно расслабиться и передохнуть.",
    "Время отдыха началось. Встаньте, разомнитесь, подышите свежим воздухом.",
    "Вы молодец! Сделайте паузу — заварите чай и отдохните.",
    "Рабочий блок завершён. Дайте глазам и телу отдохнуть.",
    "Пора сделать перерыв. Прогуляйтесь или выпейте воды.",
    "Работа окончена — насладитесь заслуженным отдыхом.",
    "Отлично поработали! Теперь немного расслабьтесь.",
    "Время выдохнуть. Отдых начался — используйте его с пользой."
]

let restDonePhrasesRU = [
    "Пора работать! Желаю удачи — всё получится.",
    "Отдых завершён. Приступим к делу с новыми силами.",
    "Время снова сосредоточиться. У вас точно получится!",
    "Перерыв окончен. Вперёд, к новым результатам!",
    "Пора возвращаться к работе. Вы справитесь!",
    "Отдохнули — теперь за дело! Удачи вам.",
    "Рабочее время началось. Сфокусируйтесь и действуйте.",
    "Время продуктивности! Начинаем работать.",
    "Перерыв закончен — покажите, на что способны!",
    "Снова в бой! Желаю продуктивной работы."
]

let workDonePhrasesEN = [
    "Time to rest! Grab a cup of coffee or tea.",
    "Work session complete. Time for a well-deserved break.",
    "Great job! Now relax and recharge for a bit.",
    "Rest time has started. Stand up, stretch, get some fresh air.",
    "Well done! Take a break — brew some tea and unwind.",
    "Work block finished. Give your eyes and body a rest.",
    "Time for a break. Take a walk or drink some water.",
    "Work is done — enjoy your well-earned rest.",
    "Great work! Time to relax a little.",
    "Time to breathe out. Rest has begun — make the most of it."
]

let restDonePhrasesEN = [
    "Time to work! Good luck — you've got this.",
    "Break's over. Let's get back to it with fresh energy.",
    "Time to focus again. You can definitely do this!",
    "Break is over. Onward to new results!",
    "Time to get back to work. You'll manage just fine!",
    "Rested up — now let's get to it! Good luck.",
    "Work time has started. Focus and take action.",
    "Time to be productive! Let's start working.",
    "Break's over — show what you're capable of!",
    "Back into it! Wishing you a productive work session."
]

private let femaleVoiceNames = ["milena", "samantha", "ava", "allison", "susan", "nicky", "victoria", "kate", "anna", "tessa"]
private let maleVoiceNames = ["yuri", "aaron", "nathan", "evan", "alex", "fred", "tom", "daniel", "arthur"]

/// Best-effort pick of a natural, gendered voice for the given language. Prefers higher-quality
/// (enhanced/premium) installed voices over the flat default ones, falling back gracefully when
/// nothing better is available — it never fails to return *some* voice for the language.
private func pickVoice(languageCode: String, female: Bool) -> AVSpeechSynthesisVoice? {
    let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == languageCode }
    guard !candidates.isEmpty else { return AVSpeechSynthesisVoice(language: languageCode) }

    func qualityRank(_ voice: AVSpeechSynthesisVoice) -> Int {
        switch voice.quality {
        case .premium: return 2
        case .enhanced: return 1
        default: return 0
        }
    }
    let sorted = candidates.sorted { qualityRank($0) > qualityRank($1) }

    if #available(iOS 17.0, *) {
        if let genderMatch = sorted.first(where: { $0.gender == (female ? .female : .male) }) {
            return genderMatch
        }
    }

    let names = female ? femaleVoiceNames : maleVoiceNames
    let nameMatch = sorted.first { voice in
        let lower = voice.name.lowercased()
        return names.contains { lower.contains($0) }
    }
    return nameMatch ?? sorted.first
}

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
    private var nextVoiceFemale = true
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
        let english = prefs.voiceLanguage == "English"
        let text: String
        if english {
            text = phase == .work ? "Rest time is approaching" : "Work time is approaching"
        } else {
            text = phase == .work ? "Приближается время отдыха" : "Приближается время работы"
        }
        speak(text)
    }

    private func speak(_ text: String) {
        let languageCode = prefs.voiceLanguage == "English" ? "en-US" : "ru-RU"
        let female = nextVoiceFemale
        nextVoiceFemale.toggle()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = pickVoice(languageCode: languageCode, female: female)
        // A pitch/rate nudge keeps the alternation audible even if the device only has one
        // installed voice for the language.
        utterance.pitchMultiplier = female ? 1.1 : 0.85
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (female ? 1.02 : 0.98)
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
        if prefs.voiceAnnounceEnabled {
            let english = prefs.voiceLanguage == "English"
            let phrase: String?
            if finishedPhase == .work {
                phrase = (english ? workDonePhrasesEN : workDonePhrasesRU).randomElement()
            } else {
                phrase = (english ? restDonePhrasesEN : restDonePhrasesRU).randomElement()
            }
            if let phrase {
                speak(phrase)
            }
        }
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
