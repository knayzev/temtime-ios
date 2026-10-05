import Foundation

/// Profession-aware day plans plus the reasoning shown next to each block.
///
/// Hints carry a real citation rather than a bare claim. Links point at a PubMed title search
/// instead of a hard-coded article id — the search resolves to the paper and keeps working even
/// if an id changes, and it avoids shipping a guessed URL.

private func pubmed(_ title: String) -> String {
    "https://pubmed.ncbi.nlm.nih.gov/?term=" + title.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "+")
}

struct PlanHint {
    let text: String
    var source: String = ""
    var url: String = ""
}

struct ProfessionPlanItem {
    let title: String
    let durationMinutes: Int
    var hint: PlanHint? = nil
}

struct ProfessionPreset {
    let id: String
    let name: String
    let emoji: String
    let summary: String
    let items: [ProfessionPlanItem]
}

// Shared reasoning, reused across presets so the same claim always cites the same source.

let hintPeakFocus = PlanHint(
    text: "Самую трудную задачу ставьте в первые 2–3 часа после пробуждения — внимание и рабочая память в это время обычно на суточном пике.",
    source: "Schmidt, Collette, Cajochen, Peigneux, Cognitive Neuropsychology, 2007",
    url: pubmed("A time to think circadian rhythms in human cognition")
)

let hintWorkBlock = PlanHint(
    text: "Работайте блоками по 45–60 минут с короткими перерывами: даже краткое переключение восстанавливает внимание и мешает ему «выгорать» на длинной задаче.",
    source: "Ariga, Lleras, Cognition, 2011",
    url: pubmed("Brief and rare mental breaks keep you focused")
)

let hintMorningLight = PlanHint(
    text: "Дневной свет в первый час после подъёма подстраивает циркадные ритмы — вечером легче уснуть, утром легче встать.",
    source: "Blume, Garbazza, Spitschan, Somnologie, 2019",
    url: pubmed("Effects of light on human circadian rhythms sleep and mood")
)

let hintPostLunch = PlanHint(
    text: "После обеда закономерно проседает бодрость. Ставьте сюда рутину и встречи, а не задачи, требующие максимальной концентрации.",
    source: "Monk, Clinics in Sports Medicine, 2005",
    url: pubmed("The post-lunch dip in performance")
)

let hintWalk = PlanHint(
    text: "Прогулка заметно повышает продуктивность мышления — эффект сохраняется и после того, как вы сели обратно за стол.",
    source: "Oppezzo, Schwartz, J. Experimental Psychology: LMC, 2014",
    url: pubmed("Give your ideas some legs the positive effect of walking on creative thinking")
)

let hintScreenNight = PlanHint(
    text: "Экран перед сном сдвигает выработку мелатонина и делает утреннюю бодрость хуже — уберите телефон хотя бы за час.",
    source: "Chang, Aeschbach, Duffy, Czeisler, PNAS, 2015",
    url: pubmed("Evening use of light-emitting eReaders negatively affects sleep")
)

let hintWarmShower = PlanHint(
    text: "Тёплый душ за 1–2 часа до сна ускоряет засыпание: тело активнее сбрасывает температуру, а это сигнал ко сну.",
    source: "Haghayegh et al., Sleep Medicine Reviews, 2019",
    url: pubmed("Before-bedtime passive body heating by warm shower or bath to improve sleep")
)

let hintPlanTomorrow = PlanHint(
    text: "Выписать завтрашние дела перед сном — засыпание ускоряется: чем конкретнее список, тем сильнее эффект.",
    source: "Scullin et al., J. Experimental Psychology: General, 2018",
    url: pubmed("The effects of bedtime writing on difficulty falling asleep")
)

let hintRegularity = PlanHint(
    text: "Одно и то же время подъёма и отбоя важнее общей длительности сна — нерегулярный график бьёт по результатам сильнее, чем недосып сам по себе.",
    source: "Phillips et al., Scientific Reports, 2017",
    url: pubmed("Irregular sleep wake patterns are associated with poorer academic performance")
)

let hintExercise = PlanHint(
    text: "Регулярная нагрузка улучшает сон; интенсивная тренировка ближе чем за час до сна, наоборот, мешает уснуть.",
    source: "Stutz, Eiholzer, Spengler, Sports Medicine, 2019",
    url: pubmed("Effects of evening exercise on sleep in healthy participants")
)

private let deepWorkCore = [
    ProfessionPlanItem(title: "Глубокая работа: главная задача дня", durationMinutes: 90, hint: hintPeakFocus),
    ProfessionPlanItem(title: "Перерыв без экрана", durationMinutes: 15, hint: hintWorkBlock),
    ProfessionPlanItem(title: "Глубокая работа: продолжение", durationMinutes: 60, hint: hintWorkBlock)
]

