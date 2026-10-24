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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    Text(L10n.tr("Una nuova materia")).font(appTheme.preservedTypography.headline)
                    SubjectFormFields(name: $name, icon: $icon, color: $color, goal: $goal, nameFocused: $nameFocused, isEditing: false)
                    HStack {
                        Button(L10n.tr("Aggiungi materia")) {
                            let validGoal = goal.isFinite && goal >= 0 ? min(168, goal) : 5.0
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            store.context.insert(Subject(name: trimmedName, icon: icon, color: color, weeklyGoal: validGoal))
                            if store.save() { name = "" }
                        }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(L10n.tr("Inserisci un nome per aggiungere la materia"))
                            .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                    }
                }
                sectionTitle(L10n.tr("Da completare"), count: store.activeSubjects.count)
                if store.activeSubjects.isEmpty {
                    Text(L10n.tr("Nessuna materia da completare.")).foregroundStyle(appTheme.palette.textSecondary)
                }
                ForEach(store.activeSubjects) { subject in activeCard(subject).transition(.opacity) }
                Button {
                    store.settings.completedSubjectsExpanded = !(store.settings.completedSubjectsExpanded ?? true)
                } label: {
                    HStack {
                        sectionTitle(L10n.tr("Completate"), count: store.completedSubjects.count)
                        Image(systemName: store.settings.completedSubjectsExpanded ?? true ? "chevron.down" : "chevron.right")
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).interactiveHover(listRow: true)
                    .modifier(KeyboardFocusBorder())
                    .accessibilityLabel(L10n.tr("Completate: %@", String(store.completedSubjects.count)))
                    .accessibilityValue(store.settings.completedSubjectsExpanded ?? true ? L10n.tr("Espansa") : L10n.tr("Compressa"))
                if store.settings.completedSubjectsExpanded ?? true {
                    if store.completedSubjects.isEmpty {
                        Text(L10n.tr("Le materie che completi compaiono qui.")).foregroundStyle(appTheme.palette.textSecondary)
                    }
                    ForEach(store.completedSubjects) { subject in completedCard(subject).transition(.opacity) }
                }

            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }.defaultScrollAnchor(.top, for: .initialOffset)
            .animation(reduceMotion || store.settings.animations == "Off" ? nil : .easeOut(duration: DesignSystem.SubjectAppearance.sectionTransitionDuration), value: store.activeSubjects.map(\.id))
            .sheet(item: $editing) { SubjectEditor(subject: $0) }
            .alert(L10n.tr("Eliminare la materia?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button(L10n.tr("Annulla"), role: .cancel) {}; Button(L10n.tr("Elimina"), role: .destructive) { if let deleting { if store.settings.lastSubject == deleting.id { store.settings.lastSubject = nil }; store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text(L10n.tr("Le sessioni passate e il loro nome verranno conservati.")) }
    }
    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title).font(appTheme.typography.heading)
            Text(String(count)).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            Spacer()
        }.accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }
    private func activeCard(_ subject: Subject) -> some View {
        let summary = store.subjectSummaries[subject.id] ?? StudyStore.SubjectSummary()
        return Card(identity: subject.id) {
            HStack {
                SubjectIconTile(symbol: subject.icon, color: appTheme.subjectColor(subject.color))
                Text(verbatim: subject.name).textCase(nil).font(appTheme.preservedTypography.title3).foregroundStyle(appTheme.subjectColor(subject.color))
                Spacer()
                Button(L10n.tr("Modifica")) { editing = subject }
                Button(L10n.tr("Elimina"), role: .destructive) { deleting = subject }.disabled(store.active?.subjectID == subject.id)
            }
            HStack(spacing: DesignSystem.Spacing.xl) {
                subjectMetric(L10n.tr("Settimana"), value: summary.week)
                subjectMetric(L10n.tr("Mese"), value: summary.month)
                subjectMetric(L10n.tr("Sempre"), value: summary.total)
            }
            Text(L10n.count(summary.count, singular: "%@ sessione salvata", plural: "%@ sessioni salvate"))
                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            GoalBar(title: L10n.tr("Obiettivo settimanale"), value: summary.week, goal: subject.weeklyGoal * 3600, color: appTheme.subjectColor(subject.color))
            StudyUnitsSection(subject: subject)
        }
    }
    private func completedCard(_ subject: Subject) -> some View {
        let summary = store.subjectSummaries[subject.id] ?? StudyStore.SubjectSummary()
        return Card(identity: subject.id) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                SubjectIconTile(symbol: subject.icon, color: appTheme.subjectColor(subject.color))
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(verbatim: subject.name).textCase(nil).font(appTheme.typography.small).lineLimit(2)
                    if let date = subject.completedAt {
                        Text(L10n.tr("Completata il %@", date.formatted(.dateTime.day().month(.abbreviated).locale(L10n.locale))))
                            .font(appTheme.typography.caption)
                    }
                    if let note = subject.gradeNote, !note.isEmpty { Text(verbatim: note).font(appTheme.typography.caption) }
                }.foregroundStyle(appTheme.palette.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: DesignSystem.Spacing.sm)
                Group {
                    if let grade = subject.gradeValue {
                        Text(String(grade) + ((subject.gradeHonors ?? false) && grade == 30 ? L10n.tr(" e lode") : ""))
                    } else { Image(systemName: "checkmark") }
                }.font(appTheme.typography.small).padding(DesignSystem.Spacing.xs)
                    .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                    .accessibilityLabel(subject.gradeValue.map { L10n.tr("Voto: %@", String($0) + ((subject.gradeHonors ?? false) ? L10n.tr(" e lode") : "")) } ?? L10n.tr("Completata"))
                Text(durationText(summary.total) + " · " + L10n.count(summary.count, singular: "%@ sessione", plural: "%@ sessioni"))
                    .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: DesignSystem.PreservedGeometry.points132, alignment: .trailing)
                Button(L10n.tr("Modifica")) { editing = subject }.fixedSize()
                CompletedSubjectActions(subject: subject, delete: { deleting = subject })
            }
            if !(store.unitsBySubject[subject.id] ?? []).isEmpty { StudyUnitsSection(subject: subject) }
        }
    }

}

