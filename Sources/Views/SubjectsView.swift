import SwiftUI
struct SubjectsView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @FocusState private var nameFocused: Bool
    @State private var name = ""
    @State private var icon = "book"
    @State private var color = SubjectColorID.defaultID
    @State private var goal = 5.0
    @State private var editing: Subject?
    @State private var deleting: Subject?
    func subjectMetric(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.PreservedGeometry.gap5) { Text(title).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary); Text(durationText(value)).font(appTheme.preservedTypography.subjectMetric).monospacedDigit() }.frame(maxWidth: .infinity, alignment: .leading)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy22) {
                Text(L10n.tr("Materie")).font(appTheme.preservedTypography.pageTitle)
                if store.subjects.isEmpty {
                    StudyEmptyState(symbol: "books.vertical", title: L10n.tr("Nessuna materia"), detail: L10n.tr("Aggiungi una materia per registrare le sessioni."), actionTitle: L10n.tr("Aggiungi materia")) { nameFocused = true }
                }
                Card {
                    Text(editing == nil ? L10n.tr("Una nuova materia") : L10n.tr("Modifica materia")).font(appTheme.preservedTypography.headline)
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        SubjectIconPicker(selection: $icon, color: appTheme.subjectColor(color))
                        StudyTextEntry(L10n.tr("Nome della materia o progetto"), text: $name).focused($nameFocused).textFieldStyle(StudyTextFieldStyle())
                    }
                    HStack(spacing: DesignSystem.Spacing.md) {
                        SubjectColorPicker(selection: $color, isEditing: editing != nil).id(editing?.id)
                        Spacer(minLength: 0)
                    }
                    HStack {
                        Text(L10n.tr("Ore / settimana")).foregroundStyle(appTheme.palette.textSecondary)
                        Spacer()
                        StudyNumberField(title: L10n.tr("Ore alla settimana"), value: $goal, range: 0...168, step: 0.5).frame(width: DesignSystem.TimerLayout.studyField)
                    }
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        SubjectIconTile(symbol: icon, color: appTheme.subjectColor(color))
                        Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.tr("Materia") : name)
                            .font(appTheme.typography.heading).foregroundStyle(appTheme.subjectColor(color)).lineLimit(2)
                    }.accessibilityElement(children: .combine).accessibilityLabel(L10n.tr("Anteprima della materia"))
                    HStack {
                        if editing != nil { Button(L10n.tr("Annulla")) { editing = nil; name = "" } }
                        Button(editing == nil ? L10n.tr("Aggiungi materia") : L10n.tr("Salva modifiche")) {
                            let validGoal = goal.isFinite && goal >= 0 ? min(168, goal) : 5.0
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let editing { editing.name = trimmedName; editing.icon = icon; editing.color = color; editing.weeklyGoal = validGoal }
                            else { store.context.insert(Subject(name: trimmedName, icon: icon, color: color, weeklyGoal: validGoal)) }
                            if store.save() { name = ""; editing = nil }
                        }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                ForEach(store.subjects) { s in
                    Card(identity: s.id.uuidString + s.name + s.icon + s.color + String(s.weeklyGoal)) {
                        HStack { SubjectIconTile(symbol: s.icon, color: appTheme.subjectColor(s.color)); Text(s.name).font(appTheme.preservedTypography.title3).foregroundStyle(appTheme.subjectColor(s.color)); Spacer(); Button(L10n.tr("Modifica")) { editing = s; name = s.name; icon = s.icon; color = s.color; goal = s.weeklyGoal }; Button(L10n.tr("Elimina"), role: .destructive) { deleting = s }.disabled(store.active?.subjectID == s.id) }
                        HStack(spacing: DesignSystem.Spacing.xl) {
                            subjectMetric(L10n.tr("Settimana"), value: store.total(in: store.week, subject: s.id))
                            let monthInterval = Calendar.current.dateInterval(of: .month, for: store.now) ?? DateInterval(start: store.now, end: store.now)
                            subjectMetric(L10n.tr("Mese"), value: store.total(in: monthInterval, subject: s.id))
                            subjectMetric(L10n.tr("Sempre"), value: store.sessions.filter { $0.subjectID == s.id }.reduce(0) { $0 + $1.duration })
                        }
                        Text(L10n.count(store.sessions.filter { $0.subjectID == s.id }.count, singular: "%@ sessione salvata", plural: "%@ sessioni salvate")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        GoalBar(title: L10n.tr("Obiettivo settimanale"), value: store.total(in: store.week, subject: s.id), goal: s.weeklyGoal * 3600, color: appTheme.subjectColor(s.color))
                    }
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }.defaultScrollAnchor(.top, for: .initialOffset).alert(L10n.tr("Eliminare la materia?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button(L10n.tr("Annulla"), role: .cancel) {}; Button(L10n.tr("Elimina"), role: .destructive) { if let deleting { if store.settings.lastSubject == deleting.id { store.settings.lastSubject = nil }; store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text(L10n.tr("Le sessioni passate e il loro nome verranno conservati.")) }
    }
}
