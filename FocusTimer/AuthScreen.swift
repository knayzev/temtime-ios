import SwiftUI

struct AuthScreen: View {
    let startInLoginMode: Bool
    let onAuthenticated: () -> Void

    @State private var isLoginMode: Bool
    @State private var errorMessage: String?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var regEmail = ""
    @State private var regPassword = ""
    @State private var consent = false

    @State private var loginEmail = PrefsManager.shared.email
    @State private var loginPassword = ""

    init(startInLoginMode: Bool, onAuthenticated: @escaping () -> Void) {
        self.startInLoginMode = startInLoginMode
        self.onAuthenticated = onAuthenticated
        _isLoginMode = State(initialValue: startInLoginMode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 48)

                Text("Focus Timer")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.primary)

                Text("Личный кабинет для контроля времени")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)

                Picker("", selection: $isLoginMode) {
                    Text("Вход").tag(true)
                    Text("Регистрация").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isLoginMode) { _ in errorMessage = nil }

                if isLoginMode {
                    TextField("Почта", text: $loginEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Пароль", text: $loginPassword)
                        .textFieldStyle(.roundedBorder)

                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red).font(.footnote)
                    }

                    Button("Войти") {
                        let prefs = PrefsManager.shared
                        if !prefs.isRegistered {
                            errorMessage = "Аккаунт не найден — зарегистрируйтесь"
                        } else if loginEmail.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(prefs.email.trimmingCharacters(in: .whitespaces)) == .orderedSame,
                                  sha256(loginPassword) == prefs.accountPasswordHash {
                            prefs.isLoggedIn = true
                            onAuthenticated()
                        } else {
                            errorMessage = "Неверная почта или пароль"
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .padding(.top, 8)
                } else {
                    TextField("Имя", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Фамилия", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Почта", text: $regEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Пароль", text: $regPassword)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Согласен(на) на обработку персональных данных", isOn: $consent)
                        .font(.footnote)

                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red).font(.footnote)
                    }

                    Button("Зарегистрироваться") {
                        if firstName.isEmpty || regEmail.isEmpty || regPassword.isEmpty {
                            errorMessage = "Заполните имя, почту и пароль"
                        } else if !consent {
                            errorMessage = "Нужно согласие на обработку данных"
                        } else {
                            let prefs = PrefsManager.shared
                            prefs.userName = firstName
                            prefs.lastName = lastName
                            prefs.email = regEmail
                            prefs.accountPasswordHash = sha256(regPassword)
                            prefs.dataConsentGiven = true
                            prefs.isRegistered = true
                            prefs.isLoggedIn = true
                            onAuthenticated()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(24)
        }
    }
}