/// Creation and editing share the same controls; opening an editor never changes the creation draft.
private struct SubjectFormFields: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var name: String
    @Binding var icon: String
    @Binding var color: String
    @Binding var goal: Double
    var nameFocused: FocusState<Bool>.Binding
    var isEditing: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                SubjectIconPicker(selection: $icon, color: appTheme.subjectColor(color))
                StudyTextEntry(L10n.tr("Nome della materia o progetto"), text: $name, preserveCase: true).focused(nameFocused).textFieldStyle(StudyTextFieldStyle())
            }
            HStack(spacing: DesignSystem.Spacing.md) {
                SubjectColorPicker(selection: $color, isEditing: isEditing)
                Spacer(minLength: 0)
            }
            HStack {
                Text(L10n.tr("Ore / settimana")).foregroundStyle(appTheme.palette.textSecondary)
                Spacer()
                StudyNumberField(title: L10n.tr("Ore alla settimana"), value: $goal, range: 0...168, step: 0.5).frame(width: DesignSystem.TimerLayout.studyField)
            }
            HStack(spacing: DesignSystem.Spacing.sm) {
                SubjectIconTile(symbol: icon, color: appTheme.subjectColor(color))
                Text(verbatim: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.tr("Materia") : name).textCase(nil)
                    .font(appTheme.typography.heading).foregroundStyle(appTheme.subjectColor(color)).lineLimit(2)
            }.accessibilityElement(children: .combine).accessibilityLabel(L10n.tr("Anteprima della materia"))

        }
    }
}

