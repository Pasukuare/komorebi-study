import SwiftUI
import Charts

struct TimeBucket: Identifiable { var date: Date; var value: Double; var id: Date { date } }
enum StudyPeriod: String, CaseIterable, Identifiable {
    case week = "Settimana", month = "Mese", year = "Anno", all = "Sempre"
    var id: String { rawValue }
    var component: Calendar.Component { switch self { case .week: return .weekOfYear; case .month: return .month; case .year, .all: return .year } }
}
struct StatisticsRange {
    var period: StudyPeriod
    var anchor: Date
    var now: Date
    var firstDate: Date?
    var calendar = Calendar.current
    var interval: DateInterval {
        if period == .all {
            let start = calendar.startOfDay(for: min(firstDate ?? now, now))
            let end = (calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now)).end
            return DateInterval(start: start, end: max(start, end))
        }
        return calendar.dateInterval(of: period.component, for: anchor) ?? DateInterval(start: anchor, end: anchor)
    }
    var elapsedEnd: Date { min(now, interval.end) }
    var days: Int {
        let last = min(calendar.startOfDay(for: now), interval.end.addingTimeInterval(-1))
        return max(1, (calendar.dateComponents([.day], from: interval.start, to: last).day ?? 0) + 1)
    }
    var previousComparable: DateInterval? {
        guard period != .all else { return nil }
        guard let previousStart = calendar.date(byAdding: period.component, value: -1, to: interval.start),
              let previousFull = calendar.dateInterval(of: period.component, for: previousStart) else { return nil }
        if interval.end <= now { return previousFull }
        let elapsed = calendar.dateComponents([.day, .hour, .minute, .second], from: interval.start, to: max(interval.start, elapsedEnd))
        let end = min(previousFull.end, calendar.date(byAdding: elapsed, to: previousStart) ?? previousFull.end)
        return DateInterval(start: previousStart, end: max(previousStart, end))
    }
}
struct SubjectShare: Identifiable {
    var id: String; var name: String; var seconds: Double; var color: Color
}
struct StatisticsView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    @State private var period: StudyPeriod = .week
    @State private var anchor = Date()
    @State private var subjectID: UUID?
    var selectedSessions: [StudySession] { store.sessions.filter { subjectID == nil || $0.subjectID == subjectID } }
    var range: StatisticsRange { StatisticsRange(period: period, anchor: anchor, now: store.now, firstDate: selectedSessions.map(\.startDate).min()) }
    var interval: DateInterval { range.interval }
    var entries: [StudySession] { selectedSessions.filter { store.contribution($0, in: interval) > 0 } }
    var total: Double { store.total(in: interval, subject: subjectID) }
    var bucketUnit: Calendar.Component { period == .year || period == .all ? .month : .day }
    var buckets: [TimeBucket] {
        let c = Calendar.current
        guard var date = c.dateInterval(of: bucketUnit, for: interval.start)?.start else { return [] }
        var dates: [Date] = []
        var intervals: [DateInterval] = []
        while date < interval.end {
            guard let end = c.date(byAdding: bucketUnit, value: 1, to: date) else { break }
            dates.append(date)
            intervals.append(DateInterval(start: max(date, interval.start), end: min(end, interval.end)))
            date = end
        }
        let seconds = store.totals(in: intervals, subject: subjectID)
        return zip(dates, seconds).map { TimeBucket(date: $0.0, value: $0.1 / 3600) }
    }
    var shares: [SubjectShare] {
        Dictionary(grouping: entries, by: { $0.subjectID?.uuidString ?? "deleted:\($0.subjectName)" }).map { key, values in
            let subject = store.subjects.first { $0.id == values.first?.subjectID }
            return SubjectShare(id: key, name: subject?.name ?? values[0].subjectName, seconds: values.reduce(0) { $0 + store.contribution($1, in: interval) }, color: appTheme.subjectColor(subject?.color ?? "Salvia"))
        }.sorted { $0.seconds > $1.seconds }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack { Text(L10n.tr("Statistiche")).font(appTheme.preservedTypography.pageTitle); Spacer(); Button(L10n.tr("Esporta CSV")) { store.export(csv: true) } }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.xl) {
                        periodFilter.frame(width: DesignSystem.PreservedGeometry.points380)
                        Spacer(minLength: DesignSystem.Spacing.sm)
                        subjectFilter.frame(width: DesignSystem.PreservedGeometry.points230)
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy14) {
                        periodFilter
                        subjectFilter.frame(maxWidth: DesignSystem.PreservedGeometry.points300)
                    }
                }
                HStack {
                    if period != .all {
                        Button { move(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel(L10n.tr("Periodo precedente"))
                        Button(L10n.tr("Periodo attuale")) { anchor = store.now }
                        Button { move(1) } label: { Image(systemName: "chevron.right") }.disabled(interval.end > store.now).accessibilityLabel(L10n.tr("Periodo successivo"))
                    }
                    Spacer()
                    Text("\(L10n.date(interval.start)) – \(L10n.date(min(store.now, interval.end.addingTimeInterval(-1))))").foregroundStyle(appTheme.palette.textSecondary)
                }
                ViewThatFits(in: .horizontal) {
                    EqualHeightCardRow(spacing: DesignSystem.Spacing.md) { keyMetrics }
                    VStack(spacing: DesignSystem.Spacing.md) { keyMetrics }
                }
                LiveStudyTime(updatesWhenIdle: true) { date in
                    let range = StatisticsRange(period: period, anchor: anchor, now: date, firstDate: selectedSessions.map(\.startDate).min())
                    let total = self.total
                if let previousRange = range.previousComparable {
                    let previous = store.total(in: previousRange, subject: subjectID)
                    HStack(alignment: .center, spacing: DesignSystem.Spacing.legacy14) {
                        Image(systemName: total >= previous ? "arrow.up.right" : "arrow.down.right")
                            .font(appTheme.preservedTypography.comparisonSymbol).foregroundStyle(appTheme.palette.accent)
                            .frame(width: DesignSystem.PreservedGeometry.points40, height: DesignSystem.PreservedGeometry.points40).background(appTheme.palette.accent.opacity(appTheme.appearance.opacity0_09), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
                        VStack(alignment: .leading, spacing: DesignSystem.PreservedGeometry.gap5) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                if previous > 0 {
                                    Text(String(format: "%+.0f%%", (total - previous) / previous * 100)).font(appTheme.preservedTypography.headline).monospacedDigit()
                                }
                                Text(total == previous ? L10n.tr("Nessuna variazione") : previous == 0 ? L10n.tr("Nessun dato nel periodo precedente") : durationText(abs(total - previous)) + (total > previous ? L10n.tr(" in più") : L10n.tr(" in meno")))
                                    .font(appTheme.preservedTypography.callout)
                            }
                            Text(interval.end > store.now ? L10n.tr("Confronto con lo stesso intervallo del periodo precedente: ") + durationText(previous) : L10n.tr("Periodo precedente completo: ") + durationText(previous))
                                .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }.padding(.vertical, DesignSystem.Spacing.xxs)
                }
                }
                if !store.units.isEmpty {
                    Card(hoverEnabled:false) {
                        Text(L10n.tr("Avanzamento per unità")).font(appTheme.typography.heading)
                        Text(L10n.tr("Totali di tutte le unità; media sulle unità finite con tempo registrato.")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        ForEach(store.subjects.filter { (subjectID == nil || subjectID == $0.id) && store.unitSummaries[$0.id] != nil }) { subject in
                            if let summary = store.unitSummaries[subject.id] {
                                VStack(alignment:.leading,spacing:DesignSystem.Spacing.xs) {
                                    Text(verbatim:subject.name).font(appTheme.typography.small)
                                    Text(L10n.tr("%@ di %@ unità finite",String(summary.finished),String(summary.total))).font(appTheme.typography.caption)
                                    if let average=summary.averageMinutes { Text(L10n.tr("Tempo medio per unità: %@",durationText(average*60))).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary) }
                                }
                            }
                        }
                    }
                }
                Card {
                    HStack { Text(bucketUnit == .month ? L10n.tr("Ore per mese") : L10n.tr("Ore per giorno")).font(appTheme.preservedTypography.title3); Spacer(); Text(L10n.tr("Passa sulle barre o selezionale per i dettagli")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary) }
                    if entries.isEmpty {
                        StudyEmptyState(symbol: "chart.xyaxis.line", title: L10n.tr("Nessuna statistica"), detail: store.sessions.isEmpty ? L10n.tr("Le statistiche saranno disponibili dopo la prima sessione salvata.") : L10n.tr("Qui non ci sono sessioni. Prova un altro periodo."), actionTitle: store.sessions.isEmpty ? L10n.tr("Inizia a studiare") : L10n.tr("Mostra tutto")) {
                            if store.sessions.isEmpty { store.openTimer = true } else { subjectID = nil; period = .all; anchor = store.now }
                        }
                    }
                    else {
                        StatisticsStudyChart(buckets: buckets, bucketUnit: bucketUnit, chartColor: chartColor)
                            .id(StatisticsChartIdentity(period: period, anchor: anchor, subjectID: subjectID))
                    }
                    Text(L10n.tr("Media calcolata su %@ giorni, inclusi quelli senza studio. Solo sessioni salvate." , String(describing: range.days))).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                Card {
                    Text(L10n.tr("Studio per materia")).font(appTheme.preservedTypography.title3)
                    if shares.isEmpty { Text(L10n.tr("Nessun dato per materia nel periodo selezionato.")).foregroundStyle(appTheme.palette.textSecondary) }
                    ForEach(shares) { share in
                        VStack(spacing: DesignSystem.Spacing.legacy6) {
                            HStack { Circle().fill(share.color).frame(width: DesignSystem.PreservedGeometry.points9, height: DesignSystem.PreservedGeometry.points9); Text(verbatim: share.name).textCase(nil); Spacer(); Text(durationText(share.seconds)).monospacedDigit(); Text(String(format: "%.0f%%", share.seconds / max(1, total) * 100)).foregroundStyle(appTheme.palette.textSecondary).frame(width: DesignSystem.PreservedGeometry.points45, alignment: .trailing) }
                            StudyProgressBar(value: share.seconds, total: max(1, total), color: share.color)
                        }.padding(.vertical, DesignSystem.PreservedGeometry.gap5)
                    }
                }
                Card {
                    HStack { Text(L10n.tr("Obiettivo settimanale complessivo")).font(appTheme.preservedTypography.title3); Spacer(); GoalEditButton() }
                    LiveStudyTime { _ in
                    GoalBar(title: L10n.tr("Settimana corrente · tutte le materie"), value: store.weeklyGoalProgress, goal: store.settings.weeklyGoal * 3600)
                    Text(store.weeklyGoalProgress >= store.settings.weeklyGoal * 3600 ? L10n.tr("Obiettivo raggiunto") : L10n.tr("Mancano %@" , String(describing: durationText(store.settings.weeklyGoal * 3600 - store.weeklyGoalProgress)))).foregroundStyle(appTheme.palette.textSecondary)
                    }
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }.background(appTheme.palette.background)
        .animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: period)
        .animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: anchor)
        .animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: subjectID)
    }
    @ViewBuilder var keyMetrics: some View {
        Metric(title: L10n.tr("Tempo studiato"), value: durationText(total), icon: "clock")
        Metric(title: L10n.tr("Serie attuale · giorni"), value: "\(store.streak)", icon: "leaf")
        Metric(title: L10n.tr("Materia più studiata"), value: shares.first?.name ?? L10n.tr("Nessun dato"), icon: "book")
    }
    var chartColor: Color { store.subjects.first { $0.id == subjectID }.map { appTheme.subjectColor($0.color) } ?? appTheme.palette.accent }
    var periodFilter: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
            Text(L10n.tr("Periodo")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
            PastelSegmentedControl(L10n.tr("Periodo"), values: StudyPeriod.allCases, selection: $period) { L10n.tr($0.rawValue) }
        }
    }
    var subjectFilter: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
            Text(L10n.tr("Materia")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
            StudyDropdown(title: L10n.tr("Materia"), options: [(nil as UUID?, L10n.tr("Tutte le materie"))] + store.consultationSubjectChoices, selection: $subjectID, sectionLabels: store.completedSubjects.first.map { [Optional($0.id): L10n.tr("Completate")] } ?? [:])
        }
    }
    func move(_ direction: Int) {
        if let next = Calendar.current.date(byAdding: period.component, value: direction, to: interval.start) {
            anchor = next
        }
    }
}

