import Foundation

struct LifestyleQuestion: Identifiable {
    let id: String
    let question: String
    let options: [String]
}

let lifestyleQuestions: [LifestyleQuestion] = [
    LifestyleQuestion(id: "q1", question: "Что мешает пробудиться?", options: [
        "Поздно лёг спать",
        "Будильник не слышу / просыпаю",
        "Нет сил встать сразу",
        "Комната тёмная, нет света",
        "Хочется доспать ещё"
    ]),
    LifestyleQuestion(id: "q2", question: "Что помогает пробудиться?", options: [
        "Будильник со звуком/светом",
        "Стакан воды сразу",
        "Открыть шторы / дневной свет",
        "Зарядка или растяжка",
        "Кофе/чай"
    ]),
    LifestyleQuestion(id: "q3", question: "Как заканчивается вечер?", options: [
        "Листаю телефон в кровати",
        "Смотрю сериалы/видео",
        "Читаю книгу",
        "Готовлюсь к следующему дню",
        "Засыпаю случайно, без чёткого времени"
    ]),
    LifestyleQuestion(id: "q4", question: "Как начинается утро?", options: [
        "Сразу хватаю телефон",
        "Завтракаю не спеша",
        "Тороплюсь, не завтракаю",
        "Делаю зарядку/растяжку",
        "Планирую день"
    ]),
    LifestyleQuestion(id: "q5", question: "Что мешает рано засыпать?", options: [
        "Долго сижу в телефоне",
        "Много дел вечером",
        "Тревожные мысли",
        "Поздний ужин/кофе",
        "Нет режима — ложусь в разное время"
    ]),
    LifestyleQuestion(id: "q6", question: "Что помогает рано засыпать?", options: [
        "Фиксированное время отбоя",
        "Убрать телефон за час до сна",
        "Тёплый душ/ванна",
        "Проветрить комнату",
        "Чтение книги перед сном"
    ])
]

struct ScheduleItem: Identifiable {
    let id = UUID()
    /// Editable: the user adjusts the suggested times before saving the schedule.
    var time: String
    let title: String
    let tips: [String]

    init(time: String, title: String, tips: [String] = []) {
        self.time = time
        self.title = title
        self.tips = tips
    }
}

private let tipLookup: [String: (block: String, tip: String)] = [
    "Поздно лёг спать": ("evening", "Старайтесь ложиться вовремя — это первый шаг к лёгкому пробуждению"),
    "Будильник не слышу / просыпаю": ("morning", "Поставьте будильник подальше от кровати"),
    "Нет сил встать сразу": ("morning", "Сразу после будильника — стакан воды и лёгкая растяжка"),
    "Комната тёмная, нет света": ("morning", "Откройте шторы или используйте лампу дневного света"),
    "Хочется доспать ещё": ("morning", "Не переносите будильник — вставайте по первому сигналу"),

    "Будильник со звуком/светом": ("morning", "Будильник с нарастающим звуком/светом облегчает пробуждение"),
    "Стакан воды сразу": ("morning", "Держите стакан воды у кровати с вечера"),
    "Открыть шторы / дневной свет": ("morning", "Откройте шторы сразу после пробуждения"),
    "Зарядка или растяжка": ("morning", "5–10 минут зарядки взбодрят лучше кофе"),
    "Кофе/чай": ("morning", "Кофе — не раньше чем через 60–90 минут после пробуждения"),

    "Листаю телефон в кровати": ("evening", "Уберите телефон за час до сна"),
    "Смотрю сериалы/видео": ("evening", "Замените экран на подкаст или книгу за час до сна"),
    "Читаю книгу": ("evening", "Отличная привычка — сохраните её"),
    "Готовлюсь к следующему дню": ("evening", "Планирование с вечера снижает тревожность утром"),
    "Засыпаю случайно, без чёткого времени": ("evening", "Установите фиксированное время отбоя"),

    "Сразу хватаю телефон": ("morning", "Отложите телефон на 20–30 минут после пробуждения"),
    "Завтракаю не спеша": ("morning", "Хорошая привычка — сохраните её"),
    "Тороплюсь, не завтракаю": ("morning", "Попробуйте вставать на 15 минут раньше ради завтрака"),
    "Делаю зарядку/растяжку": ("morning", "Отлично — так и продолжайте"),
    "Планирую день": ("morning", "Хорошая привычка — сохраните её"),

    "Долго сижу в телефоне": ("evening", "Уберите телефон за час до сна"),
    "Много дел вечером": ("evening", "Перенесите часть дел на утро"),
    "Тревожные мысли": ("evening", "Выпишите тревожные мысли на бумагу перед сном"),
    "Поздний ужин/кофе": ("evening", "Ужинайте не позднее чем за 3 часа до сна, без кофеина"),
    "Нет режима — ложусь в разное время": ("evening", "Ложитесь и вставайте в одно и то же время каждый день"),

    "Фиксированное время отбоя": ("evening", "Сохраняйте фиксированное время отбоя"),
    "Убрать телефон за час до сна": ("evening", "Продолжайте убирать телефон заранее"),
    "Тёплый душ/ванна": ("evening", "Тёплый душ за 30–60 минут до сна помогает уснуть быстрее"),
    "Проветрить комнату": ("evening", "Проветривайте спальню перед сном"),
    "Чтение книги перед сном": ("evening", "Чтение — отличная альтернатива экрану")
]

