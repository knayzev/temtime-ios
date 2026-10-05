import SwiftUI

private let maritalOptions = [
    "Не женат / не замужем",
    "В отношениях",
    "Женат / замужем",
    "Разведён(а)",
    "Вдовец / вдова"
]

private let genderOptions = ["Мужской", "Женский"]

private let personalityOptions = ["Интроверт", "Экстраверт", "Амбиверт"]

private let nightWakeOptions = ["Не просыпаюсь", "1 раз", "2–3 раза", "Часто (4+)"]

/// The long questionnaire. Setup no longer walks through it, but it is the only place some of
/// the schedule and advice inputs are collected, so it is opened from the profile. Every answer
/// is saved as it is given.
struct OnboardingScreen: View {
    let onComplete: () -> Void

    @State private var userName = PrefsManager.shared.userName
    @State private var profession = PrefsManager.shared.profession.isEmpty
        ? professionPresets[0].name
        : PrefsManager.shared.profession
    @State private var professionDetails = PrefsManager.shared.professionDetails

    @State private var weightKg = PrefsManager.shared.weightKg
    @State private var heightCm = PrefsManager.shared.heightCm
    @State private var age = PrefsManager.shared.age
    @State private var gender = PrefsManager.shared.gender.isEmpty ? genderOptions[0] : PrefsManager.shared.gender
    @State private var maritalStatus = PrefsManager.shared.maritalStatus.isEmpty
        ? maritalOptions[0]
        : PrefsManager.shared.maritalStatus
    @State private var personalityType = PrefsManager.shared.personalityType.isEmpty
        ? personalityOptions[2]
        : PrefsManager.shared.personalityType
    @State private var nightWakeFrequency = PrefsManager.shared.nightWakeFrequency.isEmpty
        ? nightWakeOptions[0]
        : PrefsManager.shared.nightWakeFrequency

    @State private var bedTime = PrefsManager.shared.bedTime
    @State private var wakeTime = PrefsManager.shared.wakeTime
    @State private var breakfastTime = PrefsManager.shared.breakfastTime
    @State private var lunchTime = PrefsManager.shared.lunchTime
    @State private var dinnerTime = PrefsManager.shared.dinnerTime
    @State private var mealsPerDay = PrefsManager.shared.mealsPerDay
    @State private var waterUnit = PrefsManager.shared.waterUnit
    @State private var waterCount = PrefsManager.shared.waterCount
    @State private var workHours = PrefsManager.shared.workHoursPerDay

    var body: some View {
        Form {
            Section {
                HeroGlyph(emoji: "🙋", size: 72)
                Text("Расскажите о себе и своём дне")
                    .font(.title2.bold())
                Text("Это поможет предложить точный график дня и советы")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Как вас зовут") {
                TextField("Имя", text: $userName)
                    .onChange(of: userName) { PrefsManager.shared.userName = $0 }
            }

            Section {
                Picker("Специальность", selection: $profession) {
                    ForEach(professionPresets, id: \.id) { preset in
                        Text("\(preset.emoji) \(preset.name)").tag(preset.name)
                    }
                }
                .onChange(of: profession) { PrefsManager.shared.profession = $0 }
                Text(presetForProfession(profession).summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Что добавить к плану (необязательно)", text: $professionDetails, axis: .vertical)
                    .lineLimit(2...4)
                    .onChange(of: professionDetails) { PrefsManager.shared.professionDetails = $0 }
            } header: {
                Text("Чем вы занимаетесь")
            } footer: {
                Text("По профессии подберём план дня: что ставить на пик концентрации, а что — после обеда. Например, можно добавить: каждый вторник двухчасовая планёрка.")
            }

            Section("О себе") {
                LabeledNumberField(label: "Вес, кг", text: $weightKg)
                    .onChange(of: weightKg) { PrefsManager.shared.weightKg = $0 }
                LabeledNumberField(label: "Рост, см", text: $heightCm)
                    .onChange(of: heightCm) { PrefsManager.shared.heightCm = $0 }
                LabeledNumberField(label: "Возраст", text: $age)
                    .onChange(of: age) { PrefsManager.shared.age = $0 }
                Picker("Пол", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: gender) { PrefsManager.shared.gender = $0 }
                Picker("Семейное положение", selection: $maritalStatus) {
                    ForEach(maritalOptions, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: maritalStatus) { PrefsManager.shared.maritalStatus = $0 }
            }

            Section("Психологический портрет") {
                Picker("Тип", selection: $personalityType) {
                    ForEach(personalityOptions, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: personalityType) { PrefsManager.shared.personalityType = $0 }
            }

            Section("Сон") {
                Picker("Просыпаетесь ночью", selection: $nightWakeFrequency) {
                    ForEach(nightWakeOptions, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: nightWakeFrequency) { PrefsManager.shared.nightWakeFrequency = $0 }
                ClockPicker(label: "Во сколько отбой", time: $bedTime)
                    .onChange(of: bedTime) { PrefsManager.shared.bedTime = $0 }
                ClockPicker(label: "Во сколько подъём", time: $wakeTime)
                    .onChange(of: wakeTime) { PrefsManager.shared.wakeTime = $0 }
            }

            Section("Питание") {
                ClockPicker(label: "Завтракаете", time: $breakfastTime)
                    .onChange(of: breakfastTime) { PrefsManager.shared.breakfastTime = $0 }
                ClockPicker(label: "Обедаете", time: $lunchTime)
                    .onChange(of: lunchTime) { PrefsManager.shared.lunchTime = $0 }
                ClockPicker(label: "Ужинаете", time: $dinnerTime)
                    .onChange(of: dinnerTime) { PrefsManager.shared.dinnerTime = $0 }
                Stepper("Приёмов пищи в день: \(mealsPerDay)", value: $mealsPerDay, in: 1...6)
                    .onChange(of: mealsPerDay) { PrefsManager.shared.mealsPerDay = $0 }
                Picker("Считать воду в", selection: $waterUnit) {
                    Text("Бутылки").tag("Бутылки")
                    Text("Чай/кофе").tag("Чай/кофе")
                }
                .pickerStyle(.segmented)
                .onChange(of: waterUnit) { PrefsManager.shared.waterUnit = $0 }
                Stepper(
                    waterUnit == "Бутылки" ? "Бутылок воды в день: \(waterCount)" : "Чашек чая/кофе в день: \(waterCount)",
                    value: $waterCount,
                    in: 0...15
                )
                .onChange(of: waterCount) { PrefsManager.shared.waterCount = $0 }
            }

            Section("Работа") {
                Stepper("Часов работы в день: \(workHours)", value: $workHours, in: 1...16)
                    .onChange(of: workHours) { PrefsManager.shared.workHoursPerDay = $0 }
            }

            Section {
                Button {
                    persistDefaults()
                    onComplete()
                } label: {
                    Text("Готово")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .listRowBackground(Color.clear)
        }
    }

    /// The pickers show a default before anything is chosen; leaving the screen keeps what was
    /// shown, so the stored answer always matches what the user saw.
    private func persistDefaults() {
        let prefs = PrefsManager.shared
        prefs.profession = profession
        prefs.gender = gender
        prefs.maritalStatus = maritalStatus
        prefs.personalityType = personalityType
        prefs.nightWakeFrequency = nightWakeFrequency
    }
}

private struct LabeledNumberField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("—", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
    }
}
