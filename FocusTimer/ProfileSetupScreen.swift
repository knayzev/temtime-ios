import SwiftUI

/// The values AdviceEngine and the voice picker already expect, so the labels map onto them.
private let genderMale = "Мужской"
private let genderFemale = "Женский"

/// Step one: who the plan is for. Name and surname already come from registration, so this asks
/// only what the plan and the advice engine need.
struct ProfileSetupScreen: View {
    let onNext: () -> Void

    @State private var gender = PrefsManager.shared.gender
    @State private var age = PrefsManager.shared.age
    @State private var weight = PrefsManager.shared.weightKg
    @State private var height = PrefsManager.shared.heightCm
    @State private var profession = PrefsManager.shared.profession.isEmpty
        ? presetForProfession("").name
        : PrefsManager.shared.profession
    @State private var professionDetails = PrefsManager.shared.professionDetails
    @State private var wakeTime = PrefsManager.shared.wakeTime

    private var canContinue: Bool { !gender.isEmpty && !age.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StepperHeader(currentStep: 1, labels: ["О себе", "Расписание", "Готово"])
                    .padding(.bottom, 4)

                HeroGlyph(emoji: "👤", size: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Расскажите о себе")
                        .font(.title2.bold())
                    Text("По этим данным подбираются длительность блоков и рекомендации")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    GenderOption(label: "Я мужчина", emoji: "👨", selected: gender == genderMale) {
                        gender = genderMale
                    }
                    GenderOption(label: "Я женщина", emoji: "👩", selected: gender == genderFemale) {
                        gender = genderFemale
                    }
                }

                HStack(spacing: 12) {
                    NumberField(label: "Возраст", text: $age)
                    NumberField(label: "Вес, кг", text: $weight)
                    NumberField(label: "Рост, см", text: $height)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Профессия")
                        Spacer()
                        Picker("Профессия", selection: $profession) {
                            ForEach(professionPresets, id: \.id) { preset in
                                Text("\(preset.emoji) \(preset.name)").tag(preset.name)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Text(presetForProfession(profession).summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                TextField("Чем именно занимаетесь (необязательно)", text: $professionDetails, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                // The wake time anchors the generated schedule, so it is asked for here rather
                // than later.
                ClockPicker(label: "Во сколько встаёте", time: $wakeTime)

                Button {
                    persist()
                    onNext()
                } label: {
                    Text("Собрать расписание")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(!canContinue)
                .padding(.top, 8)

                if !canContinue {
                    Text("Выберите пол и укажите возраст, чтобы продолжить")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
        .onChange(of: gender) { _ in persist() }
        .onChange(of: age) { _ in persist() }
        .onChange(of: weight) { _ in persist() }
        .onChange(of: height) { _ in persist() }
        .onChange(of: profession) { _ in persist() }
        .onChange(of: professionDetails) { _ in persist() }
        .onChange(of: wakeTime) { _ in persist() }
    }

    /// Saved as it is typed, so leaving the screen midway loses nothing.
    private func persist() {
        let prefs = PrefsManager.shared
        prefs.gender = gender
        prefs.age = age
        prefs.weightKg = weight
        prefs.heightCm = height
        prefs.profession = profession
        prefs.professionDetails = professionDetails
        prefs.wakeTime = wakeTime
    }
}

/// A tick-box sized as a card, so each of the two options is a single obvious tap.
private struct GenderOption: View {
    let label: String
    let emoji: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 30))
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(selected ? AppColors.primary : .secondary)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? AppColors.primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? AppColors.primarySoft : AppColors.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct NumberField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { newValue in
                    let digits = String(newValue.filter { $0.isNumber }.prefix(3))
                    if digits != newValue { text = digits }
                }
        }
    }
}
