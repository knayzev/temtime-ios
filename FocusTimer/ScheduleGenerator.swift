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
    let time: String
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
    let shift: Int
    switch variant % 3 {
    case 1: shift = -30
    case 2: shift = 30
    default: shift = 0
    }

    let allSelected = answers.values.flatMap { $0 }
    let morningTips = Array(Set(allSelected.compactMap { tipLookup[$0] }.filter { $0.block == "morning" }.map { $0.tip }))
    let eveningTips = Array(Set(allSelected.compactMap { tipLookup[$0] }.filter { $0.block == "evening" }.map { $0.tip }))

    let wake = timeToMinutes(wakeTime) + shift
    let bed = timeToMinutes(bedTime) + shift
    let breakfast = timeToMinutes(breakfastTime) + shift
    let lunch = timeToMinutes(lunchTime) + shift
    let dinner = timeToMinutes(dinnerTime) + shift

    return [
        ScheduleItem(time: minutesToTime(wake), title: "Подъём", tips: Array(morningTips.prefix(2))),
        ScheduleItem(time: minutesToTime(wake + 20), title: "Утренняя рутина"),
        ScheduleItem(time: minutesToTime(breakfast), title: "Завтрак"),
        ScheduleItem(time: minutesToTime(breakfast + 30), title: "Работа", tips: ["Блоками по 45–50 минут с перерывами 10–15 минут"]),
        ScheduleItem(time: minutesToTime(lunch), title: "Обед"),
        ScheduleItem(time: minutesToTime(lunch + 60), title: "Работа"),
        ScheduleItem(time: minutesToTime(dinner), title: "Ужин"),
        ScheduleItem(time: minutesToTime(dinner + 120), title: "Вечер", tips: Array(eveningTips.prefix(2))),
        ScheduleItem(time: minutesToTime(bed), title: "Отбой", tips: Array(eveningTips.dropFirst(2).prefix(1)))
    ]
}

func scheduleToText(_ items: [ScheduleItem]) -> String {
    items.map { item in
        let tipsText = item.tips.isEmpty ? "" : " (" + item.tips.joined(separator: "; ") + ")"
        return "\(item.time) — \(item.title)\(tipsText)"
    }.joined(separator: "\n")
}
