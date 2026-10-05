import Foundation
import AudioToolbox
import AVFAudio

enum TimerPhase: String, Codable {
    case work = "WORK"
    case rest = "REST"
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

/// One upcoming phase change, worked out ahead of time so a notification can announce it while
/// the app is suspended.
struct PhaseTransition {
    let at: Date
    let endedPhase: TimerPhase
    let nextPhase: TimerPhase
    let nextLabel: String
}

/// What survives a relaunch: enough to put the countdown back exactly where it was.
private struct SavedTimer: Codable {
    var phase: TimerPhase
    var isRunning: Bool
    var secondsLeft: Int
    var endDate: Date?
    var sessionStart: Date?
    var selectedPlanId: String?
    var comment: String
    var category: String
}

/// The work/rest countdown and the day's schedule it runs through.
///
/// iOS suspends an app shortly after it leaves the screen, so nothing here can rely on ticking:
/// the countdown is measured against the moment the phase ends, the state is saved on every
/// change, and the upcoming phase changes are handed to the system as local notifications. When
/// the app comes back, every change that fell due in the meantime is applied in one go.
@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: TimerPhase = .work
    @Published private(set) var isRunning = false
    @Published private(set) var secondsLeft: Int
    @Published private(set) var workMinutes: Int
    @Published private(set) var restMinutes: Int
    @Published var currentComment: String = "" {
        didSet { save() }
    }
    @Published var currentCategory: String = "" {
        didSet { save() }
    }
    @Published private(set) var motivationQuote: String?
    /// A phase change went unanswered for longer than the grace period with the app on screen.
    @Published private(set) var escalationActive = false

    @Published private(set) var planItems: [PlanItem]
    @Published private(set) var doneIds: Set<String>
    @Published private(set) var selectedPlanId: String?

    static let missedWindowGrace: TimeInterval = 60

    private var todayKey: String
    private var endDate: Date?
    private var sessionStart: Date?
    /// When an unanswered phase change seen live turns into a "missed window".
    private var escalationDeadline: Date?
    private var ticker: Timer?
    /// Raised until the saved state has been read back, so nothing overwrites it first.
    private var restoring = true
    private let prefs = PrefsManager.shared
    private var announcedThisPhase = false
    private var nextVoiceFemale = true
    private let speechSynthesizer = AVSpeechSynthesizer()

    init() {
        let prefs = PrefsManager.shared
        let today = dayStamp()
        let work = prefs.workMinutes
        workMinutes = work
        restMinutes = prefs.restMinutes
        secondsLeft = work * 60
        todayKey = today
        planItems = prefs.planItems
        doneIds = prefs.completedPlanIds(date: today)
        currentCategory = prefs.categories.first ?? ""
        restore()
        restoring = false
        if isRunning {
            catchUp(alertIfJustNow: false)
            startTicker()
        }
    }

    // MARK: Derived state

    var selectedPlan: PlanItem? { planItems.first { $0.id == selectedPlanId } }

    var phaseTotalSeconds: Int { max(1, phase == .work ? workMinutes : restMinutes) * 60 }

    /// With an entry loaded the ring says what it is, not just that work is happening.
    var phaseLabel: String {
        if phase == .rest { return "Отдых" }
        return selectedPlan?.title ?? "Работа"
    }

    /// A countdown is under way or paused partway, as opposed to sitting at a fresh phase.
    var isActive: Bool { isRunning || sessionStart != nil }

    /// The first entry of the day that is not ticked off yet.
    var nextPlanId: String? { planItems.first { !doneIds.contains($0.id) }?.id }

    // MARK: Timer controls

    func setWorkMinutes(_ minutes: Int) {
        applyWorkMinutes(minutes)
        save()
    }

    func setRestMinutes(_ minutes: Int) {
        prefs.restMinutes = minutes
        restMinutes = minutes
        if !isRunning && phase == .rest {
            secondsLeft = minutes * 60
        }
        save()
    }

    func dismissQuote() {
        motivationQuote = nil
    }

    func start() {
        guard !isRunning else { return }
        if sessionStart == nil {
            sessionStart = Date()
        }
        if secondsLeft <= 0 {
            secondsLeft = phaseTotalSeconds
        }
        endDate = Date().addingTimeInterval(TimeInterval(secondsLeft))
        isRunning = true
        startTicker()
        save()
        NotificationScheduler.requestAuthorization()
        scheduleNotifications()
    }

    func pause() {
        guard isRunning else { return }
        if let end = endDate {
            secondsLeft = max(1, Int(ceil(end.timeIntervalSinceNow)))
        }
        endDate = nil
        isRunning = false
        stopTicker()
        save()
        NotificationScheduler.cancelAll()
    }

