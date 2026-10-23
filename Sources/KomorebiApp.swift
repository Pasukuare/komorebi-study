import SwiftUI
import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { UNUserNotificationCenter.current().delegate = self }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner, .sound]) }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeKey {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
        completionHandler()
    }
}
@main struct KomorebiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store: StudyStore
    init() {
        do { try ThemeFonts.register() } catch {
            let alert = NSAlert(); alert.messageText = "Impossibile caricare i font del tema"; alert.informativeText = error.localizedDescription; alert.runModal()
            fatalError("Local theme font registration failed: \(error)")
        }
        do {
            let preview = Bundle.main.bundleIdentifier?.hasPrefix("com.komorebi.study.preview") == true
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let reviewURL = StudyReviewArchive.url(bundleIdentifier: Bundle.main.bundleIdentifier, applicationSupport: support)
            if let reviewURL { try FileManager.default.createDirectory(at: reviewURL.deletingLastPathComponent(), withIntermediateDirectories: true) }
            let instance = try StudyStore(inMemory: preview, defaults: preview ? UserDefaults(suiteName: "KomorebiPreview.\(UUID())")! : .standard, archiveURL: reviewURL)
            if preview { Self.configurePreview(instance) }
            _store = StateObject(wrappedValue: instance) }
        catch {
            let alert = NSAlert(); alert.messageText = "Impossibile aprire l’archivio"; alert.informativeText = "I dati non sono stati cancellati. \(error.localizedDescription)"; alert.runModal()
            fatalError("Cannot open persistent store: \(error)")
        }
    }
    private var compactPreview: Bool {
        Bundle.main.bundleIdentifier?.hasPrefix("com.komorebi.study.preview") == true && (ProcessInfo.processInfo.arguments.contains("--compact-preview") || Bundle.main.bundleIdentifier?.hasSuffix(".compact") == true)
    }
    @MainActor private static func configurePreview(_ store: StudyStore) {
        // Preview bundles always use a separate in-memory archive and disposable defaults.
        store.settings.onboarded = true
        store.settings.animations = "Full"
        if ProcessInfo.processInfo.arguments.contains("--dark-preview") || Bundle.main.bundleIdentifier?.hasSuffix(".dark") == true { store.settings.appearance = "Dark"; store.settings.landscape = "Night" }
        // QA-only bundle metadata. All preview stores and preferences remain isolated.
        if let mode = Bundle.main.object(forInfoDictionaryKey: "StudyPreviewAppearance") as? String { store.settings.appearance = mode }
        if let theme = Bundle.main.object(forInfoDictionaryKey: "StudyPreviewTheme") as? String { store.settings.themeID = theme }
        if let animation = Bundle.main.object(forInfoDictionaryKey: "StudyPreviewAnimations") as? String { store.settings.animations = animation }
        if Bundle.main.object(forInfoDictionaryKey: "StudyPreviewEmpty") as? Bool == true {
            for subject in store.subjects { store.context.delete(subject) }; store.save(); return
        }
        let subject = store.subjects.first!
        subject.name = Bundle.main.object(forInfoDictionaryKey: "StudyPreviewLongName") as? String ?? "Teoria dei Sistemi"
        let second = Subject(name: "Programmazione", color: "Cielo")
        store.context.insert(second)
        store.settings.lastSubject = subject.id
        for n in 0..<7 {
            let day = Calendar.current.date(byAdding: .day, value: -n, to: Date())!
            let start = Calendar.current.startOfDay(for: day).addingTimeInterval(8 * 3600)
            let duration = Double(n == 0 ? 5400 : 2400 + n * 480)
            let end = start.addingTimeInterval(duration)
            guard end <= Date() else { continue }
            store.context.insert(StudySession(start: start, end: end, duration: duration, subjectID: n % 2 == 0 ? subject.id : second.id, subjectName: n % 2 == 0 ? subject.name : second.name, mode: TimerMode.pomodoro.rawValue, pause: 0, note: n == 0 ? "Ripasso degli appunti" : "Esercizi e ripasso"))
        }
        // Mixed-day fixtures stay confined to the disposable preview archive.
        let mixedDay = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!).addingTimeInterval(14 * 3600)
        store.context.insert(StudySession(start: mixedDay, end: mixedDay.addingTimeInterval(10800), duration: 10800, subjectID: subject.id, subjectName: subject.name, mode: TimerMode.stopwatch.rawValue, pause: 0))
        store.context.insert(StudyExam(title: "Teoria dei Sistemi", date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, subjectID: subject.id))
        store.save()
    }
    var body: some Scene {
        WindowGroup(ProductText.name, id: "main") {
            Group {
                if Bundle.main.bundleIdentifier == "com.komorebi.study.preview" { MenuPanel().environment(\.komorebiMotion, store.settings.animations).buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()).toggleStyle(StudyToggleStyle()) }
                else { RootView() }
            }.environmentObject(store)
                .task {
                    // In-memory previews omit system integrations, but UI tests need a live clock.
                    guard Bundle.main.bundleIdentifier?.hasPrefix("com.komorebi.study.preview") == true else { return }
                    while !Task.isCancelled {
                        do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
                        store.tick()
                    }
                }
                .environment(\.komorebiMotion, store.settings.animations)
                .buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()).toggleStyle(StudyToggleStyle())
                .frame(minWidth: Bundle.main.bundleIdentifier == "com.komorebi.study.preview" ? DesignSystem.PreservedGeometry.points360 : DesignSystem.PreservedGeometry.points920, minHeight: Bundle.main.bundleIdentifier == "com.komorebi.study.preview" ? DesignSystem.PreservedGeometry.points550 : DesignSystem.PreservedGeometry.points650)
                .studyTheme(store.settings, date: store.now)
                .preferredColorScheme(store.settings.appearance == "System" ? nil : store.settings.appearance == "Dark" ? .dark : .light)
        }.defaultSize(width: Bundle.main.bundleIdentifier == "com.komorebi.study.preview" ? DesignSystem.PreservedGeometry.points360 : compactPreview ? DesignSystem.PreservedGeometry.points920 : DesignSystem.PreservedGeometry.points1140, height: compactPreview || Bundle.main.bundleIdentifier == "com.komorebi.study.preview" ? DesignSystem.PreservedGeometry.points650 : DesignSystem.PreservedGeometry.points790)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .sidebar) {
                Button(store.settings.showsSidebar ? "Nascondi barra laterale" : "Mostra barra laterale") {
                    store.settings.sidebarIsVisible = !store.settings.showsSidebar
                }.keyboardShortcut("s", modifiers: [.control, .command]).disabled(store.focus)
            }
            CommandMenu("Studio") {
                Button("Avvia sessione") { store.start() }.keyboardShortcut(.return, modifiers: .command).disabled(store.active != nil)
                Button("Pausa / Riprendi") { store.toggle() }.keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Termina sessione") { store.finish() }.keyboardShortcut(".", modifiers: .command).disabled(store.active == nil)
            }
        }
        MenuBarExtra {
            MenuPanel().environmentObject(store).environment(\.komorebiMotion, store.settings.animations).buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()).toggleStyle(StudyToggleStyle())
                .studyTheme(store.settings, date: store.now)
                .preferredColorScheme(store.settings.appearance == "System" ? nil : store.settings.appearance == "Dark" ? .dark : .light)
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: store.studying ? "book" : "book.closed")
                    .contentTransition(.symbolEffect(.replace))
                if store.showMenuTime, let a = store.active {
                    Text((a.pausedAt != nil ? "Ⅱ " : a.isBreak ? "↳ " : "") + clockText(a.displayed(at: store.now))).monospacedDigit()
                }
            }.accessibilityLabel(ProductText.name + ": " + store.stateText)
                .help(store.stateText)
        }.menuBarExtraStyle(.window)
    }
}
struct MenuPanel: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.openWindow) var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var note = ""
    @State private var editingNote = false
    var body: some View {
        ViewThatFits(in: .vertical) {
            panelContent
            ScrollView { panelContent }
        }.frame(width: DesignSystem.PreservedGeometry.points350).frame(maxHeight: DesignSystem.PreservedGeometry.points650).fixedSize(horizontal: false, vertical: true)
            .background(appTheme.palette.background).foregroundStyle(appTheme.palette.inheritedText)
            .containerBackground(appTheme.palette.background, for: .window)
            .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: editingNote)
            .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: store.active == nil)
            .sheet(isPresented: $store.correctingEnd) { EndTimeEditor().environmentObject(store) }
            .onAppear { note = store.completed?.note ?? "" }
            .onChange(of: store.completed?.id) { note = store.completed?.note ?? ""; editingNote = false }
    }
    var panelContent: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy18) {
                HStack {
                    Label(ProductText.wordmark, systemImage: store.studying ? "book" : "book.closed")
                        .font(appTheme.preservedTypography.menuWordmark).foregroundStyle(appTheme.palette.accent)
                    Spacer()
                    Button { showApp() } label: { Image(systemName: "arrow.up.right.square") }
                        .help("Apri app").accessibilityLabel(ProductText.openAccessible)
                }
                SessionStatusPill()
                if let a = store.active {
                    VStack(alignment: .leading, spacing: DesignSystem.PreservedGeometry.gap10) {
                        Text(a.subjectName).font(appTheme.preservedTypography.headline).fixedSize(horizontal: false, vertical: true)
                        HStack(alignment: .firstTextBaseline) {
                            if appTheme.cifreCellaFissa {
                                ThemeFixedTimerDigits(text: clockText(a.displayed(at: store.now)), pointSize: appTheme.typography.menuTimerPointSize)
                                    .frame(height: appTheme.typography.timerLineHeight(at: appTheme.typography.menuTimerPointSize))
                                    .accessibilityLabel("Tempo").accessibilityValue(clockText(a.displayed(at: store.now)))
                            } else {
                            Text(clockText(a.displayed(at: store.now)))
                                .font(appTheme.preservedTypography.menuTimerDigits).monospacedDigit()
                                .contentTransition(.numericText()).minimumScaleFactor(DesignSystem.PreservedGeometry.minimumScale0_6).lineLimit(1)
                            }
                            Spacer()
                            Text(a.isBreak ? "Intervallo" : a.mode.rawValue).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        }
                        if let target = a.target {
                            ProgressView(value: min(target, a.elapsed(at: store.now)), total: target).tint(a.isBreak ? appTheme.palette.interval : appTheme.palette.accent)
                        }
                    }
                    SessionControls(fromMenu: true)
                } else {
                    Text(appTheme.copy.text(.greeting, fallback: store.nextSubject == nil ? "Il prossimo passo è tuo." : "Pronto per ricominciare."))
                        .font(appTheme.preservedTypography.menuGreeting)
                    TimerSetup(compact: true)
                    SessionControls(fromMenu: true)
                }
                if let session = store.completed {
                    VStack(alignment: .leading, spacing: DesignSystem.PreservedGeometry.gap10) {
                        HStack {
                            Label("Salvata · " + durationText(session.duration), systemImage: "checkmark.circle.fill")
                                .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.accent)
                            Spacer()
                            if !editingNote {
                                Button("Nota") { editingNote = true }.font(appTheme.preservedTypography.caption)
                                Button { store.completed = nil } label: { Image(systemName: "xmark") }
                                    .accessibilityLabel("Chiudi conferma di salvataggio")
                            }
                        }
                        if editingNote {
                            StudyTextEntry("Una nota per la prossima volta…", text: $note, axis: .vertical).interactiveHover(textEntry: true).lineLimit(2...4).textFieldStyle(StudyTextFieldStyle())
                            HStack {
                                Button("Annulla") { note = session.note; editingNote = false }
                                Spacer()
                                Button("Salva nota") { session.note = note; if store.save() { store.completed = nil } }
                            }
                        }
                    }.padding(DesignSystem.Spacing.sm).background(appTheme.palette.accent.opacity(appTheme.appearance.opacity0_07), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
                }
                if let message = store.statusMessage {
                    Label(message, systemImage: "info.circle").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                if let error = store.error {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Label(error, systemImage: "exclamationmark.triangle").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.appearance.destructiveInk)
                        HStack {
                            Button("Chiudi") { store.error = nil }
                            if store.active != nil && store.active?.isBreak == false {
                                Button("Riprova salvataggio") { store.error = nil; store.finish(fromMenu: true) }
                            }
                        }.font(appTheme.preservedTypography.caption)
                    }
                }
                Divider()
                VStack(spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Il tuo studio di oggi").foregroundStyle(appTheme.palette.textSecondary)
                        Spacer()
                        Text(durationText(store.liveToday) + " / " + durationText(store.settings.dailyGoal * 3600)).monospacedDigit()
                    }.font(appTheme.preservedTypography.caption)
                    ProgressView(value: min(store.liveToday, store.settings.dailyGoal * 3600), total: store.settings.dailyGoal * 3600).tint(appTheme.palette.accent)
                }
                HStack {
                    Button("Apri timer") { store.openTimer = true; showApp() }.font(appTheme.preservedTypography.caption)
                    Spacer()
                    Menu {
                        if store.active?.isBreak == false {
                            Button("Correggi ora di fine…") { store.finishDate = Date(); store.correctingEnd = true }
                        }
                        Button(ProductText.open) { showApp() }
                        Divider()
                        Button(ProductText.quit) { NSApp.terminate(nil) }
                    } label: { Image(systemName: "ellipsis").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(Rectangle()) }.menuStyle(.borderlessButton).fixedSize().interactiveHover().help("Altre azioni")
                }
            }.padding(DesignSystem.Spacing.lg)
    }
    func showApp() {
        openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.identifier?.rawValue.contains("main") == true {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
    }
}
struct EndTimeEditor: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var fromMenu = true
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy18) {
            Text("Correggi fine sessione").font(appTheme.preservedTypography.title2)
            Text("Il periodo successivo all’ora scelta sarà escluso dallo studio.").foregroundStyle(appTheme.palette.textSecondary)
            DatePicker("Fine", selection: $store.finishDate, in: (store.active?.start ?? Date.distantPast)...Date()).interactiveHover()
            HStack {
                Button("Annulla") { store.correctingEnd = false }
                Spacer()
                Button("Termina e salva") { store.error = nil; store.finish(at: store.finishDate, fromMenu: fromMenu); if store.error == nil { store.correctingEnd = false } }.buttonStyle(ResponsiveButtonStyle(prominent: true))
            }
        }.padding(DesignSystem.Spacing.xl).frame(width: DesignSystem.PreservedGeometry.points400)
    }
}
