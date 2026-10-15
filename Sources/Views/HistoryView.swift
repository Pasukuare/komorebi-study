import SwiftUI
struct HistoryView: View {
    @EnvironmentObject var store: StudyStore
    @State private var search = ""
    @State private var subject = "Tutte"
    @State private var mode = "Tutte"
    @State private var minMinutes = 0.0
    @State private var from = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var to = Date()
    @State private var dateFilter = false
    @State private var editing: StudySession?
    @State private var deleting: StudySession?
    var filtered: [StudySession] {
        let toLimit = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to)) ?? to
        return store.sessions.filter { s in
            (search.isEmpty || s.note.localizedCaseInsensitiveContains(search) || s.subjectName.localizedCaseInsensitiveContains(search)) && (subject == "Tutte" || s.subjectName == subject) && (mode == "Tutte" || s.timerMode == mode) && s.duration >= minMinutes * 60 && (!dateFilter || (s.startDate >= Calendar.current.startOfDay(for: from) && s.startDate < toLimit))
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("La tua cronologia").font(.system(size: 30, design: .serif)); Spacer(); Text("\(filtered.count) sessioni").foregroundStyle(.secondary) }
            TextField("Cerca materia o note", text: $search).textFieldStyle(.roundedBorder)
            HStack {
                Picker("Materia", selection: $subject) { Text("Tutte").tag("Tutte"); ForEach(Array(Set(store.sessions.map(\.subjectName))).sorted(), id: \.self) { Text($0) } }
                Picker("Modalità", selection: $mode) { Text("Tutte").tag("Tutte"); ForEach(TimerMode.allCases) { Text($0.rawValue).tag($0.rawValue) } }
                Text("Min. minuti"); TextField("Minimo", value: $minMinutes, format: .number).frame(width: 50)
            }
            HStack { Toggle("Filtra date", isOn: $dateFilter); if dateFilter { DatePicker("Dal", selection: $from, displayedComponents: .date); DatePicker("Al", selection: $to, displayedComponents: .date) } }
            if filtered.isEmpty { ContentUnavailableView("Nessuna sessione", systemImage: "leaf", description: Text("Le sessioni salvate compariranno qui.")) }
            else {
                List(filtered) { s in
                    HStack {
                        SessionRow(session: s)
                        Button { editing = s } label: { Image(systemName: "pencil") }.buttonStyle(.borderless).accessibilityLabel("Modifica sessione")
                        Button(role: .destructive) { deleting = s } label: { Image(systemName: "trash") }.buttonStyle(.borderless).accessibilityLabel("Elimina sessione")
                    }
                    .contextMenu { Button("Modifica") { editing = s }; Button("Elimina", role: .destructive) { deleting = s } }
                }.listStyle(.inset)
            }
        }.padding(30)
        .sheet(item: $editing) { SessionEditor(session: $0) }
        .alert("Eliminare questa sessione?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button("Annulla", role: .cancel) {}; Button("Elimina", role: .destructive) { if let deleting { store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text("Il tempo verrà rimosso dalle statistiche.") }
    }
}
struct SessionEditor: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    let session: StudySession
    @State private var start = Date()
    @State private var end = Date()
    @State private var minutes = 0.0
    @State private var pause = 0.0
    @State private var note = ""
    @State private var subjectID: UUID?
    var valid: Bool { end > start && minutes > 0 && pause >= 0 && (minutes + pause) * 60 <= end.timeIntervalSince(start) + 1 }
    var body: some View {
        Form {
            Text("Modifica sessione").font(.title2)
            DatePicker("Inizio", selection: $start)
            DatePicker("Fine", selection: $end)
            TextField("Minuti studiati", value: $minutes, format: .number)
            TextField("Minuti in pausa", value: $pause, format: .number)
            Picker("Materia", selection: $subjectID) { Text(session.subjectName).tag(session.subjectID); ForEach(store.subjects.filter { $0.id != session.subjectID }) { Text($0.name).tag(Optional($0.id)) } }
            TextField("Note", text: $note, axis: .vertical).lineLimit(3...6)
            if !valid { Text("Durata e pause devono rientrare tra inizio e fine.").font(.caption).foregroundStyle(.red) }
            HStack { Button("Annulla") { dismiss() }; Spacer(); Button("Salva") {
                session.startDate = start; session.endDate = end; session.duration = minutes * 60; session.pauseDuration = pause * 60; session.note = note
                if let subject = store.subjects.first(where: { $0.id == subjectID }) { session.subjectID = subject.id; session.subjectName = subject.name }
                if store.save() { dismiss() }
            }.disabled(!valid).buttonStyle(.borderedProminent) }
        }.padding(28).frame(width: 470).onAppear { start = session.startDate; end = session.endDate; minutes = session.duration / 60; pause = session.pauseDuration / 60; note = session.note; subjectID = session.subjectID }
    }
}
