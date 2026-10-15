import SwiftUI

enum Page: String, CaseIterable, Identifiable {
    case home = "Home", timer = "Timer", calendar = "Calendario", statistics = "Statistiche", history = "Cronologia", subjects = "Materie", settings = "Impostazioni"
    var id: String { rawValue }
    var icon: String {
        switch self { case .home: return "house"; case .timer: return "timer"; case .calendar: return "calendar"; case .statistics: return "chart.bar.xaxis"; case .history: return "clock.arrow.circlepath"; case .subjects: return "books.vertical"; case .settings: return "slider.horizontal.3" }
    }
}
struct RootView: View {
    @EnvironmentObject var store: StudyStore
    @State private var page: Page? = .home
    var body: some View {
        Group {
            if store.focus { FocusView() }
            else {
                NavigationSplitView {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("komorebi", systemImage: "leaf.fill").font(.system(size: 24, weight: .medium, design: .serif)).foregroundStyle(Color.sage).padding(.horizontal, 20).padding(.top, 28)
                        List(Page.allCases, selection: $page) { p in Label(p.rawValue, systemImage: p.icon).padding(.vertical, 5).tag(p) }.listStyle(.sidebar)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Il tuo studio rimane sul tuo Mac.").font(.caption).foregroundStyle(.secondary)
                        }.padding(20)
                    }.navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 260)
                } detail: {
                    Group {
                        switch page ?? .home {
                        case .home: OverviewView(openTimer: { page = .timer }, openCalendar: { page = .calendar })
                        case .timer: HomeView()
                        case .statistics: StatisticsView()
                        case .calendar: CalendarView()
                        case .history: HistoryView()
                        case .subjects: SubjectsView()
                        case .settings: SettingsView()
                        }
                    }.toolbar { ToolbarItem { Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide)).foregroundStyle(.secondary).font(.caption) } }
                }
            }
        }.tint(.sage)
        .sheet(isPresented: Binding(get: { !store.settings.onboarded }, set: { if !$0 { store.settings.onboarded = true } })) { OnboardingView() }
        .sheet(item: $store.completed) { session in CompletionView(session: session) }
        .alert("Komorebi Study", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
    }
}
struct HomeView: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) { Text("Timer").font(.system(size: 29, weight: .medium, design: .serif)); Text("Scegli una materia e una modalità di studio.").foregroundStyle(.secondary) }
                    Spacer()
                    Button { store.focus = true; NSApp.keyWindow?.toggleFullScreen(nil) } label: { Label("Focus", systemImage: "arrow.up.left.and.arrow.down.right") }
                }
                VStack(spacing: 20) {
                    if store.active == nil { TimerSetup() }
                    TimerFace()
                    HStack(spacing: 14) {
                        Button { store.toggle() } label: { Label(store.active == nil ? "Inizia a studiare" : store.active?.pausedAt != nil ? "Riprendi" : "Pausa", systemImage: store.active?.pausedAt == nil && store.active != nil ? "pause.fill" : "play.fill").frame(minWidth: 145).padding(.vertical, 6) }.buttonStyle(.borderedProminent).controlSize(.large)
                        if store.active != nil { Button("Termina") { store.finish() }.controlSize(.large) }
                    }
                    AmbientControls(audio: store.audio)
                    Text(store.active?.isBreak == true ? "Respira. La pausa parte quando sei pronto." : "Il tempo viene salvato al termine della sessione.").font(.system(.body, design: .serif)).italic().foregroundStyle(.secondary)
                }.padding(30).frame(maxWidth: .infinity).foregroundStyle(store.settings.theme == "Night" ? Color.white : Color.primary).background { Landscape(theme: store.settings.theme, animations: store.settings.animations) }.clipShape(RoundedRectangle(cornerRadius: 28))
                HStack(spacing: 16) {
                    Metric(title: "Oggi", value: durationText(store.today), icon: "sun.horizon")
                    Metric(title: "Questa settimana", value: durationText(store.weekly), icon: "calendar")
                    Metric(title: "Giorni consecutivi", value: "\(store.streak)", icon: "leaf")
                }
                Card {
                    GoalBar(title: "Il tuo obiettivo di oggi", value: store.today, goal: store.settings.dailyGoal * 3600)
                    GoalBar(title: "Studio settimanale", value: store.weekly, goal: store.settings.weeklyGoal * 3600)
                    if let a = store.active, !a.isBreak { Text("Sessione in corso: \(durationText(a.elapsed(at: store.now))). Verrà aggiunta al totale al termine.").font(.caption).foregroundStyle(.secondary) }
                }
            }.padding(30)
        }.background(Color.sage.opacity(0.035))
    }
}
struct TimerSetup: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        VStack(spacing: 12) {
            Picker("Modalità", selection: $store.settings.preferredMode) { ForEach(TimerMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).frame(maxWidth: 430)
            Picker("Materia", selection: $store.settings.lastSubject) {
                Text("Scegli materia").tag(nil as UUID?)
                ForEach(store.subjects) { Text($0.name).tag(Optional($0.id)) }
            }.frame(maxWidth: 300)
            if store.settings.preferredMode == .custom {
                HStack { Text("Durata"); TextField("Minuti", value: $store.settings.customMinutes, format: .number).frame(width: 65); Text("min · pausa"); TextField("Pausa", value: $store.settings.customBreak, format: .number).frame(width: 50); Text("min") }.frame(maxWidth: 380)
            } else if store.settings.preferredMode == .pomodoro {
                HStack {
                    ForEach([25, 50, 90], id: \.self) { value in
                        Button("\(value) / \(value == 25 ? 5 : value == 50 ? 10 : 20)") {
                            store.settings.pomodoroDuration = Double(value)
                            let shortBreak = Double(value == 25 ? 5 : value == 50 ? 10 : 20)
                            store.settings.shortBreakDuration = shortBreak
                            if store.settings.longBreakDuration < shortBreak {
                                store.settings.longBreakDuration = max(15, shortBreak + 5)
                            }
                        }.buttonStyle(.borderless)
                    }
                }
            }
        }
    }
}
struct TimerFace: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        VStack(spacing: 9) {
            Text(store.active?.subjectName ?? store.subjects.first(where: { $0.id == store.settings.lastSubject })?.name ?? store.subjects.first?.name ?? "Il tuo studio").font(.system(size: 12, weight: .semibold)).tracking(3).textCase(.uppercase)
            Text(store.active.map { clockText($0.displayed(at: store.now)) } ?? clockText(store.settings.preferredMode == .stopwatch ? 0 : (store.settings.preferredMode == .pomodoro ? store.settings.pomodoroDuration : store.settings.customMinutes) * 60))
                .font(.system(size: 88, weight: .light, design: .rounded)).monospacedDigit().contentTransition(.numericText()).minimumScaleFactor(0.5).lineLimit(1)
                .accessibilityLabel("Tempo").accessibilityValue(store.active.map { clockText($0.displayed(at: store.now)) } ?? "Pronto")
            Text(store.active?.isBreak == true ? "pausa rigenerante" : store.active?.pausedAt != nil ? "sessione in pausa" : "sessione di studio").foregroundStyle(.secondary)
            if store.active?.mode == .pomodoro { Text("Pomodoro \(store.cycles + (store.active?.isBreak == true ? 0 : 1))").font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 10)
    }
}
struct FocusView: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        ZStack {
            Landscape(theme: store.settings.theme, animations: store.settings.animations).ignoresSafeArea()
            VStack(spacing: 30) {
                HStack { Spacer(); Button("Esci da Focus", systemImage: "arrow.down.right.and.arrow.up.left") { store.focus = false; if NSApp.keyWindow?.styleMask.contains(.fullScreen) == true { NSApp.keyWindow?.toggleFullScreen(nil) } } }
                Spacer(); TimerFace().foregroundStyle(store.settings.theme == "Night" ? Color.white : Color.primary)
                Button(store.active?.pausedAt == nil && store.active != nil ? "Pausa" : "Riprendi / Avvia") { store.toggle() }.controlSize(.large)
                Spacer()
            }.padding(35)
        }
    }
}
struct CompletionView: View {
    @EnvironmentObject var store: StudyStore
    let session: StudySession
    @State private var note = ""
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill").font(.system(size: 42)).foregroundStyle(Color.sage)
            Text("Sessione salvata").font(.system(size: 28, design: .serif))
            Text("\(session.subjectName) · \(durationText(session.duration))").font(.title3)
            Text("Oggi \(durationText(store.today)) · Settimana \(durationText(store.weekly))").foregroundStyle(.secondary)
            TextField("Una nota per la prossima volta…", text: $note, axis: .vertical).lineLimit(3...5).textFieldStyle(.roundedBorder)
            Button("Continua") { session.note = note; if store.save() { store.completed = nil } }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
        }.padding(36).frame(width: 440).onAppear { note = session.note }
    }
}
struct OnboardingView: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf").font(.system(size: 52)).foregroundStyle(Color.sage)
            Text("Benvenuto in Komorebi").font(.system(size: 30, design: .serif))
            Text("Timer\nIl tuo tempo si salva automaticamente.\nCostruisci una routine sostenibile.").multilineTextAlignment(.center).lineSpacing(8)
            Text("Quanto vorresti studiare al giorno?").font(.headline)
            HStack { ForEach([2,3,4], id: \.self) { h in Button("\(h) ore") { store.settings.dailyGoal = Double(h) } } }
            HStack { Text("Obiettivo in ore"); TextField("Ore", value: $store.settings.dailyGoal, format: .number).frame(width: 70) }
            Button("Entra nel tuo spazio") {
                store.settings.dailyGoal = store.settings.dailyGoal.isFinite && store.settings.dailyGoal > 0 ? min(24, max(0.25, store.settings.dailyGoal)) : 3.0
                store.settings.onboarded = true
            }.buttonStyle(.borderedProminent).controlSize(.large)
            Text("Offline. Nessun account. Solo il tuo Mac.").font(.caption).foregroundStyle(.secondary)
        }.padding(40).frame(width: 480)
    }
}