/// A value copy keeps Cancel (including Escape) independent of the persisted model.
struct SubjectEditDraft {
    var name: String
    var icon: String
    var color: String
    var goal: Double
    var completed: Bool
    var grade: String
    var honors: Bool
    var gradeNote: String?
    var completedAt: Date?
    init(subject: Subject) {
        name = subject.name; icon = subject.icon; color = subject.color; goal = subject.weeklyGoal
        completed = subject.isCompleted; grade = subject.gradeValue.map(String.init) ?? ""
        honors = subject.gradeHonors ?? false; gradeNote = subject.gradeNote; completedAt = subject.completedAt
    }
    var validGrade: Bool {
        let value = grade.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || (value.allSatisfy { "0123456789".contains($0) } && Int(value).map { (18...30).contains($0) } == true)
    }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (!completed || validGrade) }
    func apply(to subject: Subject) {
        guard isValid else { return }
        subject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        subject.icon = icon; subject.color = color
        let newlyCompleted = completed && !subject.isCompleted
        subject.isCompleted = completed
        if completed {
            subject.gradeValue = Int(grade.trimmingCharacters(in: .whitespacesAndNewlines))
            subject.gradeHonors = subject.gradeValue == 30 && honors
            subject.completedAt = completedAt ?? (newlyCompleted ? Date() : subject.completedAt)
        }
        subject.gradeNote = gradeNote
        subject.weeklyGoal = goal.isFinite && goal >= 0 ? min(168, goal) : 5.0
    }
}