// Cursor positions are resolved to stable bucket IDs before publishing state.
// This view owns selection so hover cannot invalidate StatisticsView's aggregates.
struct StatisticsChartIdentity: Hashable {
    let period: StudyPeriod
    let anchor: Date
    let subjectID: UUID?
}
enum StatisticsChartSelection {
    static func bucketDate(for date: Date?, buckets: [TimeBucket], unit: Calendar.Component, calendar: Calendar = .current) -> Date? {
        guard let date else { return nil }
        return buckets.first { calendar.isDate($0.date, equalTo: date, toGranularity: unit) }?.date
    }
}
struct StatisticsStudyChart: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    let buckets: [TimeBucket]
    let bucketUnit: Calendar.Component
    let chartColor: Color
    @State private var chartRevealed = false
    @State private var selectedDate: Date?
    func select(_ date: Date?) {
        let next = StatisticsChartSelection.bucketDate(for: date, buckets: buckets, unit: bucketUnit)
        if next != selectedDate { selectedDate = next }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            studyChart
            if let bucket = selectedBucket {
                Text("\(L10n.date(bucket.date)) · \(durationText(bucket.value * 3600))")
                    .font(appTheme.preservedTypography.callout).monospacedDigit()
            } else {
                Text(L10n.tr("Passa su una barra per vedere il tempo studiato."))
                    .font(appTheme.preservedTypography.callout).foregroundStyle(appTheme.palette.textSecondary)
            }
        }
        .onChange(of: sectionVisible) { if !sectionVisible { select(nil) } }
        .onChange(of: buckets.map(\.id)) { select(selectedDate) }
    }
    var selectedBucket: TimeBucket? {
        guard let selectedDate else { return nil }
        return buckets.first { Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: bucketUnit) }
    }
    func midpoint(_ bucket: TimeBucket) -> Date {
        let end = Calendar.current.date(byAdding: bucketUnit, value: 1, to: bucket.date) ?? bucket.date
        return bucket.date.addingTimeInterval(end.timeIntervalSince(bucket.date) / 2)
    }
    var studyChart: some View {
        Chart {
            ForEach(buckets) { bucket in
                BarMark(x: .value(L10n.tr("Data"), bucket.date, unit: bucketUnit), y: .value(L10n.tr("Ore"), chartRevealed ? bucket.value : 0))
                    .foregroundStyle(LinearGradient(colors: [chartColor.opacity(appTheme.appearance.opacity0_55), chartColor], startPoint: .top, endPoint: .bottom)).cornerRadius(DesignSystem.Spacing.xxs)
                    .accessibilityLabel(L10n.date(bucket.date))
                    .accessibilityValue(durationText(bucket.value * 3600))
                    .opacity(selectedDate.map { Calendar.current.isDate(bucket.date, equalTo: $0, toGranularity: bucketUnit) } ?? true ? 1 : appTheme.appearance.opacity0_4)
            }
            if let bucket = selectedBucket {
                RuleMark(x: .value(L10n.tr("Selezione"), midpoint(bucket)))
                    .lineStyle(StrokeStyle(lineWidth: DesignSystem.PreservedGeometry.stroke1, dash: appTheme.motion.ruleDash)).foregroundStyle(chartColor.opacity(appTheme.appearance.opacity0_4))
                PointMark(x: .value(L10n.tr("Data selezionata"), midpoint(bucket)), y: .value(L10n.tr("Ore selezionate"), bucket.value))
                    .symbolSize(0)
                    .annotation(position: .top, spacing: DesignSystem.Spacing.xs, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text(bucket.date, format: bucketUnit == .month ? .dateTime.month(.wide).year() : .dateTime.day().month(.wide))
                                .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                            Text(durationText(bucket.value * 3600)).font(appTheme.preservedTypography.chartTooltipValue).monospacedDigit()
                        }.padding(DesignSystem.Spacing.sm).background(appTheme.palette.elevatedSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.PreservedGeometry.radius10).stroke(chartColor.opacity(appTheme.appearance.opacity0_15)).allowsHitTesting(false))
                    }
            }
        }
        .chartYScale(domain: 0...max(1, (buckets.map(\.value).max() ?? 0) * appTheme.motion.chartHeadroom))
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(appTheme.palette.border.opacity(appTheme.appearance.opacity0_12))
                AxisValueLabel().foregroundStyle(appTheme.palette.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(appTheme.palette.border.opacity(appTheme.appearance.opacity0_08))
                AxisValueLabel().foregroundStyle(appTheme.palette.textSecondary)
            }
        }
        .chartYAxisLabel(L10n.tr("Ore"))
        .chartXSelection(value: Binding(get: { selectedDate }, set: { select($0) }))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onTapGesture { location in
                        guard sectionVisible else { return }
                        guard let plotFrame = proxy.plotFrame else { return }
                        let frame = geometry[plotFrame]
                        select(frame.contains(location) ? proxy.value(atX: location.x - frame.minX, as: Date.self) : nil)
                    }
                    .onContinuousHover { phase in
                        guard sectionVisible else { select(nil); return }
                        switch phase {
                        case .active(let location):
                            guard let plotFrame = proxy.plotFrame else { return }
                            let frame = geometry[plotFrame]
                            select(frame.contains(location) ? proxy.value(atX: location.x - frame.minX, as: Date.self) : nil)
                        case .ended: select(nil)
                        }
                    }
            }
        }
        .frame(height: DesignSystem.PreservedGeometry.points260)
        .animation(motion == "Off" || reduceMotion ? nil : .easeOut(duration: DesignSystem.Interaction.hoverDuration), value: selectedBucket?.id)
        .task(id: sectionVisible) {
            guard sectionVisible else { chartRevealed = false; return }
            withAnimation(motion == "Off" || reduceMotion ? nil : .easeOut(duration: DesignSystem.Interaction.chartDuration)) { chartRevealed = true }
        }
    }
}