struct OverviewView: View {
    @EnvironmentObject var store: StudyStore
    var openTimer: () -> Void
    var openCalendar: () -> Void
    var upcoming: [StudyExam] { store.exams.filter { $0.date >= store.day.start } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("KOMOREBI STUDY", systemImage: "leaf").font(.caption).tracking(2)
                    Text("Riepilogo").font(.system(size: 32, design: .serif))
                    Text("Studio, obiettivi e prossimi esami.").foregroundStyle(.secondary)
                    Button(store.active == nil ? "Vai al timer" : "Torna alla sessione", action: openTimer).buttonStyle(.borderedProminent).controlSize(.large)
                    if let active = store.active { Text("\(active.subjectName) · \(clockText(active.displayed(at: store.now))) · \(active.pausedAt == nil ? "in corso" : "in pausa")").font(.callout).monospacedDigit() }
                }.padding(28).frame(maxWidth: .infinity, alignment: .leading).background(Color.sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 26))
                HStack(spacing: 16) {
                    Metric(title: "Oggi", value: durationText(store.today), icon: "sun.horizon")
                    Metric(title: "Settimana", value: durationText(store.weekly), icon: "calendar")
                    Metric(title: "Giorni consecutivi", value: "\(store.streak)", icon: "leaf")
                }
                Card {
                    HStack { Text("I tuoi obiettivi").font(.title3); Spacer(); GoalEditButton() }
                    GoalBar(title: "Oggi", value: store.today, goal: store.settings.dailyGoal * 3600)
                    GoalBar(title: "Questa settimana", value: store.weekly, goal: store.settings.weeklyGoal * 3600)
                }
                Card {
                    HStack { Text("Prossimi esami").font(.system(size: 23, design: .serif)); Spacer(); Button("Apri calendario", action: openCalendar) }
                    if upcoming.isEmpty { Text("Nessun esame in programma. Aggiungi le date dal calendario.").foregroundStyle(.secondary) }
                    ForEach(Array(upcoming.prefix(4))) { exam in ExamRow(exam: exam) }
                }
                Card {
                    Text("Ultime sessioni").font(.title3)
                    if store.sessions.isEmpty { Text("Il tuo percorso inizia dalla prima sessione.").foregroundStyle(.secondary) }
                    ForEach(Array(store.sessions.prefix(3))) { session in SessionRow(session: session) }
                }
            }.padding(30)
        }
    }
}
