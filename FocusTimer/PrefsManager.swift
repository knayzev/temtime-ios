import Foundation
import CryptoKit

func sha256(_ text: String) -> String {
    let digest = SHA256.hash(data: Data(text.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

struct TimerPreset: Codable, Identifiable {
    var id: String
    var label: String
    var workMinutes: Int
    var restMinutes: Int
    var comment: String = ""
}

let defaultPresets = [
    TimerPreset(id: "preset_work25", label: "Работа 25 мин", workMinutes: 25, restMinutes: 5),
    TimerPreset(id: "preset_deep50", label: "Глубокая работа 50 мин", workMinutes: 50, restMinutes: 10),
    TimerPreset(id: "preset_study45", label: "Учёба 45 мин", workMinutes: 45, restMinutes: 15),
    TimerPreset(id: "preset_sprint15", label: "Спринт 15 мин", workMinutes: 15, restMinutes: 5)
]

struct SessionRecord: Codable, Identifiable {
    let id: TimeInterval
    let phase: String
    let startTime: TimeInterval
    let durationSeconds: Int
    let interrupted: Bool
    var comment: String
    var category: String
    var quote: String

    init(
        id: TimeInterval,
        phase: String,
        startTime: TimeInterval,
        durationSeconds: Int,
        interrupted: Bool,
        comment: String,
        category: String = "",
        quote: String = ""
    ) {
        self.id = id
        self.phase = phase
        self.startTime = startTime
        self.durationSeconds = durationSeconds
        self.interrupted = interrupted
        self.comment = comment
        self.category = category
        self.quote = quote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(TimeInterval.self, forKey: .id)
        phase = try container.decode(String.self, forKey: .phase)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        interrupted = try container.decode(Bool.self, forKey: .interrupted)
        comment = try container.decode(String.self, forKey: .comment)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        quote = try container.decodeIfPresent(String.self, forKey: .quote) ?? ""
    }
}

let defaultCategories = ["Работа", "Учёба", "Соцсети", "Прокрастинация", "Другое"]

// MARK: - Rituals

/// Ritual periods. Stored as plain strings so they match the Android data.
let ritualMorning = "morning"
let ritualDay = "day"
let ritualEvening = "evening"
let ritualNight = "night"

let ritualPeriods = [ritualMorning, ritualDay, ritualEvening, ritualNight]

func ritualPeriodTitle(_ period: String) -> String {
    switch period {
    case ritualDay: return "День"
    case ritualEvening: return "Вечер"
    case ritualNight: return "Перед сном"
    default: return "Утро"
    }
}

func ritualPeriodEmoji(_ period: String) -> String {
    switch period {
    case ritualDay: return "☀️"
    case ritualEvening: return "🌆"
    case ritualNight: return "🌙"
    default: return "🌅"
    }
}

struct RoutineTask: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var icon: String = "✅"
    var durationMinutes: Int = 0
    var period: String = ritualMorning
}

extension RoutineTask {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "✅"
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 0
        // A task saved without a period falls back to its library entry, so it lands in the
        // right section instead of all ending up under the morning.
        let libraryPeriod = routineTaskLibrary.first { $0.id == id }?.period ?? ritualMorning
        period = try container.decodeIfPresent(String.self, forKey: .period) ?? libraryPeriod
    }
}

let routineTaskLibrary: [RoutineTask] = [
    // Утро
    RoutineTask(id: "routine_wake7", title: "Проснуться в 7 утра", icon: "⏰", durationMinutes: 0, period: ritualMorning),
    RoutineTask(id: "routine_lie5", title: "Полежать 5 минут", icon: "🛌", durationMinutes: 5, period: ritualMorning),
    RoutineTask(id: "routine_sit5", title: "Посидеть 5 минут", icon: "🧘", durationMinutes: 5, period: ritualMorning),
    RoutineTask(id: "routine_water", title: "Выпить стакан воды", icon: "💧", durationMinutes: 1, period: ritualMorning),
    RoutineTask(id: "routine_exercise", title: "Сделать зарядку", icon: "🤸", durationMinutes: 10, period: ritualMorning),
    RoutineTask(id: "routine_teeth", title: "Почистить зубы", icon: "🪥", durationMinutes: 3, period: ritualMorning),
    RoutineTask(id: "routine_shower", title: "Принять душ", icon: "🚿", durationMinutes: 10, period: ritualMorning),
    RoutineTask(id: "routine_breakfast", title: "Позавтракать", icon: "🍳", durationMinutes: 15, period: ritualMorning),
    RoutineTask(id: "routine_stretch", title: "Растяжка", icon: "🤾", durationMinutes: 10, period: ritualMorning),
    RoutineTask(id: "routine_journal", title: "Записать мысли в дневник", icon: "📓", durationMinutes: 5, period: ritualMorning),
    RoutineTask(id: "routine_plan", title: "Составить план на день", icon: "📝", durationMinutes: 5, period: ritualMorning),
    RoutineTask(id: "routine_standup", title: "Утренний созвон", icon: "📞", durationMinutes: 15, period: ritualMorning),

    // День
    RoutineTask(id: "routine_deepwork", title: "Блок глубокой работы", icon: "🎯", durationMinutes: 50, period: ritualDay),
    RoutineTask(id: "routine_break", title: "Перерыв без экрана", icon: "☕", durationMinutes: 10, period: ritualDay),
    RoutineTask(id: "routine_lunch", title: "Пообедать", icon: "🍽️", durationMinutes: 30, period: ritualDay),
    RoutineTask(id: "routine_daywalk", title: "Выйти на воздух", icon: "🌤️", durationMinutes: 15, period: ritualDay),
    RoutineTask(id: "routine_inbox", title: "Разобрать почту и сообщения", icon: "📥", durationMinutes: 20, period: ritualDay),
    RoutineTask(id: "routine_eyes", title: "Гимнастика для глаз", icon: "👀", durationMinutes: 2, period: ritualDay),
    RoutineTask(id: "routine_water_day", title: "Стакан воды", icon: "💧", durationMinutes: 1, period: ritualDay),

    // Вечер
    RoutineTask(id: "routine_dinner", title: "Поужинать", icon: "🍲", durationMinutes: 30, period: ritualEvening),
    RoutineTask(id: "routine_evwalk", title: "Вечерняя прогулка", icon: "🚶", durationMinutes: 20, period: ritualEvening),
    RoutineTask(id: "routine_tidy", title: "Прибраться на столе", icon: "🧹", durationMinutes: 10, period: ritualEvening),
    RoutineTask(id: "routine_review", title: "Подвести итоги дня", icon: "✅", durationMinutes: 10, period: ritualEvening),
    RoutineTask(id: "routine_planned", title: "Спланировать завтра", icon: "🗓️", durationMinutes: 10, period: ritualEvening),
    RoutineTask(id: "routine_family", title: "Время с близкими", icon: "❤️", durationMinutes: 30, period: ritualEvening),

    // Перед сном
    RoutineTask(id: "routine_noscreen", title: "Убрать телефон", icon: "📵", durationMinutes: 0, period: ritualNight),
    RoutineTask(id: "routine_warmshower", title: "Тёплый душ", icon: "🛁", durationMinutes: 15, period: ritualNight),
    RoutineTask(id: "routine_air", title: "Проветрить спальню", icon: "🪟", durationMinutes: 10, period: ritualNight),
    RoutineTask(id: "routine_read", title: "Чтение книги", icon: "📖", durationMinutes: 20, period: ritualNight),
    RoutineTask(id: "routine_brain_dump", title: "Выписать тревожные мысли", icon: "📝", durationMinutes: 5, period: ritualNight),
    RoutineTask(id: "routine_breath", title: "Дыхание 4-7-8", icon: "🌬️", durationMinutes: 5, period: ritualNight),
    RoutineTask(id: "routine_bed", title: "Отбой", icon: "😴", durationMinutes: 0, period: ritualNight)
]

let defaultRoutineTasks: [RoutineTask] = [
    "routine_wake7", "routine_water", "routine_exercise", "routine_teeth", "routine_breakfast",
    "routine_deepwork", "routine_lunch", "routine_daywalk",
    "routine_dinner", "routine_review", "routine_planned",
    "routine_noscreen", "routine_air", "routine_bed"
].compactMap { id in routineTaskLibrary.first { $0.id == id } }

// MARK: - Day plan

/// One entry in the day's schedule: a single activity with its own clock time and length.
struct PlanItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    /// When it happens, as "HH:MM".
    var time: String
    var minutes: Int
    var comment: String = ""
}

