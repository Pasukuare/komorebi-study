import SwiftUI
struct CalendarView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @State private var month = Date()
    @State private var selected = Date()
    @State private var adding = false
    @State private var editing: StudyExam?
    @State private var deleting: StudyExam?
    let columns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xs), count: 7)
    var days: [Date?] {
        let c = Calendar.current; let start = c.dateInterval(of: .month, for: month)?.start ?? month
        let offset = (c.component(.weekday, from: start) - c.firstWeekday + 7) % 7
        let range = c.range(of: .day, in: .month, for: month) ?? 1..<31
        return Array(repeating: nil, count: offset) + range.compactMap { c.date(byAdding: .day, value: $0 - 1, to: start) }
    }
    var body: some View {
        let calendar = Calendar.current
        let visibleDays = days
        let intervals = visibleDays.compactMap { $0 }.compactMap { calendar.dateInterval(of: .day, for: $0) }
        let sharesByDay = Dictionary(uniqueKeysWithValues: zip(intervals.map(\.start), store.calendarShares(in: intervals)))
        let examCounts = Dictionary(grouping: store.exams, by: { calendar.startOfDay(for: $0.date) }).mapValues(\.count)
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy22) {
                HStack {
                    Text(month, format: .dateTime.month(.wide).year()).font(appTheme.preservedTypography.pageTitle)
                    Spacer(); Button(L10n.tr("Aggiungi esame"), systemImage: "plus") { adding = true }.buttonStyle(ResponsiveButtonStyle(prominent: true))
                    Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }.accessibilityLabel(L10n.tr("Mese precedente"))
                    Button(L10n.tr("Oggi")) { month = Date(); selected = Date() }
                    Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }.accessibilityLabel(L10n.tr("Mese successivo"))
                }
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<7, id: \.self) { n in Text(L10n.displayCalendar.shortStandaloneWeekdaySymbols[(Calendar.current.firstWeekday - 1 + n) % 7]).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary) }
                    ForEach(Array(visibleDays.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let interval = Calendar.current.dateInterval(of: .day, for: date) ?? DateInterval(start: date, end: date)
                            let shares = sharesByDay[interval.start] ?? []
                            let examCount = examCounts[interval.start] ?? 0
                            CalendarDayCell(date: date, shares: shares, examCount: examCount, selected: Calendar.current.isDate(date, inSameDayAs: selected)) { selected = date }
                        } else { Color.clear.frame(height: DesignSystem.CalendarAppearance.cellHeight) }
                    }
                }
                Card {
                    Text(selected, format: .dateTime.day().month(.wide)).font(appTheme.preservedTypography.title2)
                    let dayExams = store.exams.filter { Calendar.current.isDate($0.date, inSameDayAs: selected) }
                    ForEach(dayExams) { exam in
                        HStack {
                            ExamRow(exam: exam)
                            Button(L10n.tr("Modifica")) { editing = exam }
                            Button(L10n.tr("Elimina"), role: .destructive) { deleting = exam }
                        }
                    }
                    if !dayExams.isEmpty { Divider() }
                    let interval = Calendar.current.dateInterval(of: .day, for: selected) ?? DateInterval(start: selected, end: selected)
                    let sessions = store.sessions.filter { store.contribution($0, in: interval) > 0 }
                    if sessions.isEmpty { Text(L10n.tr("Nessuna sessione in questo giorno.")).foregroundStyle(appTheme.palette.textSecondary) }
                    ForEach(sessions) { session in SessionRow(session: session) }
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }
        .overlayPreferenceValue(CalendarDayTooltipKey.self) { item in
            GeometryReader { geometry in
                if let item {
                    CalendarDayTooltip(details: item.details, cell: geometry[item.anchor], bounds: geometry.size)
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
        .sheet(isPresented: $adding) { ExamEditor(initialDate: selected) }
        .sheet(item: $editing) { exam in ExamEditor(exam: exam, initialDate: exam.date) }
        .alert(L10n.tr("Eliminare l’esame?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button(L10n.tr("Annulla"), role: .cancel) {}
            Button(L10n.tr("Elimina"), role: .destructive) { if let deleting { store.context.delete(deleting); store.save() }; deleting = nil }
        } message: { Text(L10n.tr("Le sessioni di studio rimarranno nell’archivio.")) }
    }
}
struct SessionRow: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    let session: StudySession
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.legacy14) {
            SubjectIconTile(symbol: store.subjects.first { $0.id == session.subjectID }?.icon ?? "book.closed", color: appTheme.subjectColor(store.subjects.first { $0.id == session.subjectID }?.color ?? "Salvia"))
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) { Text(verbatim: session.subjectName).textCase(nil).font(appTheme.preservedTypography.headline); Text(session.note.isEmpty ? TimerMode.displayName(for: session.timerMode) : session.note).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary).lineLimit(2) }
            Spacer(); VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) { Text(durationText(session.duration)).monospacedDigit(); Text(session.startDate, format: .dateTime.day().month().hour().minute()).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary) }
        }.padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct ExamRow: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    let exam: StudyExam
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.legacy14) {
            Image(systemName: "graduationcap").foregroundStyle(appTheme.palette.accent).font(appTheme.preservedTypography.title2)
            VStack(alignment: .leading, spacing: DesignSystem.PreservedGeometry.gap5) {
                Text(verbatim: store.examDisplayTitle(exam)).textCase(nil).font(appTheme.preservedTypography.headline)
                if let subject = store.subjects.first(where: { $0.id == exam.subjectID }), exam.displayTitle(linkedSubjectName: subject.name) != subject.name { Text(verbatim: subject.name).textCase(nil).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary) }
                if !exam.note.isEmpty { Text(exam.note).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary).lineLimit(2) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DesignSystem.PreservedGeometry.gap5) {
                Text(exam.date, format: .dateTime.day().month(.abbreviated).year()).font(appTheme.preservedTypography.callout)
                if exam.hasTime { Text(exam.date, format: .dateTime.hour().minute()).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary) }
            }
        }.padding(.vertical, DesignSystem.Spacing.xs)
    }
}
struct ExamEditor: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    var exam: StudyExam? = nil
    var initialDate: Date
    @State private var kind = ExamKind.unspecified
    @State private var kindDetail = ""
    @State private var date = Date()
    @State private var hasTime = false
    @State private var subjectID: UUID?
    @State private var note = ""
    @State private var saveError: String?
    private var subjectOptions: [(UUID?, String)] {
        let choices: [(UUID?, String)]
        if let id = exam?.subjectID {
            choices = store.editingSubjectChoices(currentID: id, currentName: store.subjectsByID[id]?.name ?? L10n.tr("Materia"))
        } else { choices = store.activeSubjectChoices }
        if exam != nil { return [(nil, L10n.tr("Nessuna materia"))] + choices }
        return choices
    }
    var body: some View {
        Form {
            Text(exam == nil ? L10n.tr("Nuovo esame") : L10n.tr("Modifica esame")).font(appTheme.preservedTypography.editorTitle)
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(L10n.tr("Materia")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                StudyDropdown(title: L10n.tr("Materia"), options: subjectOptions, selection: $subjectID)
            }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(L10n.tr("Tipo di prova (facoltativo)")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                StudyDropdown(title: L10n.tr("Tipo di prova (facoltativo)"), options: ExamKind.allCases.map { ($0, $0.title) }, selection: $kind)
            }
            if kind == .other {
                StudyTextEntry(L10n.tr("Descrivi il tipo di prova"), text: $kindDetail, preserveCase: true).textFieldStyle(StudyTextFieldStyle())
            }
            if let exam, !exam.title.isEmpty {
                let linkedName = exam.subjectID.flatMap { store.subjectsByID[$0]?.name } ?? ""
                if exam.title.caseInsensitiveCompare(linkedName) != .orderedSame {
                    Text(L10n.tr("Titolo precedente: %@", exam.title)).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            }
            if subjectOptions.isEmpty { NoActiveSubjects(beforeOpen: { dismiss() }) }

            DatePicker(L10n.tr("Data"), selection: $date, displayedComponents: .date).interactiveHover()
            Toggle(L10n.tr("Specifica un orario"), isOn: $hasTime).interactiveHover()
            if hasTime { DatePicker(L10n.tr("Ora"), selection: $date, displayedComponents: .hourAndMinute).interactiveHover() }
            StudyTextEntry(L10n.tr("Note / aula"), text: $note, axis: .vertical).textFieldStyle(StudyTextFieldStyle()).interactiveHover(textEntry: true).lineLimit(3...5)
            if let saveError { Text(saveError).foregroundStyle(appTheme.appearance.destructiveInk) }
            HStack {
                Button(L10n.tr("Annulla")) { dismiss() }; Spacer()
                Button(L10n.tr("Salva esame")) {
                    let model = exam ?? StudyExam(title: "", date: date)
                    if exam == nil { store.context.insert(model) }
                    if exam == nil { model.title = subjectID.flatMap { store.subjectsByID[$0]?.name } ?? "" }
                    // Legacy custom titles remain stored; selecting a type opts into the subject-based display.
                    if exam == nil || exam?.examKind != nil || kind != .unspecified || subjectID != exam?.subjectID {
                        model.examKind = kind.rawValue
                        model.examKindDetail = kind == .other ? kindDetail : nil
                    }
                    model.date = hasTime ? date : Calendar.current.startOfDay(for: date)
                    model.hasTime = hasTime; model.subjectID = subjectID; model.note = note
                    if store.save() { dismiss() } else { store.context.rollback(); store.refresh(); saveError = L10n.tr("Impossibile salvare. Riprova.") }
                }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled((exam == nil && subjectID == nil) || !store.subjectChoiceIsAllowed(subjectID, retaining: exam?.subjectID))
            }
        }.padding(DesignSystem.PreservedGeometry.gap28).frame(width: DesignSystem.PreservedGeometry.points480)
        .onAppear { kind = exam?.examKind.flatMap(ExamKind.init(rawValue:)) ?? .unspecified; kindDetail = exam?.examKindDetail ?? ""; date = exam?.date ?? initialDate; hasTime = exam?.hasTime ?? false; subjectID = exam?.subjectID ?? (exam == nil ? store.activeSubjects.first?.id : nil); note = exam?.note ?? "" }
    }
}


