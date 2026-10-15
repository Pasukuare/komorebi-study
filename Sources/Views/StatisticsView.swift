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
    @EnvironmentObject var store: StudyStore
    @State private var period: StudyPeriod = .week
    @State private var anchor = Date()
    @State private var subjectID: UUID?
    @State private var selectedDate: Date?
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
            return SubjectShare(id: key, name: subject?.name ?? values[0].subjectName, seconds: values.reduce(0) { $0 + store.contribution($1, in: interval) }, color: .subject(subject?.color ?? "Salvia"))
        }.sorted { $0.seconds > $1.seconds }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack { Text("Statistiche").font(.system(size: 30, design: .serif)); Spacer(); Button("Esporta archivio CSV") { store.export(csv: true) } }
                HStack {
                    Picker("Periodo", selection: $period) { ForEach(StudyPeriod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).frame(maxWidth: 380)
                    Spacer()
                    Picker("Materia", selection: $subjectID) { Text("Tutte le materie").tag(nil as UUID?); ForEach(store.subjects) { Text($0.name).tag(Optional($0.id)) } }.frame(maxWidth: 240)
                }
                HStack {
                    if period != .all {
                        Button { move(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Periodo precedente")
                        Button("Periodo attuale") { anchor = store.now }
                        Button { move(1) } label: { Image(systemName: "chevron.right") }.disabled(interval.end > store.now).accessibilityLabel("Periodo successivo")
                    }
                    Spacer()
                    Text("\(interval.start.formatted(date: .abbreviated, time: .omitted)) – \(min(store.now, interval.end.addingTimeInterval(-1)).formatted(date: .abbreviated, time: .omitted))").foregroundStyle(.secondary)
                }
                HStack(spacing: 14) {
                    Metric(title: "Tempo studiato", value: durationText(total), icon: "clock")
                    Metric(title: "Sessioni", value: "\(entries.count)", icon: "square.stack")
                    Metric(title: "Media giornaliera", value: durationText(total / Double(range.days)), icon: "chart.bar")
                }
                if let previousRange = range.previousComparable {
                    let previous = store.total(in: previousRange, subject: subjectID)
                    HStack {
                        Image(systemName: total >= previous ? "arrow.up.right" : "arrow.down.right").foregroundStyle(Color.sage)
                        if previous > 0 { Text(String(format: "%+.0f%%", (total - previous) / previous * 100)).font(.headline) }
                        else { Text(previous == 0 && total == 0 ? "Nessuna variazione" : "Nessuno studio nel periodo precedente") }
                        Text(interval.end > store.now ? "Rispetto allo stesso intervallo del periodo precedente" : "Rispetto al periodo precedente completo").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Card {
                    HStack { Text(bucketUnit == .month ? "Ore per mese" : "Ore per giorno").font(.title3); Spacer(); Text("Seleziona una barra per il dettaglio").font(.caption).foregroundStyle(.secondary) }
                    if entries.isEmpty { ContentUnavailableView("Nessuna sessione nel periodo", systemImage: "chart.bar", description: Text("Cambia periodo o materia per consultare il tuo archivio.")).frame(height: 180) }
                    else {
                        Chart(buckets) { bucket in
                            BarMark(x: .value("Data", bucket.date, unit: bucketUnit), y: .value("Ore", bucket.value)).foregroundStyle(Color.sage.gradient).cornerRadius(4)
                        }.chartYScale(domain: 0...max(1, (buckets.map(\.value).max() ?? 0) * 1.12)).chartYAxisLabel("Ore").chartXSelection(value: $selectedDate).frame(height: 240)
                        if let date = selectedDate, let bucket = buckets.first(where: { Calendar.current.isDate($0.date, equalTo: date, toGranularity: bucketUnit) }) {
                            Text("\(bucket.date.formatted(.dateTime.day().month().year())) · \(durationText(bucket.value * 3600))").font(.callout).monospacedDigit()
                        }
                    }
                    Text("Media calcolata su \(range.days) giorni, inclusi quelli senza studio. Solo sessioni salvate.").font(.caption).foregroundStyle(.secondary)
                }
                Card {
                    Text("Studio per materia").font(.title3)
                    if shares.isEmpty { Text("Nessun dato disponibile.").foregroundStyle(.secondary) }
                    ForEach(shares) { share in
                        VStack(spacing: 6) {
                            HStack { Circle().fill(share.color).frame(width: 9, height: 9); Text(share.name); Spacer(); Text(durationText(share.seconds)).monospacedDigit(); Text(String(format: "%.0f%%", share.seconds / max(1, total) * 100)).foregroundStyle(.secondary).frame(width: 45, alignment: .trailing) }
                            ProgressView(value: share.seconds, total: max(1, total)).tint(share.color)
                        }.padding(.vertical, 5)
                    }
                }
                Card {
                    HStack { Text("Obiettivo settimanale complessivo").font(.title3); Spacer(); GoalEditButton() }
                    GoalBar(title: "Settimana corrente · tutte le materie", value: store.weekly, goal: store.settings.weeklyGoal * 3600)
                    Text(store.weekly >= store.settings.weeklyGoal * 3600 ? "Obiettivo raggiunto" : "Mancano \(durationText(store.settings.weeklyGoal * 3600 - store.weekly))").foregroundStyle(.secondary)
                }
            }.padding(30)
        }.onChange(of: period) { selectedDate = nil }.onChange(of: anchor) { selectedDate = nil }.onChange(of: subjectID) { selectedDate = nil }
    }
    func move(_ direction: Int) {
        if let next = Calendar.current.date(byAdding: period.component, value: direction, to: interval.start) {
            anchor = next
        }
    }
}