struct ProjectionCard: View {
    @ObservedObject private var language = AppLocalization.shared
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    var openCalendar: () -> Void
    @State private var selectedID: UUID?
    @State private var editing = false
    init(openCalendar: @escaping () -> Void, initialExamID: UUID? = nil) {
        self.openCalendar = openCalendar; _selectedID = State(initialValue: initialExamID)
    }
    private var exam: StudyExam? { store.projectionExams.first { $0.id == selectedID } ?? store.projectionExams.first }
    var body: some View {
        // Static card chrome: moving over the chart never repaints a card-sized spotlight.
        Card(hoverEnabled: false) {
            HStack {
                Text(L10n.tr("Proiezione")).font(theme.typography.heading)
                Spacer()
                if let exam, store.projections[exam.id] != nil {
                    Button { editing.toggle() } label: { Image(systemName: "pencil") }
                        .help(L10n.tr("Modifica ore necessarie")).accessibilityLabel(L10n.tr("Modifica ore necessarie"))
                }
            }
            if let exam {
                if store.projectionExams.count > 1 {
                    StudyDropdown(title: L10n.tr("Esame"), options: store.projectionExams.map { (Optional($0.id), store.examDisplayTitle($0)) },
                        selection: Binding(get: { self.exam?.id }, set: { selectedID = $0; editing = false }))
                } else {
                    Text(verbatim: store.examDisplayTitle(exam)).font(theme.typography.small).foregroundStyle(theme.palette.textSecondary)
                }
                if let id=exam.subjectID, let summary=store.unitSummaries[id], let minutes=summary.remainingMinutes {
                    Text(L10n.tr("Mancano %@ unità, circa %@ ore",String(summary.remaining),ProjectionText.number(minutes/60))).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                }
                if editing || store.projections[exam.id] == nil {
                    ProjectionTargetEditor(exam: exam, cancel: store.projections[exam.id] == nil ? nil : { editing = false }, saved: { editing = false }).id(exam.id)
                } else if let result = store.projections[exam.id] {
                    ProjectionSummary(result: result, dailyGoal: store.settings.dailyGoal)
                    ProjectionChart(result: result)
                }
            } else {
                Text(L10n.tr("Aggiungi un esame per vedere la proiezione")).foregroundStyle(theme.palette.textSecondary)
                Button(L10n.tr("Apri Calendario"), action: openCalendar)
            }
        }
        .onChange(of: store.projectionExams.map(\.id)) {
            if let selectedID, !store.projectionExams.contains(where: { $0.id == selectedID }) { self.selectedID = nil; editing = false }
        }
    }
}