struct CalendarSubjectShare: Identifiable {
    let id: String
    let name: String
    let color: String
    let seconds: Double
    let fraction: Double
}

extension StudyStore {
    func calendarShares(in interval: DateInterval) -> [CalendarSubjectShare] {
        calendarShares(in: [interval]).first ?? []
    }
    /// Batch the month: model reads/JSON decoding happen once per session, not once
    /// per cell. Only scalar time arithmetic repeats, and colors remain semantic IDs.
    func calendarShares(in intervals: [DateInterval]) -> [[CalendarSubjectShare]] {
        guard !intervals.isEmpty else { return [] }
        var byID: [UUID: Subject] = [:]
        for subject in subjects where byID[subject.id] == nil { byID[subject.id] = subject }
        var groups = Array(repeating: [String: (String, String, Double)](), count: intervals.count)
        for session in sessions {
            let timing = savedTiming(for: session)
            var metadata: (key: String, name: String, color: String)?
            for index in intervals.indices {
                let seconds = timing.contribution(in: intervals[index])
                guard seconds > 0, seconds.isFinite else { continue }
                if metadata == nil {
                    let subject = session.subjectID.flatMap { byID[$0] }
                    metadata = (session.subjectID?.uuidString ?? "name:" + session.subjectName,
                                subject?.name ?? session.subjectName, subject?.color ?? "Salvia")
                }
                if let item = metadata {
                    let previous = groups[index][item.key]?.2 ?? 0
                    groups[index][item.key] = (item.name, item.color, previous + seconds)
                }
            }
        }
        return groups.map { group in
            let total = group.values.reduce(0) { $0 + $1.2 }
            return group.map { key, value in CalendarSubjectShare(id: key, name: value.0, color: value.1, seconds: value.2, fraction: value.2 / total) }
                .sorted { $0.seconds == $1.seconds ? $0.id < $1.id : $0.seconds > $1.seconds }
        }
    }
}