extension PlanItem {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? "09:00"
        minutes = try container.decodeIfPresent(Int.self, forKey: .minutes) ?? 30
        comment = try container.decodeIfPresent(String.self, forKey: .comment) ?? ""
    }
}

/// How many entries one day may hold.
let maxPlanItems = 20

/// A suggested activity with a default clock time, ordered from waking up to going to bed.
struct PlanLibraryEntry {
    let id: String
    let title: String
    let minutes: Int
    let time: String
}

let planTaskLibrary: [PlanLibraryEntry] = [
    PlanLibraryEntry(id: "plantask_wake", title: "Проснуться", minutes: 1, time: "06:30"),
    PlanLibraryEntry(id: "plantask_water", title: "Стакан воды", minutes: 1, time: "06:35"),
    PlanLibraryEntry(id: "plantask_exercise", title: "Зарядка", minutes: 15, time: "06:45"),
    PlanLibraryEntry(id: "plantask_stretch", title: "Растяжка", minutes: 10, time: "07:00"),
    PlanLibraryEntry(id: "plantask_shower", title: "Душ", minutes: 10, time: "07:15"),
    PlanLibraryEntry(id: "plantask_teeth", title: "Почистить зубы", minutes: 3, time: "07:25"),
    PlanLibraryEntry(id: "plantask_breakfast", title: "Завтрак", minutes: 25, time: "07:30"),
    PlanLibraryEntry(id: "plantask_plan", title: "Планирование дня", minutes: 10, time: "08:00"),
    PlanLibraryEntry(id: "plantask_meditate", title: "Медитация", minutes: 10, time: "08:10"),
    PlanLibraryEntry(id: "plantask_commute_work", title: "Дорога на работу", minutes: 30, time: "08:20"),
    PlanLibraryEntry(id: "plantask_deep_work", title: "Глубокая работа", minutes: 90, time: "09:00"),
    PlanLibraryEntry(id: "plantask_mail", title: "Разбор почты", minutes: 20, time: "10:30"),
    PlanLibraryEntry(id: "plantask_calls", title: "Созвоны", minutes: 45, time: "11:00"),
    PlanLibraryEntry(id: "plantask_snack", title: "Перекус", minutes: 10, time: "11:45"),
    PlanLibraryEntry(id: "plantask_work", title: "Рабочий блок", minutes: 60, time: "12:00"),
    PlanLibraryEntry(id: "plantask_lunch", title: "Обед", minutes: 40, time: "13:00"),
    PlanLibraryEntry(id: "plantask_walk_lunch", title: "Прогулка после обеда", minutes: 20, time: "13:40"),
    PlanLibraryEntry(id: "plantask_work_second", title: "Рабочий блок, вторая половина", minutes: 90, time: "14:00"),
    PlanLibraryEntry(id: "plantask_break", title: "Перерыв", minutes: 15, time: "15:30"),
    PlanLibraryEntry(id: "plantask_study", title: "Учёба и развитие", minutes: 45, time: "16:00"),
    PlanLibraryEntry(id: "plantask_tomorrow", title: "Разбор задач на завтра", minutes: 15, time: "17:30"),
    PlanLibraryEntry(id: "plantask_commute_home", title: "Дорога домой", minutes: 30, time: "18:00"),
    PlanLibraryEntry(id: "plantask_gym", title: "Тренажёрный зал", minutes: 75, time: "18:30"),
    PlanLibraryEntry(id: "plantask_shower_gym", title: "Душ после зала", minutes: 15, time: "20:00"),
    PlanLibraryEntry(id: "plantask_dinner", title: "Ужин", minutes: 30, time: "20:20"),
    PlanLibraryEntry(id: "plantask_family", title: "Время с близкими", minutes: 45, time: "21:00"),
    PlanLibraryEntry(id: "plantask_read", title: "Чтение", minutes: 30, time: "21:45"),
    PlanLibraryEntry(id: "plantask_walk_evening", title: "Прогулка перед сном", minutes: 20, time: "22:15"),
    PlanLibraryEntry(id: "plantask_no_screens", title: "Без экранов", minutes: 30, time: "22:35"),
    PlanLibraryEntry(id: "plantask_bed_prep", title: "Подготовка ко сну", minutes: 15, time: "23:00"),
    PlanLibraryEntry(id: "plantask_sleep", title: "Отбой", minutes: 1, time: "23:15")
]