struct ProjectionTargetEditor: View {
    @ObservedObject private var language = AppLocalization.shared
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    let exam: StudyExam
    var cancel: (() -> Void)?
    let saved: () -> Void
    @State private var hoursText: String
    @State private var start: Date
    @State private var failed = false
    init(exam: StudyExam, cancel: (() -> Void)? = nil, saved: @escaping () -> Void) {
        self.exam = exam; self.cancel = cancel; self.saved = saved
        _hoursText = State(initialValue: exam.requiredStudyHours.map { String($0).replacingOccurrences(of: ".", with: L10n.locale.decimalSeparator ?? ".") } ?? "")
        _start = State(initialValue: exam.preparationStart ?? Calendar.current.startOfDay(for: Date()))
    }
    private var hours: Double? { ProjectionTargetInput.hours(hoursText) }
    private var latestStart: Date {
        let calendar = Calendar.current
        let examDay = calendar.startOfDay(for: exam.date)
        return max(calendar.startOfDay(for: store.now), calendar.date(byAdding: .day, value: -1, to: examDay)!)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            let name = exam.subjectID.flatMap { store.subjectsByID[$0]?.name } ?? exam.title
            Text(L10n.tr("Quante ore ti servono per arrivare pronto a %@?", name)).font(theme.typography.heading)
            StudyTextEntry(L10n.tr("Ore necessarie"), text: $hoursText).textFieldStyle(StudyTextFieldStyle())
            DatePicker(L10n.tr("Data di inizio preparazione"), selection: $start, in: ...latestStart, displayedComponents: .date)
            if !hoursText.isEmpty && hours == nil {
                Text(L10n.tr("Inserisci un numero di ore maggiore di zero")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            }
            if failed { Text(L10n.tr("Impossibile salvare. Riprova.")).foregroundStyle(theme.appearance.destructiveInk) }
            HStack {
                if let cancel { Button(L10n.tr("Annulla"), action: cancel) }
                Button(L10n.tr("Imposta")) {
                    guard let hours, start <= latestStart else { return }
                    let oldHours = exam.requiredStudyHours, oldStart = exam.preparationStart
                    exam.requiredStudyHours = hours; exam.preparationStart = Calendar.current.startOfDay(for: start)
                    if store.save() { saved() }
                    else { exam.requiredStudyHours = oldHours; exam.preparationStart = oldStart; failed = true }
                }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(hours == nil || start > latestStart)
            }
        }
    }
}