struct SubjectEditor: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    let subject: Subject
    @State private var draft: SubjectEditDraft
    @State private var saveFailed = false
    @State private var parentHeight: CGFloat
    @State private var measuredBody: CGFloat?
    @State private var chromeHeight = DesignSystem.Interaction.controlHeight * 2
    @State private var windowReady = false

    init(subject: Subject, parentHeight: CGFloat = DesignSystem.SubjectEditorLayout.fallbackWindowHeight) {
        self.subject = subject
        _parentHeight = State(initialValue: parentHeight)
        _draft = State(initialValue: SubjectEditDraft(subject: subject))
    }
    var body: some View {
        let bodyLimit = DesignSystem.SubjectEditorLayout.bodyLimit(windowHeight: parentHeight, chromeHeight: chromeHeight)
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(L10n.tr("Modifica materia")).font(appTheme.preservedTypography.title2)
                .background { GeometryReader { Color.clear.preference(key: SubjectEditorChromeHeight.self, value: $0.size.height) } }
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SubjectFormFields(name: $draft.name, icon: $draft.icon, color: $draft.color,
                                      goal: $draft.goal, nameFocused: $nameFocused, isEditing: true)
                    Toggle(L10n.tr("Materia completata"), isOn: $draft.completed)
                        .toggleStyle(StudyToggleStyle())
                        .onChange(of: draft.completed) { old, new in if new && !old && draft.completedAt == nil && !subject.isCompleted { draft.completedAt = Date() } }
                    if draft.completed {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(L10n.tr("Voto (facoltativo)")).foregroundStyle(appTheme.palette.textSecondary)
                            StudyTextEntry(L10n.tr("Da 18 a 30"), text: $draft.grade).textFieldStyle(StudyTextFieldStyle())
                            if !draft.validGrade {
                                Text(L10n.tr("Inserisci un voto da 18 a 30")).font(appTheme.typography.caption).foregroundStyle(appTheme.appearance.destructiveInk)
                            }
                            if Int(draft.grade.trimmingCharacters(in: .whitespacesAndNewlines)) == 30 {
                                Toggle(L10n.tr("Lode"), isOn: $draft.honors).toggleStyle(StudyToggleStyle())
                            }
                            if let date = draft.completedAt {
                                DatePicker(L10n.tr("Data di completamento"), selection: Binding(get: { draft.completedAt ?? date }, set: { draft.completedAt = $0 }), displayedComponents: .date)
                            } else {
                                HStack {
                                    Text(L10n.tr("Data non disponibile")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                                    Spacer()
                                    Button(L10n.tr("Aggiungi data")) { draft.completedAt = Date() }
                                }
                            }
                            if let note = draft.gradeNote, !note.isEmpty {
                                Text(L10n.tr("Nota del voto precedente")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                                Text(verbatim: note).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                            }
                        }
                    }
                    if saveFailed {
                        Text(L10n.tr("Impossibile salvare. Riprova."))
                            .foregroundStyle(appTheme.appearance.destructiveInk)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, DesignSystem.SubjectEditorLayout.scrollGutter)
                    .background { GeometryReader { Color.clear.preference(key: SubjectEditorBodyHeight.self, value: $0.size.height) } }
                    .id("subject-form-top")
            }.frame(height: min(measuredBody ?? bodyLimit, bodyLimit))
                .defaultScrollAnchor(.top, for: .initialOffset)
                .onChange(of: windowReady) {
                    guard windowReady else { return }
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) { proxy.scrollTo("subject-form-top", anchor: .top) }
                }
            }
            HStack {
                Button(L10n.tr("Annulla")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(L10n.tr("Salva modifiche")) {
                    guard draft.isValid else { return }
                    let original = SubjectEditDraft(subject: subject)
                    let originalCompleted = subject.completed
                    let originalGrade = subject.grade
                    let originalValue = subject.gradeValue; let originalHonors = subject.gradeHonors
                    let originalNote = subject.gradeNote; let originalDate = subject.completedAt
                    draft.apply(to: subject)
                    if store.save() { dismiss() }
                    else {
                        // Restore only this subject, leaving unrelated pending context changes intact.
                        subject.name = original.name; subject.icon = original.icon
                        subject.color = original.color; subject.weeklyGoal = original.goal
                        subject.completed = originalCompleted; subject.grade = originalGrade
                        subject.gradeValue = originalValue; subject.gradeHonors = originalHonors
                        subject.gradeNote = originalNote; subject.completedAt = originalDate
                        saveFailed = true
                    }
                }.buttonStyle(ResponsiveButtonStyle(prominent: true))
                    .keyboardShortcut(.defaultAction).disabled(!draft.isValid)
            }.background { GeometryReader { Color.clear.preference(key: SubjectEditorChromeHeight.self, value: $0.size.height) } }
        }.padding(DesignSystem.SubjectEditorLayout.padding)
            .frame(width: DesignSystem.SubjectEditorLayout.minimumWidth)
            .onPreferenceChange(SubjectEditorBodyHeight.self) { if $0 > 0 { measuredBody = $0 } }
            .onPreferenceChange(SubjectEditorChromeHeight.self) { if $0 > 0 { chromeHeight = $0 } }
            .background(appTheme.palette.background)
            .background {
                SubjectEditorWindowMetrics { height in
                    if parentHeight != height { parentHeight = height }
                    if !windowReady { windowReady = true }
                }.frame(width: 0, height: 0).allowsHitTesting(false).accessibilityHidden(true)
            }
            .interactionHost(scope: "subject-editor")
    }
}


private struct SubjectEditorBodyHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
private struct SubjectEditorChromeHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value += nextValue() }
}

/// Listen only to parent-window resize/presentation events; no polling or per-frame work.
private struct SubjectEditorWindowMetrics: NSViewRepresentable {
    let changed: (CGFloat) -> Void
    func makeNSView(context: Context) -> Host { Host(changed: changed) }
    func updateNSView(_ view: Host, context: Context) { view.changed = changed }
    static func dismantleNSView(_ view: Host, coordinator: ()) { view.stop() }
    final class Host: NSView {
        var changed: (CGFloat) -> Void
        private var observers: [NSObjectProtocol] = []
        private weak var attachedSheet: NSWindow?
        init(changed: @escaping (CGFloat) -> Void) { self.changed = changed; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); stop()
            guard window != nil else { return }
            for name in [NSWindow.didResizeNotification, NSWindow.didBecomeKeyNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.report() }
                })
            }
            DispatchQueue.main.async { [weak self] in self?.report() }
        }
        private func report() {
            guard let sheet = window, let parent = sheet.sheetParent else { return }
            if attachedSheet !== sheet {
                attachedSheet = sheet
                sheet.initialFirstResponder = nil
                sheet.makeFirstResponder(nil)
            }
            changed(parent.contentLayoutRect.height)
        }
        func stop() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll(); attachedSheet = nil
        }
        deinit { observers.forEach(NotificationCenter.default.removeObserver) }
    }
}

