import SwiftUI
struct SubjectsView: View {
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
                Text("Materie").font(appTheme.preservedTypography.pageTitle)
                if store.subjects.isEmpty {
                    StudyEmptyState(symbol: "books.vertical", title: "Dai un nome al tuo prossimo passo", detail: "Aggiungi una materia e ritrova il tuo tempo, tutto in un posto.", actionTitle: "Scrivi la prima materia") { nameFocused = true }
                }
                Card {
                    Text(editing == nil ? "Una nuova materia" : "Modifica materia").font(appTheme.preservedTypography.headline)
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        SubjectIconPicker(selection: $icon, color: appTheme.subjectColor(color))
                        StudyTextEntry("Nome della materia o progetto", text: $name).focused($nameFocused).textFieldStyle(StudyTextFieldStyle())
                    }
                    HStack(spacing: DesignSystem.Spacing.md) {
                        SubjectColorPicker(selection: $color, isEditing: editing != nil).id(editing?.id)
                        Spacer(minLength: 0)
                    }
                    HStack {
                        Text("Ore / settimana").foregroundStyle(appTheme.palette.textSecondary)
                        Spacer()
                        StudyNumberField(title: "Ore alla settimana", value: $goal, range: 0...168, step: 0.5).frame(width: DesignSystem.TimerLayout.studyField)
                    }
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        SubjectIconTile(symbol: icon, color: appTheme.subjectColor(color))
                        Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "La tua prossima materia" : name)
                            .font(appTheme.typography.heading).foregroundStyle(appTheme.subjectColor(color)).lineLimit(2)
                    }.accessibilityElement(children: .combine).accessibilityLabel("Anteprima della materia")
                    HStack {
                        if editing != nil { Button("Annulla") { editing = nil; name = "" } }
                        Button(editing == nil ? "Aggiungi materia" : "Salva modifiche") {
                            let validGoal = goal.isFinite && goal >= 0 ? min(168, goal) : 5.0
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let editing { editing.name = trimmedName; editing.icon = icon; editing.color = color; editing.weeklyGoal = validGoal }
                            else { store.context.insert(Subject(name: trimmedName, icon: icon, color: color, weeklyGoal: validGoal)) }
                            if store.save() { name = ""; editing = nil }
                        }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                ForEach(store.subjects) { s in
                    Card {
                        HStack { SubjectIconTile(symbol: s.icon, color: appTheme.subjectColor(s.color)); Text(s.name).font(appTheme.preservedTypography.title3).foregroundStyle(appTheme.subjectColor(s.color)); Spacer(); Button("Modifica") { editing = s; name = s.name; icon = s.icon; color = s.color; goal = s.weeklyGoal }; Button("Elimina", role: .destructive) { deleting = s }.disabled(store.active?.subjectID == s.id) }
                        HStack(spacing: DesignSystem.Spacing.xl) {
                            subjectMetric("Settimana", value: store.total(in: store.week, subject: s.id))
                            let monthInterval = Calendar.current.dateInterval(of: .month, for: store.now) ?? DateInterval(start: store.now, end: store.now)
                            subjectMetric("Mese", value: store.total(in: monthInterval, subject: s.id))
                            subjectMetric("Sempre", value: store.sessions.filter { $0.subjectID == s.id }.reduce(0) { $0 + $1.duration })
                        }
                        Text("\(store.sessions.filter { $0.subjectID == s.id }.count) sessioni salvate").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        GoalBar(title: "Obiettivo settimanale", value: store.total(in: store.week, subject: s.id), goal: s.weeklyGoal * 3600, color: appTheme.subjectColor(s.color))
                    }
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }.defaultScrollAnchor(.top, for: .initialOffset).alert("Eliminare la materia?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button("Annulla", role: .cancel) {}; Button("Elimina", role: .destructive) { if let deleting { if store.settings.lastSubject == deleting.id { store.settings.lastSubject = nil }; store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text("Le sessioni passate e il loro nome verranno conservati.") }
    }
}