let professionPresets: [ProfessionPreset] = [
    ProfessionPreset(
        id: "dev", name: "Разработчик", emoji: "💻",
        summary: "Длинные непрерывные блоки кода утром, разборы и ревью — во второй половине дня.",
        items: deepWorkCore + [
            ProfessionPlanItem(title: "Разбор почты, задач и сообщений", durationMinutes: 30),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Код-ревью и обсуждения", durationMinutes: 60, hint: hintPostLunch),
            ProfessionPlanItem(title: "Прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Мелкие задачи и правки", durationMinutes: 60),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "design", name: "Дизайнер", emoji: "🎨",
        summary: "Творческие блоки без прерываний, сбор референсов и правки — ближе к вечеру.",
        items: [
            ProfessionPlanItem(title: "Насмотренность: референсы и идеи", durationMinutes: 30),
            ProfessionPlanItem(title: "Основной блок: макеты", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв, прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Правки по фидбеку", durationMinutes: 60, hint: hintPostLunch),
            ProfessionPlanItem(title: "Созвоны и презентация работ", durationMinutes: 45),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "manager", name: "Руководитель", emoji: "🧭",
        summary: "Встречи собраны в один блок, утро оставлено под решения, которые нельзя делегировать.",
        items: [
            ProfessionPlanItem(title: "Приоритеты дня, без почты", durationMinutes: 20, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Стратегическая задача", durationMinutes: 60, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Блок встреч", durationMinutes: 120),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Один на один с командой", durationMinutes: 60, hint: hintPostLunch),
            ProfessionPlanItem(title: "Разбор почты и решений", durationMinutes: 45),
            ProfessionPlanItem(title: "Прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "sales", name: "Продажи", emoji: "📞",
        summary: "Звонки в часы, когда клиенты доступнее всего; подготовка и CRM — вокруг них.",
        items: [
            ProfessionPlanItem(title: "Подготовка списка и скриптов", durationMinutes: 30),
            ProfessionPlanItem(title: "Блок звонков", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв", durationMinutes: 15, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Второй блок звонков", durationMinutes: 90),
            ProfessionPlanItem(title: "CRM, письма, follow-up", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Разбор результатов дня", durationMinutes: 20, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "marketing", name: "Маркетолог", emoji: "📈",
        summary: "Аналитика и тексты — на пике внимания, запуски и согласования — после обеда.",
        items: [
            ProfessionPlanItem(title: "Метрики за вчера", durationMinutes: 20),
            ProfessionPlanItem(title: "Тексты и креативы", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв, прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Запуски и согласования", durationMinutes: 60, hint: hintPostLunch),
            ProfessionPlanItem(title: "Аналитика кампаний", durationMinutes: 60),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "student", name: "Студент", emoji: "🎓",
        summary: "Учебные блоки с активным повторением, тяжёлые предметы — в первой половине дня.",
        items: [
            ProfessionPlanItem(title: "Сложный предмет", durationMinutes: 60, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв", durationMinutes: 15, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Второй блок учёбы", durationMinutes: 60, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Повторение пройденного", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Прогулка или спорт", durationMinutes: 40, hint: hintExercise),
            ProfessionPlanItem(title: "Домашние задания", durationMinutes: 60),
            ProfessionPlanItem(title: "План на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "founder", name: "Предприниматель", emoji: "🚀",
        summary: "Одна задача, двигающая бизнес, — до всех входящих. Операционка собрана в блок.",
        items: [
            ProfessionPlanItem(title: "Задача, двигающая бизнес", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв", durationMinutes: 15, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Встречи и переговоры", durationMinutes: 90),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Операционка и команда", durationMinutes: 90, hint: hintPostLunch),
            ProfessionPlanItem(title: "Прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Цифры и итоги дня", durationMinutes: 20, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "freelance", name: "Фрилансер", emoji: "🧑‍💻",
        summary: "Клиентская работа в защищённых блоках, коммуникация — в отведённые окна.",
        items: [
            ProfessionPlanItem(title: "Клиентская работа: проект №1", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв", durationMinutes: 15, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Окно для сообщений клиентам", durationMinutes: 30),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Клиентская работа: проект №2", durationMinutes: 90, hint: hintPostLunch),
            ProfessionPlanItem(title: "Поиск заказов, счета", durationMinutes: 45),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    ),
    ProfessionPreset(
        id: "other", name: "Другое", emoji: "🗂️",
        summary: "Универсальный каркас: главный блок утром, рутина после обеда, разбор вечером.",
        items: [
            ProfessionPlanItem(title: "Главная задача дня", durationMinutes: 90, hint: hintPeakFocus),
            ProfessionPlanItem(title: "Перерыв", durationMinutes: 15, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Рабочий блок", durationMinutes: 60, hint: hintWorkBlock),
            ProfessionPlanItem(title: "Обед", durationMinutes: 45, hint: hintPostLunch),
            ProfessionPlanItem(title: "Текущие дела", durationMinutes: 60, hint: hintPostLunch),
            ProfessionPlanItem(title: "Прогулка", durationMinutes: 20, hint: hintWalk),
            ProfessionPlanItem(title: "Итоги дня и план на завтра", durationMinutes: 15, hint: hintPlanTomorrow)
        ]
    )
]

func presetForProfession(_ profession: String) -> ProfessionPreset {
    professionPresets.first { $0.name.caseInsensitiveCompare(profession) == .orderedSame }
        ?? professionPresets.first { $0.id == profession }
        ?? professionPresets[professionPresets.count - 1]
}

/// Extra context the user typed is appended as its own block rather than mixed into the preset,
/// so it is visible and easy to edit instead of silently changing the generated plan.
func planItemsFor(profession: String, details: String) -> [ProfessionPlanItem] {
    let preset = presetForProfession(profession)
    let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return preset.items }
    return preset.items + [ProfessionPlanItem(title: trimmed, durationMinutes: 30)]
}

/// Hints attached to the daily rituals, shown the same way as plan hints.
let ritualHints: [String: PlanHint] = [
    "routine_water": PlanHint(text: "Стакан воды сразу после подъёма восполняет потерю жидкости за ночь и помогает проснуться."),
    "routine_exercise": hintExercise,
    "routine_daywalk": hintMorningLight,
    "routine_deepwork": hintPeakFocus,
    "routine_break": hintWorkBlock,
    "routine_lunch": hintPostLunch,
    "routine_planned": hintPlanTomorrow,
    "routine_brain_dump": hintPlanTomorrow,
    "routine_noscreen": hintScreenNight,
    "routine_warmshower": hintWarmShower,
    "routine_wake7": hintRegularity,
    "routine_bed": hintRegularity
]