enum ProjectionText {
    static func number(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...1)).locale(L10n.locale)) }
    static func rate(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(1)).locale(L10n.locale)) }
    static func headline(_ r: StudyProjection) -> String {
        if r.isScheduled { return L10n.tr("Preparazione dal %@", r.preparationStart.formatted(.dateTime.day().month(.wide).year().locale(L10n.locale))) }
        switch r.status {
        case .reached: return L10n.tr("Obiettivo ore raggiunto: %@ h su %@ h", number(r.doneHours), number(r.requiredHours))
        case .onTrack: return L10n.tr("Sei in linea: arrivi con %@ h su %@ h", number(r.finalHours), number(r.requiredHours))
        case .examToday: return L10n.tr("Esame oggi: %@ h su %@ h", number(r.doneHours), number(r.requiredHours))
        default: return L10n.tr("A questo ritmo arrivi all’esame con %@ h su %@ h", number(r.finalHours), number(r.requiredHours))
        }
    }
    static func detail(_ r: StudyProjection, dailyGoal: Double) -> String {
        if r.isScheduled, let needed = r.necessaryPace {
            return L10n.tr("Servono %@ h al giorno dalla data di inizio. Il ritmo sarà calcolato dopo l’inizio della preparazione.", rate(needed))
        }
        guard let needed = r.necessaryPace else { return L10n.tr("L’esame è oggi: restano %@ h e nessun altro giorno di preparazione", number(max(0,r.requiredHours-r.doneHours))) }
        if r.status == .reached { return L10n.tr("Ore necessarie già raggiunte") }
        if needed > dailyGoal { return L10n.tr("Il tuo obiettivo di %@ h al giorno non basta: ne servono %@", number(dailyGoal), rate(needed)) }
        if needed > 12 { return L10n.tr("Servono %@ h al giorno, oltre 12 h di studio", rate(needed)) }
        return L10n.tr("Servono %@ h al giorno da oggi (ora ne fai %@)", rate(needed), rate(r.currentPace))
    }
}
struct ProjectionSummary: View {
    @ObservedObject private var language = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    let result: StudyProjection
    let dailyGoal: Double
    private var positive: Bool { result.status == .reached || result.status == .onTrack }
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(ProjectionText.headline(result)).font(theme.typography.title).fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                metric(L10n.tr("Fatte"), value: ProjectionText.number(result.doneHours) + " h")
                metric(L10n.tr("A questo ritmo"), value: ProjectionText.number(result.finalHours) + " h")
                metric(L10n.tr("Servono"), value: result.necessaryPace.map { ProjectionText.rate($0) + L10n.tr(" h/giorno") } ?? "—")
            }
            Text(status).font(theme.typography.small).foregroundStyle(positive ? theme.subjectColor(SubjectColorID.defaultID) : theme.appearance.amberInk)
            Text(ProjectionText.detail(result, dailyGoal: dailyGoal)).foregroundStyle(theme.palette.textSecondary).fixedSize(horizontal: false, vertical: true)
            Text(L10n.tr("Solo sessioni salvate. La sessione in corso non è inclusa.")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
        }
    }
    private var status: String {
        if result.isScheduled { return L10n.tr("Preparazione programmata") }
        switch result.status {
        case .reached: return L10n.tr("Obiettivo raggiunto")
        case .onTrack: return L10n.tr("In linea")
        case .unsustainable: return L10n.tr("Ritmo non sostenibile")
        case .examToday: return L10n.tr("Esame oggi")
        case .past: return L10n.tr("Esame passato")
        case .behind: return L10n.tr("Indietro di %@ h sulla proiezione", ProjectionText.number(result.shortfall))
        }
    }
    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            Text(value).font(theme.typography.heading).monospacedDigit().lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}