    func stop() {
        if isRunning, let end = endDate {
            secondsLeft = max(0, Int(ceil(end.timeIntervalSinceNow)))
        }
        stopTicker()
        recordSession(interrupted: true, quote: "")
        announcedThisPhase = false
        isRunning = false
        endDate = nil
        escalationDeadline = nil
        phase = .work
        secondsLeft = workMinutes * 60
        escalationActive = false
        save()
        NotificationScheduler.cancelAll()
    }

    /// Coming back to the app counts as noticing the phase change, as on Android: whatever fell due
    /// while it was away is applied, and the reminders already delivered are cleared.
    func appBecameActive() {
        refreshDay()
        if isRunning {
            catchUp(alertIfJustNow: false)
            startTicker()
        }
        acknowledge()
        NotificationScheduler.clearDelivered()
        scheduleNotifications()
    }

    func acknowledge() {
        escalationActive = false
        escalationDeadline = nil
    }

    // MARK: Day plan

    /// Picks up a new day and any schedule written elsewhere, such as the setup flow.
    func refreshDay() {
        let key = dayStamp()
        todayKey = key
        planItems = prefs.planItems
        doneIds = prefs.completedPlanIds(date: key)
        if let id = selectedPlanId, !planItems.contains(where: { $0.id == id }) {
            selectedPlanId = nil
            save()
        }
    }

    /// Loads an entry into the timer without starting it: the user decides when to begin.
    func selectPlan(_ item: PlanItem) {
        selectedPlanId = item.id
        applyWorkMinutes(item.minutes)
        currentCategory = item.title
        save()
        if isRunning { scheduleNotifications() }
    }

    func toggleDone(_ item: PlanItem) {
        let nowDone = !doneIds.contains(item.id)
        prefs.setPlanItemDone(date: todayKey, itemId: item.id, done: nowDone)
        if nowDone { doneIds.insert(item.id) } else { doneIds.remove(item.id) }
        // A ticked entry should not stay loaded in the timer as if it were still ahead.
        if nowDone && selectedPlanId == item.id {
            selectedPlanId = nil
            save()
        }
        if isRunning { scheduleNotifications() }
    }

    func addPlanItem(_ item: PlanItem) {
        guard planItems.count < maxPlanItems else { return }
        prefs.planItems = planItems + [item]
        planItems = prefs.planItems
        if isRunning { scheduleNotifications() }
    }

    func updatePlanItem(_ item: PlanItem) {
        prefs.planItems = planItems.map { $0.id == item.id ? item : $0 }
        planItems = prefs.planItems
        // Picking up a new length only makes sense while that entry is not mid-run.
        if selectedPlanId == item.id && !isRunning {
            selectPlan(item)
        }
        if isRunning { scheduleNotifications() }
    }

    func deletePlanItem(_ item: PlanItem) {
        prefs.planItems = planItems.filter { $0.id != item.id }
        planItems = prefs.planItems
        if selectedPlanId == item.id {
            selectedPlanId = nil
            save()
        }
        if isRunning { scheduleNotifications() }
    }

    /// The next phase changes, worked out from the current state by the same rules the timer
    /// follows: work and rest alternate, and each finished work phase moves on to the next open
    /// entry of the day when one is loaded.
    func upcomingTransitions(limit: Int) -> [PhaseTransition] {
        guard isRunning, var end = endDate else { return [] }
        var current = phase
        var work = workMinutes
        var planId = selectedPlanId
        var queue = planItems.filter { !doneIds.contains($0.id) && $0.id != selectedPlanId }
        var result: [PhaseTransition] = []
        for _ in 0..<limit {
            let next: TimerPhase = current == .work ? .rest : .work
            if current == .work && planId != nil {
                if queue.isEmpty {
                    planId = nil
                } else {
                    let item = queue.removeFirst()
                    planId = item.id
                    work = item.minutes
                }
            }
            let workTitle = planItems.first(where: { $0.id == planId })?.title ?? "Работа"
            result.append(
                PhaseTransition(at: end, endedPhase: current, nextPhase: next, nextLabel: next == .rest ? "Отдых" : workTitle)
            )
            end = end.addingTimeInterval(TimeInterval(max(1, next == .work ? work : restMinutes) * 60))
            current = next
        }
        return result
    }

