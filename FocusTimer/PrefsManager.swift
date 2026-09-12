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