// These are represented by their own dedicated "turn off notifications" step instead of a generic
// tip line, so they are filtered out of the regular evening tips list.
private let phoneTipTexts: Set<String> = [
    "Уберите телефон за час до сна",
    "Продолжайте убирать телефон заранее"
]

/// Each variant changes more than a uniform time shift — the gaps between blocks (morning routine
/// length, work-block start delays, lunch/evening buffer) differ too, so consecutive variants are
/// actually distinguishable instead of collapsing into a barely-noticeable ±30 minute shift.
private struct ScheduleProfile {
    let wakeShift: Int
    let bedShift: Int
    let breakfastShift: Int
    let lunchShift: Int
    let dinnerShift: Int
    let morningRoutineOffset: Int
    let postBreakfastGap: Int
    let postLunchGap: Int
    let postDinnerGap: Int
}

private let scheduleProfiles = [
    ScheduleProfile(wakeShift: 0, bedShift: 0, breakfastShift: 0, lunchShift: 0, dinnerShift: 0,
                    morningRoutineOffset: 20, postBreakfastGap: 30, postLunchGap: 60, postDinnerGap: 120),
    ScheduleProfile(wakeShift: -20, bedShift: -20, breakfastShift: -10, lunchShift: -15, dinnerShift: -20,
                    morningRoutineOffset: 15, postBreakfastGap: 20, postLunchGap: 45, postDinnerGap: 90),
    ScheduleProfile(wakeShift: 20, bedShift: 20, breakfastShift: 15, lunchShift: 15, dinnerShift: 15,
                    morningRoutineOffset: 30, postBreakfastGap: 40, postLunchGap: 75, postDinnerGap: 150),
    ScheduleProfile(wakeShift: 0, bedShift: 0, breakfastShift: 10, lunchShift: -10, dinnerShift: 5,
                    morningRoutineOffset: 25, postBreakfastGap: 35, postLunchGap: 90, postDinnerGap: 105)
]

/// The tips in the order their answers were given, without repeats.
private func orderedTips(_ selected: [String], block: String) -> [String] {
    var seen = Set<String>()
    var result: [String] = []
    for answer in selected {
        guard let entry = tipLookup[answer], entry.block == block, !seen.contains(entry.tip) else { continue }
        seen.insert(entry.tip)
        result.append(entry.tip)
    }
    return result
}

private func timeToMinutes(_ text: String) -> Int {
    let parts = text.split(separator: ":")
    let h = parts.count > 0 ? Int(parts[0]) ?? 8 : 8
    let m = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
    return h * 60 + m
}

private func minutesToTime(_ total: Int) -> String {
    let normalized = ((total % 1440) + 1440) % 1440
    return String(format: "%02d:%02d", normalized / 60, normalized % 60)
}

func generateSchedule(
    answers: [String: [String]],
    wakeTime: String,
    bedTime: String,
    breakfastTime: String,
    lunchTime: String,
    dinnerTime: String,
    variant: Int
) -> [ScheduleItem] {
    let count = scheduleProfiles.count
    let profile = scheduleProfiles[((variant % count) + count) % count]

    // Answers are walked question by question so the same answers always give the same tips in
    // the same order, whichever variant is shown.
    let allSelected = lifestyleQuestions.flatMap { answers[$0.id] ?? [] }
    let morningTips = orderedTips(allSelected, block: "morning")
    let eveningTips = orderedTips(allSelected, block: "evening").filter { !phoneTipTexts.contains($0) }

    let wake = timeToMinutes(wakeTime) + profile.wakeShift
    let bed = timeToMinutes(bedTime) + profile.bedShift
    let breakfast = timeToMinutes(breakfastTime) + profile.breakfastShift
    let lunch = timeToMinutes(lunchTime) + profile.lunchShift
    let dinner = timeToMinutes(dinnerTime) + profile.dinnerShift

    return [
        ScheduleItem(time: minutesToTime(wake), title: "Подъём", tips: Array(morningTips.prefix(2))),
        ScheduleItem(time: minutesToTime(wake + profile.morningRoutineOffset), title: "Утренняя рутина"),
        ScheduleItem(time: minutesToTime(breakfast), title: "Завтрак"),
        ScheduleItem(
            time: minutesToTime(breakfast + profile.postBreakfastGap),
            title: "Работа",
            tips: ["Блоками по 45–50 минут с перерывами 10–15 минут"]
        ),
        ScheduleItem(time: minutesToTime(lunch), title: "Обед"),
        ScheduleItem(time: minutesToTime(lunch + profile.postLunchGap), title: "Работа"),
        ScheduleItem(time: minutesToTime(dinner), title: "Ужин"),
        ScheduleItem(time: minutesToTime(dinner + profile.postDinnerGap), title: "Вечер", tips: Array(eveningTips.prefix(2))),
        ScheduleItem(
            time: minutesToTime(bed - 60),
            title: "Отключить уведомления на телефоне",
            tips: ["Включите «Не беспокоить» или авиарежим — так точно уснёте вовремя"]
        ),
        ScheduleItem(time: minutesToTime(bed), title: "Отбой", tips: Array(eveningTips.dropFirst(2).prefix(1)))
    ]
}

func scheduleToText(_ items: [ScheduleItem]) -> String {
    items.map { item in
        let tipsText = item.tips.isEmpty ? "" : " (" + item.tips.joined(separator: "; ") + ")"
        return "\(item.time) — \(item.title)\(tipsText)"
    }.joined(separator: "\n")
}
