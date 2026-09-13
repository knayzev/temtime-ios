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
    "Хэй, привет! Ну что, поработал? Пора бы и отдохнуть!",
    "Стоп машина! Работа подождёт — самое время выдохнуть.",
    "Есть! Рабочий блок закрыт. Отдых, встречай!",
    "Отличная работа. Дайте себе немного тишины и покоя.",
    "Всё, шабаш! Заслуженный перерыв уже ждёт.",
    "Мозг просит паузы — дайте ему то, что он хочет.",
    "Рабочий этап завершён. Забота о себе — тоже часть продуктивности.",
    "Ты справился! Теперь можно и ноги на стол.",
    "Тайм-аут! Тело и голова скажут спасибо за пару минут отдыха.",
    "Готово! Сделайте паузу — вы это заслужили."
]

let restDonePhrasesRU = [
    "Так, так, время пришло работать! Вперёд и с песней!",
    "Отдых закончен, будильник для мозга прозвенел. За работу!",
    "Перерыв — в архив. Погнали делать великие дела!",
    "Время снова включиться в работу. У вас точно получится.",
    "Батарейка заряжена на сто процентов — пора выдавать результат!",
    "Отдохнули — красота. Теперь покажем, на что способны!",
    "Рабочий режим активирован. Приступаем!",
    "Хватит бездельничать — шучу! Но работать и правда пора.",
    "Соберитесь — сейчас будет продуктивно и красиво.",
    "Вперёд, покоритель дедлайнов! Работа ждёт."
]

let workDonePhrasesEN = [
    "Hey there! You worked hard, huh? Time to rest!",
    "Stop the presses! Work can wait — time to breathe out.",
    "Done and done! Work block closed. Hello, rest!",
    "Great work. Give yourself a little peace and quiet.",
    "That's a wrap! Your well-earned break is waiting.",
    "Your brain is asking for a pause — give it what it wants.",
    "Work block complete. Self-care is productivity too.",
    "You did it! Time to kick back for a bit.",
    "Time out! Your body and mind will thank you for a short rest.",
    "All done! Take a break — you've earned it."
]

let restDonePhrasesEN = [
    "Alright, alright, it's time to work! Onward, with a song!",
    "Break's over, the brain alarm just went off. Let's work!",
    "Break — archived. Let's go make great things happen!",
    "Time to get back into it. You've got this.",
    "Battery's at one hundred percent — time to deliver!",
    "Nicely rested. Now let's show what you can do!",
    "Work mode: activated. Let's go!",
    "Enough lounging around — just kidding! But it really is time to work.",
    "Get focused — this is about to be productive and great.",
    "Onward, deadline conqueror! Work awaits."
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