private struct CompletedSubjectActions: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    let subject: Subject
    let delete: () -> Void
    @State private var showing = false
    var body: some View {
        Button { showing.toggle() } label: {
            Image(systemName: "ellipsis").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle())
        }.accessibilityLabel(L10n.tr("Azioni della materia"))
            .popover(isPresented: $showing) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Button(L10n.tr("Riapri")) {
                        subject.isCompleted = false
                        if !store.save() { subject.isCompleted = true }
                        showing = false
                    }
                    Button(L10n.tr("Elimina"), role: .destructive) { showing = false; delete() }
                        .disabled(store.active?.subjectID == subject.id)
                }.padding(DesignSystem.Spacing.md).background(theme.palette.elevatedSurface)
                    .onExitCommand { showing = false }
            }
    }
}


struct StudyUnitsSection: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    let subject: Subject
    @State private var expanded = false
    @State private var creating = false
    @State private var batch = false
    @State private var editing: StudyUnit?
    @State private var deleting: StudyUnit?
    init(subject: Subject, initiallyExpanded: Bool = false) { self.subject = subject; _expanded = State(initialValue:initiallyExpanded) }
    private var list: [StudyUnit] { store.unitsBySubject[subject.id] ?? [] }
    var body: some View {
        VStack(alignment:.leading,spacing:DesignSystem.Spacing.sm) {
            Button { expanded.toggle() } label: {
                HStack {
                    Text(L10n.tr("Unità di studio")).font(theme.typography.heading)
                    Text(String(list.count)).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                    Spacer(); Image(systemName:expanded ? "chevron.up" : "chevron.down")
                }.frame(maxWidth:.infinity).contentShape(Rectangle())
            }.buttonStyle(.plain).interactiveHover(listRow:true).modifier(KeyboardFocusBorder())
                .accessibilityValue(expanded ? L10n.tr("Espansa") : L10n.tr("Compressa"))
            if expanded {
                if !subject.isCompleted {
                    HStack {
                        Button(L10n.tr("Aggiungi unità")) { creating = true }
                        Button(L10n.tr("Crea più unità")) { batch = true }
                    }
                }
                if list.isEmpty {
                    Text(L10n.tr("Aggiungi lezioni, capitoli o pagine da studiare")).foregroundStyle(theme.palette.textSecondary)
                }
                LazyVStack(alignment:.leading,spacing:DesignSystem.Spacing.sm) {
                    ForEach(list) { unit in unitRow(unit) }
                }
            }
        }
        .sheet(isPresented:$creating) { StudyUnitEditor(subject:subject) }
        .sheet(item:$editing) { StudyUnitEditor(subject:subject,unit:$0) }
        .sheet(isPresented:$batch) { StudyUnitsBatchEditor(subject:subject) }
        .alert(L10n.tr("Eliminare l’unità?"),isPresented:Binding(get:{ deleting != nil },set:{ if !$0 { deleting = nil } })) {
            Button(L10n.tr("Annulla"),role:.cancel) { deleting = nil }
            Button(L10n.tr("Elimina"),role:.destructive) { if let deleting { store.deleteUnit(deleting) }; deleting = nil }
        } message: { Text(L10n.tr("Le sessioni e il tempo studiato restano nella cronologia.")) }
    }
    private func unitRow(_ unit: StudyUnit) -> some View {
        VStack(alignment:.leading,spacing:DesignSystem.Spacing.xs) {
            HStack(alignment:.top) {
                VStack(alignment:.leading,spacing:DesignSystem.Spacing.xs) {
                    Text(verbatim:unit.title).font(theme.typography.body).fixedSize(horizontal:false,vertical:true)
                    Text(unit.unitKind.title + " · " + unit.unitState.title).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                    Text(durationText(store.unitSeconds[unit.id] ?? 0) + (store.unitEstimates[unit.id].map { " · " + L10n.tr("Stima: %@",durationText($0*60)) } ?? ""))
                        .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                }.frame(maxWidth:.infinity,alignment:.leading)
                Button { store.moveUnit(unit,by:-1) } label: { Image(systemName:"arrow.up") }
                    .disabled(list.first?.id == unit.id).help(L10n.tr("Sposta su")).accessibilityLabel(L10n.tr("Sposta su"))
                Button { store.moveUnit(unit,by:1) } label: { Image(systemName:"arrow.down") }
                    .disabled(list.last?.id == unit.id).help(L10n.tr("Sposta giù")).accessibilityLabel(L10n.tr("Sposta giù"))
                Button(L10n.tr("Modifica")) { editing = unit }
                Button { deleting = unit } label: { Image(systemName:"trash") }
                    .help(L10n.tr("Elimina unità")).accessibilityLabel(L10n.tr("Elimina unità"))
            }
            Divider().overlay(theme.palette.border).allowsHitTesting(false)
        }.padding(.vertical,DesignSystem.Spacing.xs)
    }
}

