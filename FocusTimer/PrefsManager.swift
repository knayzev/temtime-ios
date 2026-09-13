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
        get {
            guard let data = defaults.data(forKey: Keys.presets),
                  let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) else {
                return defaultPresets
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.presets)
            }
        }
    }

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

    private static let maxHistoryEntries = 300

    var history: [SessionRecord] {
        get {
            guard let data = defaults.data(forKey: Keys.history),
                  let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.history)
            }
        }
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

    func exportAllData() -> String {
        let profile: [String: Any] = [
            "userName": userName,
            "lastName": lastName,
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
                guard let id = obj["id"] as? TimeInterval,
                      let phase = obj["phase"] as? String,
                      let startTime = obj["startTime"] as? TimeInterval,
                      let durationSeconds = obj["durationSeconds"] as? Int,
                      let interrupted = obj["interrupted"] as? Bool else {
                    return nil
                }
                let comment = obj["comment"] as? String ?? ""
                let category = obj["category"] as? String ?? ""
                return SessionRecord(
                    id: id,
                    phase: phase,
                    startTime: startTime,
                    durationSeconds: durationSeconds,
                    interrupted: interrupted,
                    comment: comment,
                    category: category
                )
            }
            history = imported.sorted { $0.startTime > $1.startTime }
        }
        return true
    }
}