/// The midpoint of each soft boundary is the cumulative time share.
/// Limiting the transition to the smaller adjacent share keeps short sessions visible.
func calendarPigmentStops(_ shares: [CalendarSubjectShare], theme appTheme: ResolvedTheme = ThemeRegistry.defaultPackage.resolve(mode: .light)) -> [Gradient.Stop] {
    guard let first = shares.first else { return [] }
    var stops: [Gradient.Stop] = [.init(color: appTheme.subjectColor(first.color), location: 0)]
    var boundary = 0.0
    for index in shares.indices {
        boundary += shares[index].fraction
        if index + 1 < shares.count {
            let next = shares[index + 1]
            let feather = min(shares[index].fraction, next.fraction) * DesignSystem.CalendarAppearance.boundaryFeather
            stops.append(.init(color: appTheme.subjectColor(shares[index].color), location: boundary - feather))
            stops.append(.init(color: appTheme.subjectColor(next.color), location: boundary + feather))
        }
    }
    stops.append(.init(color: appTheme.subjectColor(shares.last!.color), location: 1))
    return stops
}

private struct CalendarDayCell: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    let date: Date
    let shares: [CalendarSubjectShare]
    let examCount: Int
    let selected: Bool
    let action: () -> Void
    @State private var hovered = false
    @State private var dismissedDetails = false
    @FocusState private var focused: Bool
    private var total: Double { shares.reduce(0) { $0 + $1.seconds } }
    private var details: String {
        ([L10n.date(date, complete: true), L10n.tr("Totale: ") + durationText(total)] + shares.map { "\($0.name) · \(durationText($0.seconds)) · \(($0.fraction * 100).formatted(.number.precision(.fractionLength(0...1)).locale(L10n.locale)))%" } + [L10n.count(examCount, singular: "%@ esame", plural: "%@ esami")]).joined(separator: "\n")
    }
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    if Calendar.current.isDateInToday(date) { Circle().fill(appTheme.palette.accent).frame(width: DesignSystem.Spacing.xs, height: DesignSystem.Spacing.xs).accessibilityHidden(true) }
                    Text(date, format: .dateTime.day()).font(appTheme.preservedTypography.headline)
                }
                if total > 0 { Text(durationText(total)).font(appTheme.typography.caption).monospacedDigit() }
                if examCount > 0 { Image(systemName: "graduationcap.fill").font(appTheme.typography.caption).accessibilityHidden(true) }
            }
            .foregroundStyle(appTheme.palette.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.xxs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .frame(maxWidth: .infinity, minHeight: DesignSystem.CalendarAppearance.cellHeight)
            .background {
                if shares.isEmpty { appTheme.palette.accentSurface.opacity(DesignSystem.CalendarAppearance.neutralOpacity) }
                else {
                    Canvas { context, size in
                        let stops = calendarPigmentStops(shares, theme: appTheme)
                        let amplitude = size.width * min(DesignSystem.CalendarAppearance.waveAmplitude, (shares.map(\.fraction).min() ?? 0) * DesignSystem.CalendarAppearance.waveShareLimit)
                        for row in 0..<Int(ceil(size.height)) {
                            let y = CGFloat(row)
                            let shift = sin(y / max(1, size.height) * .pi * 2) * amplitude
                            context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: DesignSystem.PreservedGeometry.points1)), with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: shift, y: y), endPoint: CGPoint(x: size.width + shift, y: y)))
                        }
                    }.opacity(DesignSystem.CalendarAppearance.pigmentOpacity).allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(selected || focused ? appTheme.palette.accent : .clear, lineWidth: DesignSystem.Interaction.focusWidth).allowsHitTesting(false))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain).focusable().focused($focused).focusEffectDisabled()
        .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card))
        .interactiveHover(cornerRadius: DesignSystem.Radius.card)
        .onHover { hovered = $0; if !$0 { dismissedDetails = false } }
        .onChange(of: focused) { if !focused { dismissedDetails = false } }
        .onKeyPress(.escape) { dismissedDetails = true; return .handled }
        .accessibilityLabel(details).accessibilityHint(L10n.tr("Seleziona per vedere le sessioni del giorno"))
        .anchorPreference(key: CalendarDayTooltipKey.self, value: .bounds) { anchor in
            (hovered || focused) && !dismissedDetails ? CalendarDayTooltipItem(anchor: anchor, details: details) : nil
        }
    }
}