    // MARK: Ticking

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // The common mode keeps the countdown moving while a list is being scrolled.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard isRunning, let end = endDate else { return }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        if remaining > 0 {
            if remaining != secondsLeft {
                secondsLeft = remaining
            }
            maybeAnnounceUpcomingPhase()
        } else {
            catchUp(alertIfJustNow: true)
        }
        // A change that happened on screen and drew no response within the grace period is
        // flagged, the way the Android service escalates a missed window.
        if let deadline = escalationDeadline, Date() >= deadline {
            escalationDeadline = nil
            escalationActive = true
            if prefs.vibrationEnabled {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }

    /// Rolls the timer forward over every phase change that is already due. A suspended app does
    /// not tick, so on return several may have passed; only one that has just happened, with the
    /// app on screen, gets the sound and the voice — the notification already announced the rest.
    private func catchUp(alertIfJustNow: Bool) {
        let now = Date()
        var changed = false
        while isRunning, let end = endDate, end <= now {
            let live = alertIfJustNow && now.timeIntervalSince(end) < 3
            finishPhase(endedAt: end, alert: live)
            changed = true
        }
        if isRunning, let end = endDate {
            secondsLeft = max(0, Int(ceil(end.timeIntervalSince(now))))
        }
        if changed {
            save()
            scheduleNotifications()
        }
    }

    private func finishPhase(endedAt: Date, alert: Bool) {
        let finished = phase
        let quote = finished == .work ? motivationalQuotes.randomElement() : nil
        recordSession(interrupted: false, quote: quote ?? "")
        if finished == .work {
            advancePlan(on: endedAt)
        }
        phase = finished == .work ? .rest : .work
        endDate = endedAt.addingTimeInterval(TimeInterval(phaseTotalSeconds))
        sessionStart = endedAt
        // Only a change seen live starts the grace period here; one that fell due while the app
        // was away has already been announced by its notifications.
        escalationDeadline = alert ? endedAt.addingTimeInterval(Self.missedWindowGrace) : nil
        announcedThisPhase = false
        if let quote {
            motivationQuote = quote
        }
        if alert {
            repeatAlert(times: finished == .work ? 3 : 1)
            if prefs.voiceAnnounceEnabled {
                let english = prefs.voiceLanguage == "English"
                let phrases = finished == .work
                    ? (english ? workDonePhrasesEN : workDonePhrasesRU)
                    : (english ? restDonePhrasesEN : restDonePhrasesRU)
                if let phrase = phrases.randomElement() {
                    speak(phrase)
                }
            }
        }
    }

    /// Finishing a work phase is what "the entry is done" means: it is ticked off and the next
    /// open entry is loaded for the following work phase while the rest runs.
    private func advancePlan(on date: Date) {
        guard let finishedId = selectedPlanId else { return }
        let key = dayStamp(date)
        prefs.setPlanItemDone(date: key, itemId: finishedId, done: true)
        if key == todayKey {
            doneIds.insert(finishedId)
        }
        let next = planItems.first { !doneIds.contains($0.id) && $0.id != finishedId }
        selectedPlanId = next?.id
        if let next {
            applyWorkMinutes(next.minutes)
            currentCategory = next.title
        }
    }

    private func applyWorkMinutes(_ minutes: Int) {
        prefs.workMinutes = minutes
        workMinutes = minutes
        if !isRunning && phase == .work {
            secondsLeft = minutes * 60
        }
    }

    private func recordSession(interrupted: Bool, quote: String) {
        guard let start = sessionStart else { return }
        let planned = phaseTotalSeconds
        let elapsed = interrupted ? max(0, planned - secondsLeft) : planned
        prefs.addHistoryEntry(
            SessionRecord(
                id: start.timeIntervalSince1970,
                phase: phase.rawValue,
                startTime: start.timeIntervalSince1970,
                durationSeconds: elapsed,
                interrupted: interrupted,
                comment: currentComment,
                category: currentCategory,
                quote: quote
            )
        )
        sessionStart = nil
        currentComment = ""
    }

    // MARK: Notifications

    private func scheduleNotifications() {
        guard isRunning else {
            NotificationScheduler.cancelAll()
            return
        }
        NotificationScheduler.schedule(
            transitions: upcomingTransitions(limit: NotificationScheduler.slots),
            sound: prefs.soundEnabled,
            headsUpLead: prefs.voiceAnnounceEnabled ? prefs.voiceAnnounceLeadSeconds() : 0,
            english: prefs.voiceLanguage == "English",
            grace: Self.missedWindowGrace
        )
    }

    // MARK: Persistence

    private func save() {
        guard !restoring else { return }
        let saved = SavedTimer(
            phase: phase,
            isRunning: isRunning,
            secondsLeft: secondsLeft,
            endDate: endDate,
            sessionStart: sessionStart,
            selectedPlanId: selectedPlanId,
            comment: currentComment,
            category: currentCategory
        )
        prefs.timerState = try? JSONEncoder().encode(saved)
    }

    private func restore() {
        guard let data = prefs.timerState,
              let saved = try? JSONDecoder().decode(SavedTimer.self, from: data) else { return }
        phase = saved.phase
        secondsLeft = saved.secondsLeft
        endDate = saved.endDate
        sessionStart = saved.sessionStart
        selectedPlanId = saved.selectedPlanId
        currentComment = saved.comment
        if !saved.category.isEmpty {
            currentCategory = saved.category
        }
        isRunning = saved.isRunning && saved.endDate != nil
    }

    // MARK: Voice and alerts

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

    private func alertUser() {
        if prefs.vibrationEnabled {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        if prefs.soundEnabled {
            AudioServicesPlaySystemSound(1005)
        }
    }

    deinit {
        ticker?.invalidate()
    }
}
