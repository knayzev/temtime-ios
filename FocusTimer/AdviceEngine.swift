import Foundation

/// Rule-based tips derived from body/age data. This isn't a literal per-value lookup table
/// (that would mean millions of rows for every age/height/weight combination) — instead it
/// covers the full supported range (age 10-95, height 110-220cm, weight 35-220kg) with fine
/// enough brackets per dimension (age, BMI, height, gender) that the combined output varies
/// meaningfully across users instead of collapsing into the same 3-4 generic messages.
/// Not medical advice — just sensible defaults to nudge the user toward a healthier routine.
func buildAdvice(weightKg: String, heightCm: String, age: String, gender: String) -> [String] {
    var advice: [String] = []
    let ageValue = Int(age)
    let weightValue = Double(weightKg)
    let heightCmValue = Double(heightCm)
    let heightM = heightCmValue.map { $0 / 100 }
    let isFemale = gender == "Женский"
    let isMale = gender == "Мужской"

    advice.append(sleepAdvice(age: ageValue))

    if let ageValue, ageValue < 18 {
        advice.append(childBmiAdvice(age: ageValue, weight: weightValue, heightM: heightM))
    } else if let weightValue, let heightM, heightM > 0 {
        let bmi = weightValue / (heightM * heightM)
        advice.append(adultBmiAdvice(bmi: bmi, age: ageValue, isFemale: isFemale, isMale: isMale))
    } else {
        advice.append("Заполните вес и рост выше, чтобы получить более точный совет по активности.")
    }

    if let weightValue, let extra = weightExtremeAdvice(weight: weightValue, age: ageValue) {
        advice.append(extra)
    }

    if let heightCmValue, let extra = heightAdvice(heightCm: heightCmValue) {
        advice.append(extra)
    }

    advice.append(genderAdvice(isFemale: isFemale, isMale: isMale, age: ageValue))
    advice.append(focusRoutineAdvice(age: ageValue))

    return advice
}

private func sleepAdvice(age: Int?) -> String {
    guard let age else { return "Взрослым обычно рекомендуют 7–9 часов сна." }
    switch age {
    case ..<13: return "В возрасте 10–12 лет организму нужно 9–12 часов сна — старайтесь укладываться спать не позднее 21:30."
    case ..<16: return "Подросткам 13–15 лет рекомендуется 8–10 часов сна, особенно в учебные дни."
    case ..<18: return "В 16–17 лет всё ещё важно спать 8–10 часов — недосып в этом возрасте сильнее всего бьёт по концентрации."
    case ..<26: return "В 18–25 лет обычно достаточно 7–9 часов, но соблазн лечь позже велик — держите постоянный режим."
    case ..<36: return "В 26–35 лет рекомендуется 7–9 часов сна: это база для восстановления при высокой рабочей нагрузке."
    case ..<46: return "В 36–45 лет держите 7–8 часов сна и старайтесь не брать работу в постель — это заметно влияет на качество сна."
    case ..<56: return "В 46–55 лет рекомендуется 7–8 часов; в этом возрасте особенно важен стабильный ритм отхода ко сну."
    case ..<66: return "В 56–65 лет обычно достаточно 7–8 часов, но чувствительность к кофеину вечером возрастает — ограничьте его после обеда."
    case ..<76: return "В 66–75 лет рекомендуется 7–8 часов ночного сна; короткий дневной сон 20–30 минут — это нормально и полезно."
    default: return "В возрасте 76+ часто достаточно 7–8 часов с более гибким графиком; дневной отдых 20–30 минут помогает компенсировать более чуткий ночной сон."
    }
}

private func childBmiAdvice(age: Int, weight: Double?, heightM: Double?) -> String {
    let base = age < 13
        ? "Детям рекомендуется минимум 60 минут активной игры или спорта в день."
        : "Подросткам рекомендуется минимум 60 минут умеренной или высокой физической активности в день, включая силовые упражнения 2–3 раза в неделю."
    guard let weight, let heightM, heightM > 0 else { return base }
    _ = weight
    return base + " Индекс массы тела у детей и подростков оценивается по возрастным перцентилям, а не по взрослым нормам — если вес заметно выходит за пределы возрастной нормы, стоит обсудить это с педиатром."
}