/// Entries offered as one-tap fills when adding, so the quick path is not another long list.
let planQuickFillTitles = [
    "Завтрак", "Зарядка", "Глубокая работа", "Созвоны", "Обед",
    "Прогулка после обеда", "Рабочий блок", "Учёба и развитие", "Тренажёрный зал", "Ужин", "Чтение"
]

// MARK: - Storage

final class PrefsManager {
    static let shared = PrefsManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let name = "user_name"
        static let photoFileName = "photo_file_name"
        static let workMinutes = "work_minutes"
        static let restMinutes = "rest_minutes"
        static let sound = "sound_enabled"
        static let vibration = "vibration_enabled"
        static let keepScreenOn = "keep_screen_on"
        static let email = "email"
        static let weightKg = "weight_kg"
        static let heightCm = "height_cm"
        static let age = "age"
        static let maritalStatus = "marital_status"
        static let gender = "gender"
        static let personalityType = "personality_type"
        static let nightWakeFrequency = "night_wake_frequency"
        static let wakeTime = "wake_time"
        static let bedTime = "bed_time"
        static let isWorking = "is_working"
        static let lastName = "last_name"
        static let dataConsentGiven = "data_consent_given"
        static let stepsEnabled = "steps_enabled"
        static let history = "session_history"
        static let categories = "categories"
        static let passwordHash = "account_password_hash"
        static let isRegistered = "is_registered"
        static let isLoggedIn = "is_logged_in"
        static let isOnboarded = "is_onboarded"
        static let breakfastTime = "breakfast_time"
        static let lunchTime = "lunch_time"
        static let dinnerTime = "dinner_time"
        static let workHoursPerDay = "work_hours_per_day"
        static let mealsPerDay = "meals_per_day"
        static let waterUnit = "water_unit"
        static let waterCount = "water_count"
        static let presets = "timer_presets"
        static let voiceAnnounceEnabled = "voice_announce_enabled"
        static let voiceAnnounceValue = "voice_announce_value"
        static let voiceAnnounceUnit = "voice_announce_unit"
        static let voiceLanguage = "voice_language"
        static let daySchedule = "day_schedule"
        static let lifestyleAnswers = "lifestyle_answers"
        static let profession = "profession"
        static let professionDetails = "profession_details"
        static let focusW1Start = "focus_w1_start"
        static let focusW1End = "focus_w1_end"
        static let focusW2Start = "focus_w2_start"
        static let focusW2End = "focus_w2_end"
        static let routineTasks = "routine_tasks"
        static let routineCompletions = "routine_completions"
        static let daySummaries = "day_summaries"
        static let planItems = "plan_items"
        static let planCompletions = "plan_completions"
        static let wordSeen = "word_seen_date"
        static let timerState = "timer_state"
    }

    var userName: String {
        get { defaults.string(forKey: Keys.name) ?? "" }
        set { defaults.set(newValue, forKey: Keys.name) }
    }

    var lastName: String {
        get { defaults.string(forKey: Keys.lastName) ?? "" }
        set { defaults.set(newValue, forKey: Keys.lastName) }
    }

    var dataConsentGiven: Bool {
        get { defaults.object(forKey: Keys.dataConsentGiven) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.dataConsentGiven) }
    }

    /// Drives which day-plan preset and advice the generator picks.
    var profession: String {
        get { defaults.string(forKey: Keys.profession) ?? "" }
        set { defaults.set(newValue, forKey: Keys.profession) }
    }

    /// Free-form extra context the user adds on top of the profession.
    var professionDetails: String {
        get { defaults.string(forKey: Keys.professionDetails) ?? "" }
        set { defaults.set(newValue, forKey: Keys.professionDetails) }
    }

    /// Two productivity windows the stats are grouped by, so a morning block and an afternoon
    /// block can be compared instead of disappearing into one daily total.
    var focusWindowOneStart: String {
        get { defaults.string(forKey: Keys.focusW1Start) ?? "08:00" }
        set { defaults.set(newValue, forKey: Keys.focusW1Start) }
    }

    var focusWindowOneEnd: String {
        get { defaults.string(forKey: Keys.focusW1End) ?? "15:00" }
        set { defaults.set(newValue, forKey: Keys.focusW1End) }
    }

    var focusWindowTwoStart: String {
        get { defaults.string(forKey: Keys.focusW2Start) ?? "15:30" }
        set { defaults.set(newValue, forKey: Keys.focusW2Start) }
    }

    var focusWindowTwoEnd: String {
        get { defaults.string(forKey: Keys.focusW2End) ?? "19:00" }
        set { defaults.set(newValue, forKey: Keys.focusW2End) }
    }

    var voiceAnnounceEnabled: Bool {
        get { defaults.object(forKey: Keys.voiceAnnounceEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.voiceAnnounceEnabled) }
    }

    var voiceAnnounceLeadValue: Int {
        get { defaults.object(forKey: Keys.voiceAnnounceValue) as? Int ?? 30 }
        set { defaults.set(newValue, forKey: Keys.voiceAnnounceValue) }
    }

    var voiceAnnounceUnit: String {
        get { defaults.string(forKey: Keys.voiceAnnounceUnit) ?? "Секунды" }
        set { defaults.set(newValue, forKey: Keys.voiceAnnounceUnit) }
    }

    func voiceAnnounceLeadSeconds() -> Int {
        voiceAnnounceUnit == "Минуты" ? voiceAnnounceLeadValue * 60 : voiceAnnounceLeadValue
    }

    var voiceLanguage: String {
        get { defaults.string(forKey: Keys.voiceLanguage) ?? "Русский" }
        set { defaults.set(newValue, forKey: Keys.voiceLanguage) }
    }

    var stepsEnabled: Bool {
        get { defaults.object(forKey: Keys.stepsEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.stepsEnabled) }
    }

    private var photoFileName: String? {
        get { defaults.string(forKey: Keys.photoFileName) }
        set { defaults.set(newValue, forKey: Keys.photoFileName) }
    }

    var workMinutes: Int {
        get { defaults.object(forKey: Keys.workMinutes) as? Int ?? 25 }
        set { defaults.set(newValue, forKey: Keys.workMinutes) }
    }

    var restMinutes: Int {
        get { defaults.object(forKey: Keys.restMinutes) as? Int ?? 5 }
        set { defaults.set(newValue, forKey: Keys.restMinutes) }
    }

    var soundEnabled: Bool {
        get { defaults.object(forKey: Keys.sound) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.sound) }
    }

    var vibrationEnabled: Bool {
        get { defaults.object(forKey: Keys.vibration) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.vibration) }
    }

    var keepScreenOn: Bool {
        get { defaults.object(forKey: Keys.keepScreenOn) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.keepScreenOn) }
    }

    var email: String {
        get { defaults.string(forKey: Keys.email) ?? "" }
        set { defaults.set(newValue, forKey: Keys.email) }
    }

    var weightKg: String {
        get { defaults.string(forKey: Keys.weightKg) ?? "" }
        set { defaults.set(newValue, forKey: Keys.weightKg) }
    }

    var heightCm: String {
        get { defaults.string(forKey: Keys.heightCm) ?? "" }
        set { defaults.set(newValue, forKey: Keys.heightCm) }
    }

    var age: String {
        get { defaults.string(forKey: Keys.age) ?? "" }
        set { defaults.set(newValue, forKey: Keys.age) }
    }

    var maritalStatus: String {
        get { defaults.string(forKey: Keys.maritalStatus) ?? "" }
        set { defaults.set(newValue, forKey: Keys.maritalStatus) }
    }

    var gender: String {
        get { defaults.string(forKey: Keys.gender) ?? "" }
        set { defaults.set(newValue, forKey: Keys.gender) }
    }

    var personalityType: String {
        get { defaults.string(forKey: Keys.personalityType) ?? "" }
        set { defaults.set(newValue, forKey: Keys.personalityType) }
    }

    var nightWakeFrequency: String {
        get { defaults.string(forKey: Keys.nightWakeFrequency) ?? "" }
        set { defaults.set(newValue, forKey: Keys.nightWakeFrequency) }
    }

    var wakeTime: String {
        get { defaults.string(forKey: Keys.wakeTime) ?? "07:00" }
        set { defaults.set(newValue, forKey: Keys.wakeTime) }
    }

    var bedTime: String {
        get { defaults.string(forKey: Keys.bedTime) ?? "23:00" }
        set { defaults.set(newValue, forKey: Keys.bedTime) }
    }

    var isWorking: Bool {
        get { defaults.object(forKey: Keys.isWorking) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.isWorking) }
    }

    var categories: [String] {
        get { defaults.stringArray(forKey: Keys.categories) ?? defaultCategories }
        set { defaults.set(newValue, forKey: Keys.categories) }
    }

    var daySchedule: String {
        get { defaults.string(forKey: Keys.daySchedule) ?? "" }
        set { defaults.set(newValue, forKey: Keys.daySchedule) }
    }

    var lifestyleAnswers: [String: [String]] {
        get { (defaults.dictionary(forKey: Keys.lifestyleAnswers) as? [String: [String]]) ?? [:] }
        set { defaults.set(newValue, forKey: Keys.lifestyleAnswers) }
    }

    var accountPasswordHash: String {
        get { defaults.string(forKey: Keys.passwordHash) ?? "" }
        set { defaults.set(newValue, forKey: Keys.passwordHash) }
    }

    var isRegistered: Bool {
        get { defaults.object(forKey: Keys.isRegistered) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.isRegistered) }
    }

    var isLoggedIn: Bool {
        get { defaults.object(forKey: Keys.isLoggedIn) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.isLoggedIn) }
    }

    var isOnboarded: Bool {
        get { defaults.object(forKey: Keys.isOnboarded) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.isOnboarded) }
    }

    var breakfastTime: String {
        get { defaults.string(forKey: Keys.breakfastTime) ?? "08:00" }
        set { defaults.set(newValue, forKey: Keys.breakfastTime) }
    }

    var lunchTime: String {
        get { defaults.string(forKey: Keys.lunchTime) ?? "13:00" }
        set { defaults.set(newValue, forKey: Keys.lunchTime) }
    }

    var dinnerTime: String {
        get { defaults.string(forKey: Keys.dinnerTime) ?? "19:00" }
        set { defaults.set(newValue, forKey: Keys.dinnerTime) }
    }

    var workHoursPerDay: Int {
        get { defaults.object(forKey: Keys.workHoursPerDay) as? Int ?? 8 }
        set { defaults.set(newValue, forKey: Keys.workHoursPerDay) }
    }

    var mealsPerDay: Int {
        get { defaults.object(forKey: Keys.mealsPerDay) as? Int ?? 3 }
        set { defaults.set(newValue, forKey: Keys.mealsPerDay) }
    }

    var waterUnit: String {
        get { defaults.string(forKey: Keys.waterUnit) ?? "Бутылки" }
        set { defaults.set(newValue, forKey: Keys.waterUnit) }
    }

    var waterCount: Int {
        get { defaults.object(forKey: Keys.waterCount) as? Int ?? 4 }
        set { defaults.set(newValue, forKey: Keys.waterCount) }
    }

    var presets: [TimerPreset] {
        get { decoded([TimerPreset].self, forKey: Keys.presets) ?? defaultPresets }
        set { encode(newValue, forKey: Keys.presets) }
    }

    // MARK: Rituals

    var routineTasks: [RoutineTask] {
        get { decoded([RoutineTask].self, forKey: Keys.routineTasks) ?? defaultRoutineTasks }
        set { encode(newValue, forKey: Keys.routineTasks) }
    }

    private var routineCompletions: [String: [String]] {
        get { (defaults.dictionary(forKey: Keys.routineCompletions) as? [String: [String]]) ?? [:] }
        set { defaults.set(newValue, forKey: Keys.routineCompletions) }
    }

    func completedRoutineIds(date: String) -> Set<String> {
        Set(routineCompletions[date] ?? [])
    }

    func setRoutineTaskDone(date: String, taskId: String, done: Bool) {
        var all = routineCompletions
        var current = Set(all[date] ?? [])
        if done { current.insert(taskId) } else { current.remove(taskId) }
        all[date] = Array(current)
        routineCompletions = all
    }

    /// Consecutive-day streak for a task, counted backward from today. If today isn't done yet
    /// the streak still reflects the run ending yesterday, so it doesn't drop to zero mid-day.
    func routineStreak(taskId: String, today: String, previousDates: [String]) -> Int {
        let all = routineCompletions
        var streak = (all[today] ?? []).contains(taskId) ? 1 : 0
        for date in previousDates {
            if (all[date] ?? []).contains(taskId) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var daySummaries: [String: String] {
        get { (defaults.dictionary(forKey: Keys.daySummaries) as? [String: String]) ?? [:] }
        set { defaults.set(newValue, forKey: Keys.daySummaries) }
    }

    func daySummary(date: String) -> String {
        daySummaries[date] ?? ""
    }

    func setDaySummary(date: String, text: String) {
        var all = daySummaries
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            all.removeValue(forKey: date)
        } else {
            all[date] = text
        }
        daySummaries = all
    }

    // MARK: Day plan

    var planItems: [PlanItem] {
        get { (decoded([PlanItem].self, forKey: Keys.planItems) ?? []).sorted { $0.time < $1.time } }
        set { encode(newValue.sorted { $0.time < $1.time }, forKey: Keys.planItems) }
    }

    private var planCompletions: [String: [String]] {
        get { (defaults.dictionary(forKey: Keys.planCompletions) as? [String: [String]]) ?? [:] }
        set { defaults.set(newValue, forKey: Keys.planCompletions) }
    }

    func completedPlanIds(date: String) -> Set<String> {
        Set(planCompletions[date] ?? [])
    }

    func setPlanItemDone(date: String, itemId: String, done: Bool) {
        var all = planCompletions
        var current = Set(all[date] ?? [])
        if done { current.insert(itemId) } else { current.remove(itemId) }
        all[date] = Array(current)
        planCompletions = all
    }

    /// The day whose term of the day has already been dismissed.
    var wordSeenDate: String {
        get { defaults.string(forKey: Keys.wordSeen) ?? "" }
        set { defaults.set(newValue, forKey: Keys.wordSeen) }
    }

    /// The running timer, kept so a relaunch picks the countdown up where it was.
    var timerState: Data? {
        get { defaults.data(forKey: Keys.timerState) }
        set { defaults.set(newValue, forKey: Keys.timerState) }
    }

    // MARK: Photo

    var photoURL: URL? {
        guard let name = photoFileName else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(name)
    }

    @discardableResult
    func savePhoto(data: Data) -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileName = "profile_photo.jpg"
        let url = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            photoFileName = fileName
            return url
        } catch {
            return nil
        }
    }

    // MARK: History

    private static let maxHistoryEntries = 300

    var history: [SessionRecord] {
        get { decoded([SessionRecord].self, forKey: Keys.history) ?? [] }
        set { encode(newValue, forKey: Keys.history) }
    }

    func addHistoryEntry(_ entry: SessionRecord) {
        var current = history
        current.insert(entry, at: 0)
        if current.count > Self.maxHistoryEntries {
            current = Array(current.prefix(Self.maxHistoryEntries))
        }
        history = current
    }

    func updateHistoryComment(id: TimeInterval, comment: String) {
        var current = history
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].comment = comment
            history = current
        }
    }

    // MARK: Export / import

    func exportAllData() -> String {
        let profile: [String: Any] = [
            "userName": userName,
            "lastName": lastName,
            "profession": profession,
            "professionDetails": professionDetails,
            "focusWindowOneStart": focusWindowOneStart,
            "focusWindowOneEnd": focusWindowOneEnd,
            "focusWindowTwoStart": focusWindowTwoStart,
            "focusWindowTwoEnd": focusWindowTwoEnd,
            "email": email,
            "dataConsentGiven": dataConsentGiven,
            "weightKg": weightKg,
            "heightCm": heightCm,
            "age": age,
            "gender": gender,
            "maritalStatus": maritalStatus,
            "wakeTime": wakeTime,
            "bedTime": bedTime,
            "isWorking": isWorking,
            "breakfastTime": breakfastTime,
            "lunchTime": lunchTime,
            "dinnerTime": dinnerTime,
            "workHoursPerDay": workHoursPerDay,
            "mealsPerDay": mealsPerDay,
            "waterUnit": waterUnit,
            "waterCount": waterCount
        ]
        let settings: [String: Any] = [
            "workMinutes": workMinutes,
            "restMinutes": restMinutes,
            "soundEnabled": soundEnabled,
            "vibrationEnabled": vibrationEnabled,
            "keepScreenOn": keepScreenOn,
            "categories": categories
        ]
        let historyArray: [[String: Any]] = history.map { entry in
            [
                "id": entry.id,
                "phase": entry.phase,
                "startTime": entry.startTime,
                "durationSeconds": entry.durationSeconds,
                "interrupted": entry.interrupted,
                "comment": entry.comment,
                "category": entry.category
            ]
        }
        let root: [String: Any] = [
            "exportVersion": 1,
            "profile": profile,
            "settings": settings,
            "history": historyArray
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    func importAllData(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        if let profile = root["profile"] as? [String: Any] {
            if let v = profile["userName"] as? String { userName = v }
            if let v = profile["lastName"] as? String { lastName = v }
            if let v = profile["profession"] as? String { profession = v }
            if let v = profile["professionDetails"] as? String { professionDetails = v }
            if let v = profile["focusWindowOneStart"] as? String { focusWindowOneStart = v }
            if let v = profile["focusWindowOneEnd"] as? String { focusWindowOneEnd = v }
            if let v = profile["focusWindowTwoStart"] as? String { focusWindowTwoStart = v }
            if let v = profile["focusWindowTwoEnd"] as? String { focusWindowTwoEnd = v }
            if let v = profile["email"] as? String { email = v }
            if let v = profile["dataConsentGiven"] as? Bool { dataConsentGiven = v }
            if let v = profile["weightKg"] as? String { weightKg = v }
            if let v = profile["heightCm"] as? String { heightCm = v }
            if let v = profile["age"] as? String { age = v }
            if let v = profile["gender"] as? String { gender = v }
            if let v = profile["maritalStatus"] as? String { maritalStatus = v }
            if let v = profile["wakeTime"] as? String { wakeTime = v }
            if let v = profile["bedTime"] as? String { bedTime = v }
            if let v = profile["isWorking"] as? Bool { isWorking = v }
            if let v = profile["breakfastTime"] as? String { breakfastTime = v }
            if let v = profile["lunchTime"] as? String { lunchTime = v }
            if let v = profile["dinnerTime"] as? String { dinnerTime = v }
            if let v = profile["workHoursPerDay"] as? Int { workHoursPerDay = v }
            if let v = profile["mealsPerDay"] as? Int { mealsPerDay = v }
            if let v = profile["waterUnit"] as? String { waterUnit = v }
            if let v = profile["waterCount"] as? Int { waterCount = v }
        }
        if let settingsDict = root["settings"] as? [String: Any] {
            if let v = settingsDict["workMinutes"] as? Int { workMinutes = v }
            if let v = settingsDict["restMinutes"] as? Int { restMinutes = v }
            if let v = settingsDict["soundEnabled"] as? Bool { soundEnabled = v }
            if let v = settingsDict["vibrationEnabled"] as? Bool { vibrationEnabled = v }
            if let v = settingsDict["keepScreenOn"] as? Bool { keepScreenOn = v }
            if let v = settingsDict["categories"] as? [String] { categories = v }
        }
        if let historyArray = root["history"] as? [[String: Any]] {
            let imported: [SessionRecord] = historyArray.compactMap { obj in
                // The Android export stores milliseconds under "startTimeMillis"; this one stores
                // seconds under "startTime". Either is accepted, so a backup moves between phones.
                let startTime: TimeInterval
                if let seconds = obj["startTime"] as? TimeInterval {
                    startTime = seconds
                } else if let millis = obj["startTimeMillis"] as? TimeInterval {
                    startTime = millis / 1000
                } else {
                    return nil
                }
                guard let phase = obj["phase"] as? String,
                      let durationSeconds = obj["durationSeconds"] as? Int,
                      let interrupted = obj["interrupted"] as? Bool else {
                    return nil
                }
                return SessionRecord(
                    id: startTime,
                    phase: phase,
                    startTime: startTime,
                    durationSeconds: durationSeconds,
                    interrupted: interrupted,
                    comment: obj["comment"] as? String ?? "",
                    category: obj["category"] as? String ?? "",
                    quote: obj["quote"] as? String ?? ""
                )
            }
            history = imported.sorted { $0.startTime > $1.startTime }
        }
        return true
    }

    // MARK: Codable helpers

    private func decoded<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
