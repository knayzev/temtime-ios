import Foundation

/// Simple rule-based tips derived from basic body/age data. Not medical advice —
/// just sensible defaults to nudge the user toward a healthier routine.
func buildAdvice(weightKg: String, heightCm: String, age: String, gender: String) -> [String] {
    var advice: [String] = []
    let ageValue = Int(age)
    let weightValue = Double(weightKg)
    let heightM = Double(heightCm).map { $0 / 100 }

    if let ageValue {
        switch ageValue {
        case ..<18:
            advice.append("В вашем возрасте рекомендуется 8–10 часов сна.")
        case 18...64:
            advice.append("Рекомендуется 7–9 часов сна.")
        default:
            advice.append("Рекомендуется 7–8 часов сна.")
        }
    } else {
        advice.append("Взрослым обычно рекомендуют 7–9 часов сна.")
    }

    if let weightValue, let heightM, heightM > 0 {
        let bmi = weightValue / (heightM * heightM)
        switch bmi {
        case ..<18.5:
            advice.append("Индекс массы тела ниже нормы — добавьте силовые тренировки 2–3 раза в неделю и следите за питанием.")
        case 18.5..<25:
            advice.append("Индекс массы тела в норме — поддерживайте активность: минимум 150 минут в неделю, около 30 минут в день.")
        case 25..<30:
            advice.append("Индекс массы тела немного повышен — старайтесь проходить не менее 8000 шагов в день.")
        default:
            advice.append("Индекс массы тела повышен — начните с лёгкой активности: ходьба 20–30 минут в день, постепенно увеличивая нагрузку.")
        }
    } else {
        advice.append("Заполните вес и рост выше, чтобы получить более точный совет по активности.")
    }

    if gender == "Женский" {
        advice.append("Женщинам старше 18 рекомендуется дополнительно следить за железом в питании при высокой физической нагрузке.")
    }

    advice.append("Работайте блоками по 45–50 минут, затем делайте перерыв 10–15 минут.")
    advice.append("На перерыве лучше пройтись или почитать, а не листать телефон — так мозг действительно отдыхает.")

    return advice
}