struct StudyUnitDraft {
    var title = ""
    var kind: StudyUnitKind = .lesson
    var state: StudyUnitState = .todo
    var estimate = ""
    var firstPage = ""
    var lastPage = ""
    init(unit: StudyUnit? = nil) {
        guard let unit else { return }
        title = unit.title; kind = unit.unitKind; state = unit.unitState
        estimate = unit.estimatedMinutes.map { String($0) } ?? ""
        firstPage = unit.firstPage.map(String.init) ?? ""; lastPage = unit.lastPage.map(String.init) ?? ""
    }
    var isValid: Bool {
        guard !title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return false }
        if !estimate.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && ProjectionTargetInput.hours(estimate) == nil { return false }
        if kind == .pages { guard let first = Int(firstPage), let last = Int(lastPage), first > 0, last >= first, last < Int.max else { return false } }
        return true
    }
    func apply(to unit: StudyUnit) {
        guard isValid else { return }
        unit.title = title.trimmingCharacters(in:.whitespacesAndNewlines); unit.kind = kind.rawValue; unit.state = state.rawValue
        unit.estimatedMinutes = ProjectionTargetInput.hours(estimate)
        unit.firstPage = kind == .pages ? Int(firstPage) : nil; unit.lastPage = kind == .pages ? Int(lastPage) : nil
    }
}
struct StudyUnitEditor: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let subject: Subject
    var unit: StudyUnit?
    @State private var draft: StudyUnitDraft
    init(subject: Subject,unit: StudyUnit? = nil) { self.subject = subject; self.unit = unit; _draft = State(initialValue:StudyUnitDraft(unit:unit)) }
    var body: some View {
        VStack(alignment:.leading,spacing:DesignSystem.Spacing.md) {
            Text(unit == nil ? L10n.tr("Aggiungi unità") : L10n.tr("Modifica unità")).font(theme.typography.heading)
            ScrollView {
                VStack(alignment:.leading,spacing:DesignSystem.Spacing.md) {
                    StudyTextEntry(L10n.tr("Titolo dell’unità"),text:$draft.title,preserveCase:true).textFieldStyle(StudyTextFieldStyle())
                    StudyDropdown(title:L10n.tr("Tipo"),options:StudyUnitKind.allCases.map { ($0,$0.title) },selection:$draft.kind)
                    StudyDropdown(title:L10n.tr("Stato"),options:StudyUnitState.allCases.map { ($0,$0.title) },selection:$draft.state)
                    if draft.kind == .pages {
                        HStack {
                            StudyTextEntry(L10n.tr("Pagina iniziale"),text:$draft.firstPage).textFieldStyle(StudyTextFieldStyle())
                            StudyTextEntry(L10n.tr("Pagina finale"),text:$draft.lastPage).textFieldStyle(StudyTextFieldStyle())
                        }
                    }
                    Text(L10n.tr("Stima in minuti (facoltativa)")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                    StudyTextEntry(L10n.tr("Nessuna stima manuale"),text:$draft.estimate).textFieldStyle(StudyTextFieldStyle())
                    Text(L10n.tr("Se lasci vuoto, la stima viene proposta dopo almeno 3 unità finite dello stesso tipo.")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                    if !draft.isValid { Text(L10n.tr("Inserisci un titolo e valori validi.")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary) }
                }.padding(.trailing,DesignSystem.Spacing.sm)
            }.frame(maxHeight:DesignSystem.SubjectEditorLayout.fallbackWindowHeight/2)
            HStack {
                Button(L10n.tr("Annulla")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(L10n.tr("Salva")) {
                    guard draft.isValid else { return }
                    let item = unit ?? StudyUnit(subjectID:subject.id,title:draft.title,order:(store.unitsBySubject[subject.id]?.map(\.order).max() ?? -1)+1)
                    draft.apply(to:item); if unit == nil { store.context.insert(item) }
                    if store.save() { dismiss() } else { store.context.rollback(); store.refresh() }
                }.buttonStyle(ResponsiveButtonStyle(prominent:true)).disabled(!draft.isValid).keyboardShortcut(.defaultAction)
            }
        }.padding(DesignSystem.Spacing.lg).frame(width:DesignSystem.SubjectEditorLayout.minimumWidth).background(theme.palette.background)
    }
}
struct StudyUnitsBatchEditor: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let subject: Subject
    @State private var kind: StudyUnitKind = .lesson
    @State private var prefix = ""
    @State private var first = 1.0
    @State private var last = 20.0
    @State private var block = 15.0
    private var seeds: [UnitSeed] {
        let prefix = prefix.isEmpty ? kind.title + " " : prefix
        // Direct numeric edits can be temporarily fractional or out of range.
        // Exact conversion rejects them without a floating-point-to-Int trap.
        guard let first = Int(exactly:first), let last = Int(exactly:last) else { return [] }
        if kind == .pages {
            guard let block = Int(exactly:block) else { return [] }
            return UnitRules.pages(from:first,through:last,block:block,prefix:prefix)
        }
        return UnitRules.numbered(from:first,through:last,prefix:prefix)
    }
    var body: some View {
        VStack(alignment:.leading,spacing:DesignSystem.Spacing.md) {
            Text(L10n.tr("Crea più unità")).font(theme.typography.heading)
            StudyDropdown(title:L10n.tr("Tipo"),options:StudyUnitKind.allCases.map { ($0,$0.title) },selection:$kind)
            StudyTextEntry(L10n.tr("Prefisso (facoltativo)"),text:$prefix,preserveCase:true).textFieldStyle(StudyTextFieldStyle())
            HStack { Text(L10n.tr("Da")); Spacer(); StudyNumberField(title:L10n.tr("Da"),value:$first,range:1...10000) }
            HStack { Text(L10n.tr("A")); Spacer(); StudyNumberField(title:L10n.tr("A"),value:$last,range:1...10000) }
            if kind == .pages { HStack { Text(L10n.tr("Pagine per blocco")); Spacer(); StudyNumberField(title:L10n.tr("Pagine per blocco"),value:$block,range:1...10000) } }
            Text(L10n.tr("%@ unità da creare",String(seeds.count))).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            if let first = seeds.first, let last = seeds.last { Text(first.title + " … " + last.title).font(theme.typography.caption).lineLimit(2) }
            HStack {
                Button(L10n.tr("Annulla")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(L10n.tr("Crea")) { store.addUnits(subject:subject,seeds:seeds,kind:kind); if store.error == nil { dismiss() } }
                    .buttonStyle(ResponsiveButtonStyle(prominent:true)).disabled(seeds.isEmpty).keyboardShortcut(.defaultAction)
            }
        }.padding(DesignSystem.Spacing.lg).frame(width:DesignSystem.SubjectEditorLayout.minimumWidth).background(theme.palette.background)
    }
}
