import SwiftUI

struct HistoryScreen: View {
    @State private var history: [SessionRecord] = PrefsManager.shared.history

    var body: some View {
        Group {
            if history.isEmpty {
                VStack {
                    Spacer()
                    Text("Пока пусто — здесь появится история ваших сессий работы и отдыха")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                List {
                    ForEach(history) { entry in
                        HistoryRow(entry: entry) { newComment in
                            PrefsManager.shared.updateHistoryComment(id: entry.id, comment: newComment)
                            history = PrefsManager.shared.history
                        }
                    }
                }
            }
        }
        .onAppear {
            history = PrefsManager.shared.history
        }
    }
}

private struct HistoryRow: View {
    let entry: SessionRecord
    let onCommentChange: (String) -> Void

    @State private var comment: String

    init(entry: SessionRecord, onCommentChange: @escaping (String) -> Void) {
        self.entry = entry
        self.onCommentChange = onCommentChange
        _comment = State(initialValue: entry.comment)
    }

    private var phaseLabel: String {
        (entry.phase == "WORK" ? "Работа" : "Отдых") + (entry.interrupted ? " (прервано)" : "")
    }

    private var dateText: String {
        let date = Date(timeIntervalSince1970: entry.startTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(phaseLabel).bold()
                Spacer()
                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Text(String(format: "%d:%02d", entry.durationSeconds / 60, entry.durationSeconds % 60))
                    .font(.subheadline)
                if !entry.category.isEmpty {
                    Text("• \(entry.category)")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if !entry.quote.isEmpty {
                Text(entry.quote)
                    .font(.caption)
                    .italic()
                    .foregroundColor(AppColors.restColor)
            }

            TextField("Комментарий", text: $comment)
                .textFieldStyle(.roundedBorder)
                .onChange(of: comment) { onCommentChange($0) }
        }
        .padding(.vertical, 4)
    }
}
