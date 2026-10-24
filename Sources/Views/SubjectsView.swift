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
                ForEach(store.subjects) { s in
                    Card(identity: s.id.uuidString + s.name + s.icon + s.color + String(s.weeklyGoal)) {
                        HStack { SubjectIconTile(symbol: s.icon, color: appTheme.subjectColor(s.color)); Text(s.name).font(appTheme.preservedTypography.title3).foregroundStyle(appTheme.subjectColor(s.color)); Spacer(); Button(L10n.tr("Modifica")) { editing = s }; Button(L10n.tr("Elimina"), role: .destructive) { deleting = s }.disabled(store.active?.subjectID == s.id) }
                        if s.isCompleted {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Label(L10n.tr("Completata"), systemImage: "checkmark.circle")
                                if let grade = s.grade, !grade.isEmpty {
                                    Text(L10n.tr("Voto: %@", grade))
                                }
                            }.font(appTheme.preservedTypography.caption)
                                .foregroundStyle(appTheme.palette.textSecondary)
                        }
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
        }.defaultScrollAnchor(.top, for: .initialOffset)
            .sheet(item: $editing) { SubjectEditor(subject: $0) }
            .alert(L10n.tr("Eliminare la materia?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button(L10n.tr("Annulla"), role: .cancel) {}; Button(L10n.tr("Elimina"), role: .destructive) { if let deleting { if store.settings.lastSubject == deleting.id { store.settings.lastSubject = nil }; store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text(L10n.tr("Le sessioni passate e il loro nome verranno conservati.")) }
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
                StudyTextEntry(L10n.tr("Nome della materia o progetto"), text: $name).focused(nameFocused).textFieldStyle(StudyTextFieldStyle())
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
                Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.tr("Materia") : name)
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
    init(subject: Subject) {
        name = subject.name; icon = subject.icon; color = subject.color; goal = subject.weeklyGoal
        completed = subject.isCompleted; grade = subject.grade ?? ""
    }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func apply(to subject: Subject) {
        subject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        subject.icon = icon; subject.color = color
        subject.isCompleted = completed
        let trimmedGrade = grade.trimmingCharacters(in: .whitespacesAndNewlines)
        subject.grade = trimmedGrade.isEmpty ? nil : trimmedGrade
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
                    if draft.completed {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(L10n.tr("Voto (facoltativo)")).foregroundStyle(appTheme.palette.textSecondary)
                            StudyTextEntry(L10n.tr("Es. 30 e lode, 28/30, Idoneità"), text: $draft.grade)
                                .textFieldStyle(StudyTextFieldStyle())
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
                    draft.apply(to: subject)
                    if store.save() { dismiss() }
                    else {
                        // Restore only this subject, leaving unrelated pending context changes intact.
                        subject.name = original.name; subject.icon = original.icon
                        subject.color = original.color; subject.weeklyGoal = original.goal
                        subject.completed = originalCompleted; subject.grade = originalGrade
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