private func adultBmiAdvice(bmi: Double, age: Int?, isFemale: Bool, isMale: Bool) -> String {
    let seniorNote = (age != nil && age! >= 65)
        ? " После 65 лет для суставов особенно хорошо подходят низкоударные нагрузки: плавание, скандинавская ходьба, велотренажёр."
        : ""
    let base: String
    switch bmi {
    case ..<16.0:
        base = "Индекс массы тела сильно ниже нормы (выраженный дефицит массы) — это повод обсудить питание и самочувствие с врачом; самостоятельно наращивать нагрузку в этом состоянии не стоит."
    case ..<17.0:
        base = "Индекс массы тела заметно ниже нормы — сделайте акцент на регулярном полноценном питании и лёгких силовых упражнениях 2 раза в неделю, без интенсивного кардио."
    case ..<18.5:
        base = "Индекс массы тела немного ниже нормы — добавьте силовые тренировки 2–3 раза в неделю и следите, чтобы питание покрывало расход энергии."
    case ..<25.0:
        base = "Индекс массы тела в норме — поддерживайте активность: минимум 150 минут в неделю умеренной нагрузки, около 20–30 минут в день." + seniorNote
    case ..<30.0:
        base = "Индекс массы тела немного повышен — старайтесь проходить не менее 8000 шагов в день и добавьте 2 силовые тренировки в неделю." + seniorNote
    case ..<35.0:
        base = "Индекс массы тела повышен (ожирение I степени) — начните с лёгкой активности: ходьба 20–30 минут в день, постепенно увеличивая длительность и темп." + seniorNote
    case ..<40.0:
        base = "Индекс массы тела значительно повышен (ожирение II степени) — низкоударные нагрузки (плавание, велосипед, ходьба) безопаснее для суставов, чем бег; имеет смысл обсудить план с врачом." + seniorNote
    default:
        base = "Индекс массы тела существенно повышен (ожирение III степени) — прежде чем наращивать нагрузку, стоит проконсультироваться с врачом и подобрать безопасный для суставов формат активности." + seniorNote
    }
    if isFemale && bmi < 18.5 {
        return base + " Женщинам с дефицитом массы особенно важно следить за железом и кальцием в рационе."
    }
    return base
}

private func weightExtremeAdvice(weight: Double, age: Int?) -> String? {
    if weight < 35.0 {
        return "Указанный вес очень низкий — рекомендуем обсудить питание и самочувствие с врачом."
    }
    if weight < 40.0, age == nil || age! >= 18 {
        return "Вес заметно ниже типичного для взрослого человека — стоит проверить, хватает ли калорий и белка в рационе."
    }
    if weight > 180.0 {
        return "При весе в этом диапазоне особенно полезны низкоударные тренировки (плавание, велосипед) — они снижают нагрузку на суставы и позвоночник."
    }
    if weight > 150.0 {
        return "Начинайте активность постепенно и отдавайте предпочтение низкоударным нагрузкам — так суставы адаптируются безопаснее."
    }
    return nil
}

private func heightAdvice(heightCm: Double) -> String? {
    switch heightCm {
    case ..<150.0: return "При невысоком росте особенно важно настроить рабочее место: высота стула и монитора должны позволять держать спину прямо, а ноги — полностью стоять на полу или подставке."
    case let h where h > 195.0: return "При высоком росте проверьте рабочее место: слишком низкий стол или монитор заставляют сутулиться — поднимите монитор на уровень глаз и следите за пространством для ног."
    case let h where h > 185.0: return "При вашем росте обратите внимание на высоту стола и монитора, чтобы не сутулиться во время долгой работы."
    default: return nil
    }
}

private func genderAdvice(isFemale: Bool, isMale: Bool, age: Int?) -> String {
    if isFemale, let age, age >= 45 {
        return "Женщинам после 45 особенно важны кальций, витамин D и силовые упражнения — они поддерживают плотность костей."
    }
    if isFemale {
        return "Женщинам, особенно при высокой физической нагрузке, стоит следить за железом в рационе."
    }
    if isMale, let age, age >= 40 {
        return "Мужчинам после 40 рекомендуется регулярно проверять сердечно-сосудистую систему и не пренебрегать кардионагрузкой 2–3 раза в неделю."
    }
    if isMale {
        return "Мужчинам стоит сочетать силовые тренировки с кардионагрузкой — это лучше поддерживает сердце и сосуды в долгосрочной перспективе."
    }
    return "Сочетайте силовые упражнения с кардионагрузкой — так поддерживаются и мышцы, и сердечно-сосудистая система."
}

private func focusRoutineAdvice(age: Int?) -> String {
    if let age, age < 16 {
        return "Для учёбы подойдут блоки покороче — 20–30 минут работы, затем 5–10 минут перерыва."
    }
    if let age, age < 18 {
        return "Попробуйте блоки по 30–40 минут с перерывами 10 минут — так легче удерживать концентрацию на учёбе."
    }
    if let age, age >= 66 {
        return "Блоки по 30–40 минут с перерывом 10–15 минут обычно комфортнее для долгой концентрации, чем длинные подходы."
    }
    return "Работайте блоками по 45–50 минут, затем делайте перерыв 10–15 минут. На перерыве лучше пройтись или почитать, а не листать телефон — так мозг действительно отдыхает."
}
