import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: TimeInterval
    let phase: String
    let startTime: TimeInterval
    let durationSeconds: Int
    let interrupted: Bool
    var comment: String
}

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
        static let wakeTime = "wake_time"
        static let bedTime = "bed_time"
        static let isWorking = "is_working"
        static let lastName = "last_name"
        static let dataConsentGiven = "data_consent_given"
        static let stepsEnabled = "steps_enabled"
        static let history = "session_history"
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
}
