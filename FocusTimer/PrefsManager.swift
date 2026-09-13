import Foundation

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
    }

    var userName: String {
        get { defaults.string(forKey: Keys.name) ?? "" }
        set { defaults.set(newValue, forKey: Keys.name) }
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
}
