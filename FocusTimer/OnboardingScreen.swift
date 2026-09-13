import SwiftUI

struct OnboardingScreen: View {
    let onComplete: () -> Void

    @State private var bedTime = OnboardingScreen.timeStringToDate(PrefsManager.shared.bedTime)
    @State private var breakfastTime = OnboardingScreen.timeStringToDate(PrefsManager.shared.breakfastTime)
    @State private var lunchTime = OnboardingScreen.timeStringToDate(PrefsManager.shared.lunchTime)
    @State private var dinnerTime = OnboardingScreen.timeStringToDate(PrefsManager.shared.dinnerTime)
    @State private var workHours = PrefsManager.shared.workHoursPerDay
    @State private var mealsPerDay = PrefsManager.shared.mealsPerDay
    @State private var waterUnit = PrefsManager.shared.waterUnit
    @State private var waterCount = PrefsManager.shared.waterCount

    var body: some View {
        Form {
            Section {
                Text("Расскажите о своём дне")
                    .font(.title2.bold())
                Text("Это поможет давать более точные советы")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)

            Section("Режим") {
                DatePicker("Ложитесь спать", selection: $bedTime, displayedComponents: .hourAndMinute)
                    .onChange(of: bedTime) { PrefsManager.shared.bedTime = Self.dateToTimeString($0) }
                DatePicker("Завтракаете", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                    .onChange(of: breakfastTime) { PrefsManager.shared.breakfastTime = Self.dateToTimeString($0) }
                DatePicker("Обедаете", selection: $lunchTime, displayedComponents: .hourAndMinute)
                    .onChange(of: lunchTime) { PrefsManager.shared.lunchTime = Self.dateToTimeString($0) }
                DatePicker("Ужинаете", selection: $dinnerTime, displayedComponents: .hourAndMinute)
                    .onChange(of: dinnerTime) { PrefsManager.shared.dinnerTime = Self.dateToTimeString($0) }
            }

            Section("Работа и питание") {
                Stepper("Часов работы в день: \(workHours)", value: $workHours, in: 1...16)
                    .onChange(of: workHours) { PrefsManager.shared.workHoursPerDay = $0 }
                Stepper("Приёмов пищи в день: \(mealsPerDay)", value: $mealsPerDay, in: 1...6)
                    .onChange(of: mealsPerDay) { PrefsManager.shared.mealsPerDay = $0 }
            }

            Section("Вода") {
                Picker("Считать в", selection: $waterUnit) {
                    Text("Бутылки").tag("Бутылки")
                    Text("Чай/кофе").tag("Чай/кофе")
                }
                .pickerStyle(.segmented)
                .onChange(of: waterUnit) { PrefsManager.shared.waterUnit = $0 }

                Stepper(
                    waterUnit == "Бутылки" ? "Бутылок в день: \(waterCount)" : "Чашек в день: \(waterCount)",
                    value: $waterCount,
                    in: 0...15
                )
                .onChange(of: waterCount) { PrefsManager.shared.waterCount = $0 }
            }

            Section {
                Button("Далее") {
                    onComplete()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
            .listRowBackground(Color.clear)
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