private struct CalendarDayTooltipItem {
    var anchor: Anchor<CGRect>
    var details: String
}
private struct CalendarDayTooltipKey: PreferenceKey {
    static let defaultValue: CalendarDayTooltipItem? = nil
    static func reduce(value: inout CalendarDayTooltipItem?, nextValue: () -> CalendarDayTooltipItem?) {
        if let next = nextValue() { value = next }
    }
}
/// Placement is computed against the scroll viewport, never a clipped individual cell.
enum CalendarTooltipPlacement {
    static func origin(cell: CGRect, tooltip: CGSize, bounds: CGSize, inset: CGFloat, gap: CGFloat) -> CGPoint {
        let x = min(max(inset, cell.midX - tooltip.width / 2), max(inset, bounds.width - inset - tooltip.width))
        let above = cell.minY - gap - tooltip.height
        let proposedY = above >= inset ? above : cell.maxY + gap
        let y = min(max(inset, proposedY), max(inset, bounds.height - inset - tooltip.height))
        return CGPoint(x: x, y: y)
    }
}
private struct CalendarDayTooltip: View {
    @Environment(\.studyTheme) private var appTheme
    var details: String
    var cell: CGRect
    var bounds: CGSize
    @State private var measuredHeight: CGFloat = 0
    var body: some View {
        let inset = DesignSystem.Spacing.md
        let width = min(DesignSystem.SettingsLayout.dropdownWidth, max(0, bounds.width - inset * 2))
        let origin = CalendarTooltipPlacement.origin(cell: cell, tooltip: CGSize(width: width, height: measuredHeight), bounds: bounds, inset: inset, gap: DesignSystem.Spacing.xs)
        Text(details).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textPrimary)
            .padding(inset).frame(width: width, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(appTheme.palette.elevatedSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(appTheme.palette.border))
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measuredHeight = $0 }
            .offset(x: origin.x, y: origin.y)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}
