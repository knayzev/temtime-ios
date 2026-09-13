import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @State private var name = PrefsManager.shared.userName
    @State private var lastName = PrefsManager.shared.lastName
    @State private var email = PrefsManager.shared.email
    @State private var dataConsentGiven = PrefsManager.shared.dataConsentGiven
    @State private var weightKg = PrefsManager.shared.weightKg
    @State private var heightCm = PrefsManager.shared.heightCm
    @State private var age = PrefsManager.shared.age
    @State private var maritalStatus = PrefsManager.shared.maritalStatus
    @State private var gender = PrefsManager.shared.gender
    @State private var isWorking = PrefsManager.shared.isWorking
    @State private var wakeTime = Date()
    @State private var bedTime = Date()

    @State private var photoImage: Image?
    @State private var pickerItem: PhotosPickerItem?

    private let maritalOptions = [
        "Не женат / не замужем",
        "В отношениях",
        "Женат / замужем",
        "Разведён(а)",
        "Вдовец / вдова"
    ]

    private let genderOptions = ["Мужской", "Женский"]

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 100, height: 100)

                            if let photoImage {
                                photoImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: pickerItem) { newItem in
                        Task {
                            guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                            if let url = PrefsManager.shared.savePhoto(data: data),
                               let uiImage = UIImage(contentsOfFile: url.path) {
                                photoImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Основное") {
                TextField("Имя", text: $name)
                    .onChange(of: name) { PrefsManager.shared.userName = $0 }

                TextField("Фамилия", text: $lastName)
                    .onChange(of: lastName) { PrefsManager.shared.lastName = $0 }

                TextField("Почта", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .onChange(of: email) { PrefsManager.shared.email = $0 }

                Toggle("Согласен(на) на обработку персональных данных", isOn: $dataConsentGiven)
                    .onChange(of: dataConsentGiven) { PrefsManager.shared.dataConsentGiven = $0 }
            }

            Section("Параметры") {
                TextField("Вес, кг", text: $weightKg)
                    .keyboardType(.numberPad)
                    .onChange(of: weightKg) { PrefsManager.shared.weightKg = $0 }

                TextField("Рост, см", text: $heightCm)
                    .keyboardType(.numberPad)
                    .onChange(of: heightCm) { PrefsManager.shared.heightCm = $0 }

                TextField("Возраст", text: $age)
                    .keyboardType(.numberPad)
                    .onChange(of: age) { PrefsManager.shared.age = $0 }
            }

            Section("Образ жизни") {
                Picker("Пол", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: gender) { PrefsManager.shared.gender = $0 }

                Picker("Семейное положение", selection: $maritalStatus) {
                    ForEach(maritalOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: maritalStatus) { PrefsManager.shared.maritalStatus = $0 }

                DatePicker("Обычно встаю", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .onChange(of: wakeTime) { PrefsManager.shared.wakeTime = Self.dateToTimeString($0) }

                DatePicker("Обычно ложусь", selection: $bedTime, displayedComponents: .hourAndMinute)
                    .onChange(of: bedTime) { PrefsManager.shared.bedTime = Self.dateToTimeString($0) }

                Toggle("Сейчас работаю", isOn: $isWorking)
                    .onChange(of: isWorking) { PrefsManager.shared.isWorking = $0 }
            }

            Section("Персональные рекомендации") {
                ForEach(buildAdvice(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender), id: \.self) { tip in
                    Text("• \(tip)")
                }
            }
        }
        .onAppear {
            if maritalStatus.isEmpty {
                maritalStatus = maritalOptions[0]
            }
            if gender.isEmpty {
                gender = genderOptions[0]
            }
            wakeTime = Self.timeStringToDate(PrefsManager.shared.wakeTime)
            bedTime = Self.timeStringToDate(PrefsManager.shared.bedTime)
            if let url = PrefsManager.shared.photoURL,
               let uiImage = UIImage(contentsOfFile: url.path) {
                photoImage = Image(uiImage: uiImage)
            }
        }
    }

    private static func timeStringToDate(_ text: String) -> Date {
        let parts = text.split(separator: ":")
        let hour = parts.count > 0 ? Int(parts[0]) ?? 7 : 7
        let minute = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func dateToTimeString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
