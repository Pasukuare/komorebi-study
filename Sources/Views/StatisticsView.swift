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
        var result: [TimeBucket] = []
        while date < interval.end {
            guard let end = c.date(byAdding: bucketUnit, value: 1, to: date) else { break }
            let part = DateInterval(start: max(date, interval.start), end: min(end, interval.end))
            result.append(TimeBucket(date: date, value: store.total(in: part, subject: subjectID) / 3600)); date = end
        }
        return result
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
                            HStack { Circle().fill(share.color).frame(width: DesignSystem.PreservedGeometry.points9, height: DesignSystem.PreservedGeometry.points9); Text(share.name); Spacer(); Text(durationText(share.seconds)).monospacedDigit(); Text(String(format: "%.0f%%", share.seconds / max(1, total) * 100)).foregroundStyle(appTheme.palette.textSecondary).frame(width: DesignSystem.PreservedGeometry.points45, alignment: .trailing) }
                            StudyProgressBar(value: share.seconds, total: max(1, total), color: share.color)
                        }.padding(.vertical, DesignSystem.PreservedGeometry.gap5)
                    }
                }
                Card {
                    HStack { Text(L10n.tr("Obiettivo settimanale complessivo")).font(appTheme.preservedTypography.title3); Spacer(); GoalEditButton() }
                    LiveStudyTime { _ in
                    GoalBar(title: L10n.tr("Settimana corrente · tutte le materie"), value: store.liveWeekly, goal: store.settings.weeklyGoal * 3600)
                    Text(store.liveWeekly >= store.settings.weeklyGoal * 3600 ? L10n.tr("Obiettivo raggiunto") : L10n.tr("Mancano %@" , String(describing: durationText(store.settings.weeklyGoal * 3600 - store.liveWeekly)))).foregroundStyle(appTheme.palette.textSecondary)
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
            StudyDropdown(title: L10n.tr("Materia"), options: [(nil as UUID?, L10n.tr("Tutte le materie"))] + store.subjects.map { (Optional($0.id), $0.name) }, selection: $subjectID)
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
