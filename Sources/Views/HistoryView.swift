import SwiftUI
struct HistoryView: View {
    @Environment(\.studyTheme) private var appTheme
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy18) {
            HStack { Text("La tua cronologia").font(appTheme.preservedTypography.pageTitle); Spacer(); Text("\(filtered.count) sessioni").foregroundStyle(appTheme.palette.textSecondary) }
            StudyTextEntry("Cerca materia o note", text: $search).interactiveHover(textEntry: true).textFieldStyle(StudyTextFieldStyle())
            HStack {
                StudyDropdown(title: "Materia", options: [("Tutte", "Tutte le materie")] + Array(Set(store.sessions.map(\.subjectName))).sorted().map { ($0, $0) }, selection: $subject)
                StudyDropdown(title: "Modalità", options: [("Tutte", "Tutte le modalità")] + TimerMode.allCases.map { ($0.rawValue, $0.rawValue) }, selection: $mode)
                Text("Min. minuti"); StudyNumberField(title: "Minimo", value: $minMinutes).frame(width: DesignSystem.TimerLayout.studyField)
            }
            HStack { Toggle("Filtra date", isOn: $dateFilter).interactiveHover(); if dateFilter { DatePicker("Dal", selection: $from, displayedComponents: .date).interactiveHover(); DatePicker("Al", selection: $to, displayedComponents: .date).interactiveHover() } }
            if filtered.isEmpty {
                StudyEmptyState(symbol: "book.closed", title: store.sessions.isEmpty ? "Ogni sessione lascia un segno" : "Nessuna sessione qui", detail: store.sessions.isEmpty ? "Il tempo che dedichi allo studio lo ritrovi qui." : "Prova a togliere qualche filtro.", actionTitle: store.sessions.isEmpty ? "Inizia a studiare" : "Azzera filtri") {
                    if store.sessions.isEmpty { store.openTimer = true }
                    else { search = ""; subject = "Tutte"; mode = "Tutte"; minMinutes = 0; dateFilter = false }
                }
            }
            else {
                List(filtered) { s in
                    HStack(spacing: 0) {
                        Button { editing = s } label: {
                            SessionRow(session: s).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                        }.buttonStyle(.plain).interactiveHover(cornerRadius: DesignSystem.Radius.card)
                            .accessibilityLabel("Modifica sessione: " + s.subjectName)
                        Button { editing = s } label: {
                            Image(systemName: "pencil").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle())
                        }.buttonStyle(.plain).interactiveHover().accessibilityLabel("Modifica sessione")
                        Button(role: .destructive) { deleting = s } label: {
                            Image(systemName: "trash").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle())
                        }.buttonStyle(.plain).interactiveHover().accessibilityLabel("Elimina sessione")
                    }.listRowInsets(EdgeInsets())

                    .contextMenu { Button("Modifica") { editing = s }; Button("Elimina", role: .destructive) { deleting = s } }
                }.listStyle(.inset)
            }
        }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        .sheet(item: $editing) { SessionEditor(session: $0) }
        .alert("Eliminare questa sessione?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button("Annulla", role: .cancel) {}; Button("Elimina", role: .destructive) { if let deleting { store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text("Il tempo verrà rimosso dalle statistiche.") }
    }
}
struct SessionEditor: View {
    @Environment(\.studyTheme) private var appTheme
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
            Text("Modifica sessione").font(appTheme.preservedTypography.title2)
            DatePicker("Inizio", selection: $start).interactiveHover()
            DatePicker("Fine", selection: $end).interactiveHover()
            StudyNumberField(title: "Minuti studiati", value: $minutes)
            StudyNumberField(title: "Minuti in pausa", value: $pause)
            StudyDropdown(title: "Materia", options: [(session.subjectID, session.subjectName)] + store.subjects.filter { $0.id != session.subjectID }.map { (Optional($0.id), $0.name) }, selection: $subjectID)
            StudyTextEntry("Note", text: $note, axis: .vertical).textFieldStyle(StudyTextFieldStyle()).interactiveHover(textEntry: true).lineLimit(3...6)
            if !valid { Text("Durata e pause devono rientrare tra inizio e fine.").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.appearance.destructiveInk) }
            HStack { Button("Annulla") { dismiss() }; Spacer(); Button("Salva") {
                session.updateTiming(start: start, end: end, duration: minutes * 60, pause: pause * 60); session.note = note
                if let subject = store.subjects.first(where: { $0.id == subjectID }) { session.subjectID = subject.id; session.subjectName = subject.name }
                if store.save() { dismiss() }
            }.disabled(!valid).buttonStyle(ResponsiveButtonStyle(prominent: true)) }
        }.padding(DesignSystem.PreservedGeometry.gap28).frame(width: DesignSystem.PreservedGeometry.points470).onAppear { start = session.startDate; end = session.endDate; minutes = session.duration / 60; pause = session.pauseDuration / 60; note = session.note; subjectID = session.subjectID }
    }
}
