import SwiftUI
struct CalendarView: View {
    @EnvironmentObject var store: StudyStore
    @State private var month = Date()
    @State private var selected = Date()
    @State private var adding = false
    @State private var editing: StudyExam?
    @State private var deleting: StudyExam?
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    var days: [Date?] {
        let c = Calendar.current; let start = c.dateInterval(of: .month, for: month)?.start ?? month
        let offset = (c.component(.weekday, from: start) - c.firstWeekday + 7) % 7
        let range = c.range(of: .day, in: .month, for: month) ?? 1..<31
        return Array(repeating: nil, count: offset) + range.compactMap { c.date(byAdding: .day, value: $0 - 1, to: start) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text(month, format: .dateTime.month(.wide).year()).font(.system(size: 30, design: .serif))
                    Spacer(); Button("Aggiungi esame", systemImage: "plus") { adding = true }.buttonStyle(.borderedProminent)
                    Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Mese precedente")
                    Button("Oggi") { month = Date(); selected = Date() }
                    Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Mese successivo")
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<7, id: \.self) { n in Text(Calendar.current.shortStandaloneWeekdaySymbols[(Calendar.current.firstWeekday - 1 + n) % 7]).font(.caption).foregroundStyle(.secondary) }
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let total = store.total(in: Calendar.current.dateInterval(of: .day, for: date) ?? DateInterval(start: date, end: date))
                            let examCount = store.exams.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
                            Button { selected = date } label: {
                                VStack(spacing: 10) { Text(date, format: .dateTime.day()).font(.headline); Text(total > 0 ? durationText(total) : "—").font(.caption); if examCount > 0 { Label("\(examCount) esam\(examCount == 1 ? "e" : "i")", systemImage: "graduationcap.fill").font(.system(size: 10)).foregroundStyle(Color.sage) } }.frame(maxWidth: .infinity, minHeight: 76)
                                    .background(Color.sage.opacity(total == 0 ? 0.04 : 0.15 + min(0.5, total / max(1, store.settings.dailyGoal * 3600) * 0.5)), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Calendar.current.isDate(date, inSameDayAs: selected) ? Color.sage : .clear, lineWidth: 2))
                            }.buttonStyle(.plain).accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(durationText(total)), \(examCount) esami")
                        } else { Color.clear.frame(height: 76) }
                    }
                }
                Card {
                    Text(selected, format: .dateTime.day().month(.wide)).font(.title2)
                    let dayExams = store.exams.filter { Calendar.current.isDate($0.date, inSameDayAs: selected) }
                    ForEach(dayExams) { exam in
                        HStack {
                            ExamRow(exam: exam)
                            Button("Modifica") { editing = exam }
                            Button("Elimina", role: .destructive) { deleting = exam }
                        }
                    }
                    if !dayExams.isEmpty { Divider() }
                    let interval = Calendar.current.dateInterval(of: .day, for: selected) ?? DateInterval(start: selected, end: selected)
                    let sessions = store.sessions.filter { store.contribution($0, in: interval) > 0 }
                    if sessions.isEmpty { Text("Nessuna sessione in questo giorno.").foregroundStyle(.secondary) }
                    ForEach(sessions) { session in SessionRow(session: session) }
                }
            }.padding(30)
        }
        .sheet(isPresented: $adding) { ExamEditor(initialDate: selected) }
        .sheet(item: $editing) { exam in ExamEditor(exam: exam, initialDate: exam.date) }
        .alert("Eliminare l’esame?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) { if let deleting { store.context.delete(deleting); store.save() }; deleting = nil }
        } message: { Text("Le sessioni di studio rimarranno nell’archivio.") }
    }
}
struct SessionRow: View {
    let session: StudySession
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed").foregroundStyle(Color.sage).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) { Text(session.subjectName).font(.headline); Text(session.note.isEmpty ? session.timerMode : session.note).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
            Spacer(); VStack(alignment: .trailing, spacing: 4) { Text(durationText(session.duration)).monospacedDigit(); Text(session.startDate, format: .dateTime.day().month().hour().minute()).font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 8)
    }
}

struct ExamRow: View {
    @EnvironmentObject var store: StudyStore
    let exam: StudyExam
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "graduationcap").foregroundStyle(Color.sage).font(.title2)
            VStack(alignment: .leading, spacing: 5) {
                Text(exam.title).font(.headline)
                if let subject = store.subjects.first(where: { $0.id == exam.subjectID }) { Text(subject.name).font(.caption).foregroundStyle(.secondary) }
                if !exam.note.isEmpty { Text(exam.note).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(exam.date, format: .dateTime.day().month(.abbreviated).year()).font(.callout)
                if exam.hasTime { Text(exam.date, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary) }
            }
        }.padding(.vertical, 8)
    }
}
struct ExamEditor: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    var exam: StudyExam? = nil
    var initialDate: Date
    @State private var title = ""
    @State private var date = Date()
    @State private var hasTime = false
    @State private var subjectID: UUID?
    @State private var note = ""
    @State private var saveError: String?
    var body: some View {
        Form {
            Text(exam == nil ? "Nuovo esame" : "Modifica esame").font(.system(size: 25, design: .serif))
            TextField("Nome esame", text: $title)
            Picker("Materia", selection: $subjectID) {
                Text("Nessuna materia").tag(nil as UUID?)
                ForEach(store.subjects) { Text($0.name).tag(Optional($0.id)) }
            }
            DatePicker("Data", selection: $date, displayedComponents: .date)
            Toggle("Specifica un orario", isOn: $hasTime)
            if hasTime { DatePicker("Ora", selection: $date, displayedComponents: .hourAndMinute) }
            TextField("Note / aula", text: $note, axis: .vertical).lineLimit(3...5)
            if let saveError { Text(saveError).foregroundStyle(.red) }
            HStack {
                Button("Annulla") { dismiss() }; Spacer()
                Button("Salva esame") {
                    let model = exam ?? StudyExam(title: "", date: date)
                    if exam == nil { store.context.insert(model) }
                    model.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    model.date = hasTime ? date : Calendar.current.startOfDay(for: date)
                    model.hasTime = hasTime; model.subjectID = subjectID; model.note = note
                    if store.save() { dismiss() } else { store.context.rollback(); store.refresh(); saveError = "Impossibile salvare. Riprova." }
                }.buttonStyle(.borderedProminent).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(28).frame(width: 480)
        .onAppear { title = exam?.title ?? ""; date = exam?.date ?? initialDate; hasTime = exam?.hasTime ?? false; subjectID = exam?.subjectID; note = exam?.note ?? "" }
    }
}
