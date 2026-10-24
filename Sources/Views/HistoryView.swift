import SwiftUI
struct HistoryView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @State private var search = ""
    @State private var subject = HistorySubjectSelection.all
    @State private var mode = "Tutte"
    @State private var minMinutes = 0.0
    @State private var from = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var to = Date()
    @State private var dateFilter = false
    @State private var editing: StudySession?
    @State private var deleting: StudySession?
    var filtered: [StudySession] {
        let calendar = Calendar.current
        let fromLimit = calendar.startOfDay(for: from)
        let toLimit = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: to)) ?? to
        return store.sessions.filter { s in
            (search.isEmpty || s.note.localizedCaseInsensitiveContains(search) || s.subjectName.localizedCaseInsensitiveContains(search)) && subject.matches(s) && (mode == "Tutte" || s.timerMode == mode) && s.duration >= minMinutes * 60 && (!dateFilter || (s.startDate >= fromLimit && s.startDate < toLimit))
        }
    }
    var body: some View {
        // One filtering pass per body, shared by count, empty state and lazy List.
        let visibleSessions = filtered
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy18) {
            HStack { Text(L10n.tr("Cronologia")).font(appTheme.preservedTypography.pageTitle); Spacer(); Text(L10n.count(visibleSessions.count, singular: "%@ sessione", plural: "%@ sessioni")).foregroundStyle(appTheme.palette.textSecondary) }
            StudyTextEntry(L10n.tr("Cerca materia o note"), text: $search).interactiveHover(textEntry: true).textFieldStyle(StudyTextFieldStyle())
            HStack {
                StudyDropdown(title: L10n.tr("Materia"), options: [(.all, L10n.tr("Tutte le materie"))] + store.historySubjectChoices, selection: $subject, sectionLabels: store.completedSubjects.first.map { [HistorySubjectSelection.subject($0.id): L10n.tr("Completate")] } ?? [:])
                StudyDropdown(title: L10n.tr("Modalità"), options: [("Tutte", L10n.tr("Tutte le modalità"))] + TimerMode.allCases.map { ($0.rawValue, $0.displayName) }, selection: $mode)
                Text(L10n.tr("Min. minuti")); StudyNumberField(title: L10n.tr("Minimo"), value: $minMinutes).frame(width: DesignSystem.TimerLayout.studyField)
            }
            HStack { Toggle(L10n.tr("Filtra date"), isOn: $dateFilter).interactiveHover(); if dateFilter { DatePicker(L10n.tr("Dal"), selection: $from, displayedComponents: .date).interactiveHover(); DatePicker(L10n.tr("Al"), selection: $to, displayedComponents: .date).interactiveHover() } }
            if visibleSessions.isEmpty {
                StudyEmptyState(symbol: "book.closed", title: store.sessions.isEmpty ? L10n.tr("Nessuna sessione") : L10n.tr("Nessuna sessione qui"), detail: store.sessions.isEmpty ? L10n.tr("Le sessioni salvate appariranno qui.") : L10n.tr("Prova a togliere qualche filtro."), actionTitle: store.sessions.isEmpty ? L10n.tr("Inizia a studiare") : L10n.tr("Azzera filtri")) {
                    if store.sessions.isEmpty { store.openTimer = true }
                    else { search = ""; subject = .all; mode = "Tutte"; minMinutes = 0; dateFilter = false }
                }
            }
            else {
                List(visibleSessions) { s in
                    HistorySessionRow(session: s, edit: { editing = s }, delete: { deleting = s })
                        .listRowInsets(EdgeInsets())
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }

                    .contextMenu { Button(L10n.tr("Modifica")) { editing = s }; Button(L10n.tr("Elimina"), role: .destructive) { deleting = s } }
                }.listStyle(.inset)
            }
        }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        .sheet(item: $editing) { SessionEditor(session: $0) }
        .alert(L10n.tr("Eliminare questa sessione?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button(L10n.tr("Annulla"), role: .cancel) {}; Button(L10n.tr("Elimina"), role: .destructive) { if let deleting { store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text(L10n.tr("Il tempo verrà rimosso dalle statistiche.")) }
    }
}
struct SessionEditor: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
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
    var valid: Bool { store.subjectChoiceIsAllowed(subjectID, retaining: session.subjectID) && end > start && minutes > 0 && pause >= 0 && (minutes + pause) * 60 <= end.timeIntervalSince(start) + 1 }
    var body: some View {
        Form {
            Text(L10n.tr("Modifica sessione")).font(appTheme.preservedTypography.title2)
            DatePicker(L10n.tr("Inizio"), selection: $start).interactiveHover()
            DatePicker(L10n.tr("Fine"), selection: $end).interactiveHover()
            StudyNumberField(title: L10n.tr("Minuti studiati"), value: $minutes)
            StudyNumberField(title: L10n.tr("Minuti in pausa"), value: $pause)
            StudyDropdown(title: L10n.tr("Materia"), options: store.editingSubjectChoices(currentID: session.subjectID, currentName: session.subjectName), selection: $subjectID)
            StudyTextEntry(L10n.tr("Note"), text: $note, axis: .vertical).textFieldStyle(StudyTextFieldStyle()).interactiveHover(textEntry: true).lineLimit(3...6)
            if !valid { Text(L10n.tr("Durata e pause devono rientrare tra inizio e fine.")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.appearance.destructiveInk) }
            HStack { Button(L10n.tr("Annulla")) { dismiss() }; Spacer(); Button(L10n.tr("Salva")) {
                session.updateTiming(start: start, end: end, duration: minutes * 60, pause: pause * 60); session.note = note
                if subjectID != session.subjectID, let id = subjectID, store.activeSubjectIDs.contains(id), let subject = store.subjectsByID[id] { session.subjectID = subject.id; session.subjectName = subject.name }
                if store.save() { dismiss() }
            }.disabled(!valid).buttonStyle(ResponsiveButtonStyle(prominent: true)) }
        }.padding(DesignSystem.PreservedGeometry.gap28).frame(width: DesignSystem.PreservedGeometry.points470).onAppear { start = session.startDate; end = session.endDate; minutes = session.duration / 60; pause = session.pauseDuration / 60; note = session.note; subjectID = session.subjectID }
    }
}


/// One highlight/focus outline encloses content and both actions, not just the label.
struct HistorySessionRow: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    let session: StudySession
    let edit: () -> Void
    let delete: () -> Void
    private enum Action: Hashable { case content, edit, delete }
    @FocusState private var focusedAction: Action?
    var body: some View {
        HStack(spacing: 0) {
            Button(action: edit) {
                SessionRow(session: session).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }.buttonStyle(.plain).focusEffectDisabled().focused($focusedAction, equals: .content)
                .accessibilityLabel(L10n.tr("Modifica sessione: ") + session.subjectName)
            Button(action: edit) {
                Image(systemName: "pencil").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle())
            }.buttonStyle(.plain).focusEffectDisabled().focused($focusedAction, equals: .edit)
                .accessibilityLabel(L10n.tr("Modifica sessione"))
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle())
            }.buttonStyle(.plain).focusEffectDisabled().focused($focusedAction, equals: .delete)
                .accessibilityLabel(L10n.tr("Elimina sessione"))
        }.contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .interactiveHover(cornerRadius: DesignSystem.Radius.card, listRow: true, identity: session.subjectName + session.note + String(session.duration))
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card, explicitFocus: focusedAction != nil))
    }
}