/// Selection is local and quantized to a calendar day. It never invalidates store aggregates.
struct ProjectionChart: View {
    @ObservedObject private var language = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiSectionVisible) private var visible
    let result: StudyProjection
    @State private var selected: Date?
    @State private var entered = false
    init(result: StudyProjection, initialSelection: Date? = nil) {
        self.result = result; _selected = State(initialValue: initialSelection)
    }
    private var actualColor: Color { theme.subjectColor(SubjectColorID.defaultID) }
    private var forecastColor: Color { result.status == .reached || result.status == .onTrack ? actualColor : theme.appearance.amberInk }
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if result.studiedDays < 2 {
                Text(L10n.tr("Servono almeno 2 giorni di studio per una proiezione affidabile"))
                    .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            }
            if result.examDate > result.asOf && result.examDate > result.preparationStart {
                chart
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DesignSystem.Spacing.md) { legend }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) { legend }
                }.font(theme.typography.caption)
            } else {
                Text(L10n.tr("L’esame è oggi: non ci sono altri giorni di preparazione."))
                    .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            }
        }
        .onAppear {
            withAnimation(reduceMotion || motion == "Off" ? nil : .easeOut(duration: DesignSystem.ProjectionLayout.entryDuration)) { entered = true }
        }
        .onChange(of: result) { selected = nil }
        .onChange(of: visible) { if !visible { selected = nil } }
    }
    private var chart: some View {
        Chart {
            if result.studiedDays >= 2 {
                ForEach(result.actualPoints) { point in
                    LineMark(x: .value(L10n.tr("Data"), point.date), y: .value(L10n.tr("Ore"), point.hours), series: .value("series", "actual"))
                        .foregroundStyle(actualColor).lineStyle(StrokeStyle(lineWidth: DesignSystem.ProjectionLayout.stroke))
                }
            }
            ForEach([ProjectionPoint(date: result.forecastStart, hours: result.doneHours), ProjectionPoint(date: result.examDate, hours: result.finalHours)]) { point in
                LineMark(x: .value(L10n.tr("Data"), point.date), y: .value(L10n.tr("Ore"), point.hours), series: .value("series", "forecast"))
                    .foregroundStyle(forecastColor).lineStyle(StrokeStyle(lineWidth: DesignSystem.ProjectionLayout.stroke, dash: DesignSystem.ProjectionLayout.dash))
            }
            ForEach([ProjectionPoint(date: result.preparationStart, hours: 0), ProjectionPoint(date: result.examDate, hours: result.requiredHours)]) { point in
                LineMark(x: .value(L10n.tr("Data"), point.date), y: .value(L10n.tr("Ore"), point.hours), series: .value("series", "plan"))
                    .foregroundStyle(theme.palette.textTertiary).lineStyle(StrokeStyle(lineWidth: DesignSystem.ProjectionLayout.planStroke))
            }
            PointMark(x: .value(L10n.tr("Data"), result.examDate), y: .value(L10n.tr("Ore"), result.finalHours))
                .foregroundStyle(forecastColor).symbolSize(DesignSystem.ProjectionLayout.symbolSize)
                .annotation(position: .bottom, alignment: .trailing) {
                    Text(ProjectionText.number(result.finalHours) + " h").font(theme.typography.caption).foregroundStyle(theme.palette.textPrimary)
                }
            PointMark(x: .value(L10n.tr("Data"), result.examDate), y: .value(L10n.tr("Ore"), result.requiredHours))
                .foregroundStyle(theme.palette.textTertiary).symbolSize(DesignSystem.ProjectionLayout.symbolSize)
                .annotation(position: .top, alignment: .trailing) {
                    Text(ProjectionText.number(result.requiredHours) + " h").font(theme.typography.caption).foregroundStyle(theme.palette.textPrimary)
                }
            if !result.isScheduled {
            RuleMark(x: .value(L10n.tr("Data"), result.asOf))
                .foregroundStyle(theme.palette.textSecondary.opacity(theme.appearance.opacity0_35))
                .lineStyle(StrokeStyle(lineWidth: DesignSystem.ProjectionLayout.planStroke, dash: DesignSystem.ProjectionLayout.todayDash))
                .annotation(position: .top) { Text(L10n.tr("Oggi")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary) }
            }
            if let selected {
                RuleMark(x: .value(L10n.tr("Data"), selected)).foregroundStyle(theme.palette.border)
            }
        }
        .chartXScale(domain: result.preparationStart...result.examDate)
        .chartYAxisLabel(L10n.tr("Ore"))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: DesignSystem.ProjectionLayout.axisTicks)) { value in
                AxisValueLabel { if let date = value.as(Date.self) { Text(date.formatted(.dateTime.day().month(.abbreviated).locale(L10n.locale))).foregroundStyle(theme.palette.textSecondary) } }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: DesignSystem.ProjectionLayout.axisTicks)) {
                AxisGridLine().foregroundStyle(theme.palette.border.opacity(theme.appearance.opacity0_13))
                AxisValueLabel().foregroundStyle(theme.palette.textSecondary)
            }
        }
        .chartLegend(.hidden)
        .chartXSelection(value: Binding(get: { selected }, set: { select($0) }))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        guard visible else { select(nil); return }
                        switch phase {
                        case .active(let point):
                            guard let plot = proxy.plotFrame else { return }
                            let frame = geometry[plot]
                            select(frame.contains(point) ? proxy.value(atX: point.x-frame.minX, as: Date.self) : nil)
                        case .ended: select(nil)
                        }
                    }
            }
        }
        .overlay(alignment: .topLeading) {
            if let date = selected {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(L10n.date(date)).font(theme.typography.small)
                    Text(L10n.tr("%@ h · %@", ProjectionText.number(hours(at: date)), date <= result.asOf ? L10n.tr("Fatte") : L10n.tr("Proiezione")))
                    Text(L10n.tr("Piano: %@ h", ProjectionText.number(plan(at: date))))
                }.font(theme.typography.caption).foregroundStyle(theme.palette.textPrimary)
                    .padding(DesignSystem.Spacing.sm).background(theme.palette.elevatedSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.control).stroke(theme.palette.border))
                    .allowsHitTesting(false)
            }
        }
        .frame(height: DesignSystem.ProjectionLayout.chartHeight)
        .opacity(entered ? 1 : 0)
        .focusable().focusEffectDisabled().modifier(KeyboardFocusBorder())
        .onMoveCommand { direction in
            if direction == .left || direction == .right {
                select(Calendar.current.date(byAdding: .day, value: direction == .left ? -1 : 1, to: selected ?? result.asOf))
            }
        }
        .accessibilityLabel(L10n.tr("Proiezione delle ore di studio"))
        .accessibilityValue(ProjectionText.headline(result))
        .accessibilityAdjustableAction { direction in
            select(Calendar.current.date(byAdding: .day, value: direction == .increment ? 1 : -1, to: selected ?? result.asOf))
        }
    }
    private func select(_ date: Date?) {
        let next = date.map { min(result.examDate, max(result.preparationStart, Calendar.current.startOfDay(for: $0))) }
        if selected != next { selected = next }
    }
    private func hours(at date: Date) -> Double {
        if date <= result.asOf { return result.actualPoints.last(where: { $0.date <= date })?.hours ?? 0 }
        return result.doneHours + result.currentPace * Double(ExamCalendarDays.remaining(until: date, from: result.forecastStart))
    }
    private func plan(at date: Date) -> Double {
        let total = max(1, ExamCalendarDays.remaining(until: result.examDate, from: result.preparationStart))
        let elapsed = max(0, ExamCalendarDays.remaining(until: date, from: result.preparationStart))
        return result.requiredHours * min(1, Double(elapsed)/Double(total))
    }
    @ViewBuilder private var legend: some View {
        if result.studiedDays >= 2 { Label(L10n.tr("Fatte"), systemImage: "line.diagonal").foregroundStyle(actualColor) }
        Label(L10n.tr("Proiezione tratteggiata"), systemImage: "line.diagonal").foregroundStyle(forecastColor)
        Label(L10n.tr("Piano"), systemImage: "line.diagonal").foregroundStyle(theme.palette.textSecondary)
    }
}
