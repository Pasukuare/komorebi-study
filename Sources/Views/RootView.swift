import SwiftUI

enum Page: String, CaseIterable, Identifiable {
    case home = "Home", timer = "Timer", calendar = "Calendario", statistics = "Statistiche", history = "Cronologia", subjects = "Materie", settings = "Impostazioni"
    var id: String { rawValue }
    var icon: String {
        switch self { case .home: return "house"; case .timer: return "timer"; case .calendar: return "calendar"; case .statistics: return "chart.bar.xaxis"; case .history: return "clock.arrow.circlepath"; case .subjects: return "books.vertical"; case .settings: return "slider.horizontal.3" }
    }
}
struct RootView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Page = .home
    @State private var revealTheme = false
    private var sidebarVisible: Bool { store.settings.showsSidebar }
    @Namespace private var sidebarSelection
    private var animated: Bool { !reduceMotion && store.settings.animations != "Off" }
    private var sidebarAnimation: Animation? {
        let duration = DesignSystem.SidebarToggle.duration(reduceMotion: reduceMotion, animations: store.settings.animations)
        return duration == 0 ? nil : .easeInOut(duration: duration)
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: DesignSystem.Layout.windowControlsSpace).contentShape(Rectangle()).gesture(WindowDragGesture())
                    Color.clear.frame(width: DesignSystem.SidebarToggle.size).allowsHitTesting(false)
                    Color.clear.contentShape(Rectangle()).gesture(WindowDragGesture())
                }.frame(height: DesignSystem.Layout.headerHeight)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                ThemeBrand().font(appTheme.typography.wordmark).foregroundStyle(appTheme.palette.accent)
                    .environment(\.komorebiSectionVisible, sidebarVisible && !store.focus)
                    .padding(.horizontal, DesignSystem.Spacing.lg).padding(.top, DesignSystem.Spacing.xl)
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(Page.allCases) { item in
                            Button { page = item } label: {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: item.icon).font(appTheme.typography.body).fontWeight(appTheme.preservedTypography.regularWeight)
                                        .foregroundStyle(page == item ? appTheme.palette.sidebarSelectedIcon : appTheme.palette.textSecondary)
                                        .frame(width: DesignSystem.Spacing.xl)
                                    Text(item.rawValue).font(appTheme.typography.small).fontWeight(page == item ? appTheme.preservedTypography.semiboldWeight : appTheme.preservedTypography.regularWeight)
                                    Spacer(minLength: 0)
                                }.padding(.horizontal, DesignSystem.Spacing.sm).padding(.vertical, DesignSystem.Spacing.sm)
                                    .foregroundStyle(page == item ? appTheme.palette.sidebarSelectedText : appTheme.palette.textPrimary)
                                    .background {
                                        if page == item {
                                            RoundedRectangle(cornerRadius: DesignSystem.Radius.card).fill(appTheme.palette.sidebarSelection.opacity(appTheme.appearance.sidebarSelectionOpacity))
                                                .matchedGeometryEffect(id: "active", in: sidebarSelection).allowsHitTesting(false)
                                        }
                                    }.contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                            }.buttonStyle(.plain).interactiveHover(cornerRadius: DesignSystem.Radius.card)
                                .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card))
                                .accessibilityAddTraits(page == item ? .isSelected : [])
                        }
                    }.padding(.horizontal, DesignSystem.Spacing.sm).padding(.vertical, DesignSystem.Spacing.xs)
                }.onMoveCommand { direction in
                    let index = Page.allCases.firstIndex(of: page) ?? 0
                    if direction == .up, index > 0 { page = Page.allCases[index - 1] }
                    if direction == .down, index + 1 < Page.allCases.count { page = Page.allCases[index + 1] }
                }
                Text("Il tuo studio rimane sul tuo Mac.").font(appTheme.typography.caption)
                    .foregroundStyle(appTheme.palette.textSecondary).padding(DesignSystem.Spacing.lg)
                }.opacity(sidebarVisible ? (store.studying ? appTheme.appearance.opacity0_90 : 1) : 0)
                    .animation(animated ? .easeOut(duration: DesignSystem.SidebarToggle.fadeDuration) : nil, value: sidebarVisible)
            }
            .frame(width: DesignSystem.Layout.sidebarWidth)
            .frame(width: sidebarVisible ? DesignSystem.Layout.sidebarWidth : 0, alignment: .leading)
            .clipped()
            .background { SidebarChromeSurface().ignoresSafeArea() }
            .overlay(alignment: .trailing) { Rectangle().fill(appTheme.palette.border.opacity(appTheme.appearance.opacity0_35)).frame(width: DesignSystem.Layout.dividerWidth).opacity(sidebarVisible ? 1 : 0) }
            .disabled(store.focus || !sidebarVisible).accessibilityHidden(store.focus || !sidebarVisible)
            VStack(spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(ProductText.name).font(appTheme.typography.small).fontWeight(appTheme.preservedTypography.mediumWeight)
                    Spacer(minLength: DesignSystem.Spacing.md)
                    Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                        .foregroundStyle(appTheme.palette.textSecondary).font(appTheme.typography.caption).lineLimit(1)
                }
                .contentShape(Rectangle()).gesture(WindowDragGesture())
                .padding(.leading, sidebarVisible ? 0 : DesignSystem.SidebarToggle.collapsedHeaderInset)
                .padding(.horizontal, DesignSystem.Layout.contentPadding)
                .frame(maxWidth: DesignSystem.Layout.contentMaximum)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Layout.headerHeight)
                .background { SidebarChromeSurface().ignoresSafeArea(edges: .top) }
                .zIndex(2)
            // Stable identities retain each section's scroll position, filters and drafts.
            ZStack {
                section(.home) { OverviewView(openTimer: { page = .timer }, openCalendar: { page = .calendar }, openThemeSettings: { page = .settings; revealTheme = true }) }
                section(.timer) { HomeView() }
                section(.statistics) { StatisticsView() }
                section(.calendar) { CalendarView() }
                section(.history) { HistoryView() }
                section(.subjects) { SubjectsView() }
                section(.settings) { SettingsView(revealTheme: $revealTheme) }
            }.background(appTheme.palette.background).clipped()
            }
        }
        .overlay(alignment: .topLeading) {
            sidebarToggle.padding(.leading, DesignSystem.Layout.windowControlsSpace)
                .frame(height: DesignSystem.Layout.headerHeight)
        }
        .ignoresSafeArea(.container, edges: .top)
        .opacity(store.focus ? 0 : 1)
        .overlay {
            if store.focus { FocusView().transition(.opacity) }
        }
        .animation(sidebarAnimation, value: sidebarVisible)
        .animation(animated ? .easeOut(duration: DesignSystem.Interaction.sectionDuration) : nil, value: page)
        .animation(animated ? .easeOut(duration: DesignSystem.Interaction.sectionDuration) : nil, value: store.focus)
        .animation(animated ? .easeOut(duration: DesignSystem.Interaction.sectionDuration) : nil, value: store.studying)
        .tint(appTheme.palette.accent).foregroundStyle(appTheme.palette.textPrimary)
        .environment(\.komorebiMotion, store.settings.animations)
        .buttonStyle(ResponsiveButtonStyle())
        .onChange(of: store.openTimer) { if store.openTimer { page = .timer; store.openTimer = false } }
        .sheet(isPresented: Binding(get: { !store.settings.onboarded }, set: { if !$0 { store.settings.onboarded = true } })) { OnboardingView() }
        .sheet(item: Binding(get: { store.menuCompletion ? nil : store.completed }, set: { store.completed = $0 })) { session in CompletionView(session: session) }
        .alert(ProductText.name, isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
    }
    private var sidebarToggle: some View {
        SidebarGhostToggle(isOpen: sidebarVisible) { store.settings.sidebarIsVisible = !sidebarVisible }
            .disabled(store.focus)
    }
    private func section<Content: View>(_ item: Page, @ViewBuilder content: () -> Content) -> some View {
        content()
            .environment(\.komorebiSectionVisible, page == item && !store.focus)
            .opacity(page == item ? 1 : 0)
            .offset(y: page == item || !animated ? 0 : DesignSystem.Interaction.sectionOffset)
            .allowsHitTesting(page == item && !store.focus).disabled(page != item || store.focus)
            .accessibilityHidden(page != item || store.focus)
            .zIndex(page == item ? 1 : 0)
    }
}
struct HomeView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
                        Text(appTheme.copy.text(.timerSubtitle, fallback: "Il tuo tempo, una cosa alla volta.")).font(appTheme.typography.timerTitle)
                        Text("Uno spazio per concentrarti, al tuo ritmo.").foregroundStyle(appTheme.palette.textSecondary)
                    }
                    Spacer(minLength: DesignSystem.Spacing.md)
                    Button {
                        store.focus = true
                        if NSApp.keyWindow?.styleMask.contains(.fullScreen) != true { NSApp.keyWindow?.toggleFullScreen(nil) }
                    } label: { Label("Focus", systemImage: "arrow.up.left.and.arrow.down.right") }.help("Riduci le distrazioni")
                }
                VStack(spacing: DesignSystem.Spacing.xl) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DesignSystem.Spacing.xxl) {
                            TimerFace().frame(width: DesignSystem.TimerLayout.faceWide)
                            sessionPanel(compact: false).frame(width: DesignSystem.TimerLayout.panelWide)
                        }.frame(minWidth: DesignSystem.TimerLayout.wideMinimum)
                        HStack(spacing: DesignSystem.Spacing.xl) {
                            TimerFace().frame(width: DesignSystem.TimerLayout.faceMedium)
                            sessionPanel(compact: true).frame(width: DesignSystem.TimerLayout.panelMedium)
                        }.frame(minWidth: DesignSystem.TimerLayout.mediumMinimum)
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            TimerFace().frame(width: DesignSystem.TimerLayout.faceCompact)
                            sessionPanel(compact: true).frame(maxWidth: DesignSystem.TimerLayout.panelCompact)
                        }
                    }
                    Divider().overlay(appTheme.palette.timerDivider)
                    HStack {
                        AmbientControls(audio: store.audio)
                        Spacer(minLength: DesignSystem.Spacing.sm)
                        if store.active != nil && store.active?.isBreak == false {
                            Button("Correggi fine…") { store.finishDate = Date(); store.correctingEnd = true }.font(appTheme.typography.caption)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.legacy30).frame(maxWidth: .infinity)
                .background { Landscape(theme: store.settings.landscape, animations: store.settings.animations) }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.legacyTimerPanel))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.legacyTimerPanel).stroke(appTheme.palette.timerBorder).allowsHitTesting(false))
                .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: store.active == nil)
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy6) {
                            Text("Ogni minuto conta").font(appTheme.typography.legacyHeadline)
                            Text(store.active?.isBreak == false ? "Il tempo in corso è incluso nel progresso di oggi." : "Ritrova qui il progresso della tua giornata.").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        }
                        Spacer()
                        Text(durationText(store.liveToday)).font(appTheme.typography.timerTotal).monospacedDigit()
                    }
                    GoalBar(title: "Obiettivo di oggi", value: store.liveToday, goal: store.settings.dailyGoal * 3600)
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum)
                .frame(maxWidth: .infinity)
        }.foregroundStyle(appTheme.palette.textPrimary).background(appTheme.palette.background)
        .sheet(isPresented: $store.correctingEnd) { EndTimeEditor(fromMenu: false).environmentObject(store) }
    }
    func sessionPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            SessionStatusPill()
            if store.active == nil {
                Text(store.nextSubject == nil ? "Prepara la tua sessione" : "Riparti da dove eri").font(appTheme.typography.timerSetupTitle)
                TimerSetup(compact: compact).transition(.opacity)
            } else {
                Text(store.active?.isBreak == true ? "Una pausa per ricaricarti." : store.active?.pausedAt != nil ? "Prenditi il tempo che serve." : "Sei nel tuo momento di studio.")
                    .font(appTheme.typography.timerMessage).fixedSize(horizontal: false, vertical: true)
                Label(store.active?.mode.rawValue ?? "", systemImage: "timer").font(appTheme.typography.legacyCallout).foregroundStyle(appTheme.palette.textSecondary)
            }
            SessionControls()
            Text(store.active?.isBreak == true ? "La prossima sessione partirà quando lo decidi tu." : "Al termine, il tuo tempo viene salvato nell’archivio.")
                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary).fixedSize(horizontal: false, vertical: true)
            if let message = store.statusMessage {
                Label(message, systemImage: "info.circle").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: store.stateText)
    }
}
struct SessionControls: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var fromMenu = false
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.legacy9) {
            Button { store.toggle() } label: {
                Label(store.actionTitle, systemImage: store.active != nil && store.active?.pausedAt == nil ? "pause.fill" : "play.fill")
                    .font(appTheme.typography.control)
                    .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.Spacing.legacy6)
            }.buttonStyle(StudyActionStyle()).disabled(store.active == nil && store.subjects.isEmpty)
            if let active = store.active {
                Button(active.isBreak ? "Salta pausa" : "Termina e salva") {
                    if active.isBreak { store.skipBreak() } else { store.finish(fromMenu: fromMenu) }
                }.frame(maxWidth: .infinity)
            }
        }
    }
}
struct TimerSetup: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy14) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy6) {
                Text("Materia").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                StudyDropdown(title: "Materia", options: store.subjects.map { (Optional($0.id), $0.name) }, selection: Binding(get: { store.preparedSubject?.id }, set: { store.chooseSubject($0) })).frame(maxWidth: .infinity)
                if store.subjects.isEmpty { Text("Aggiungi una materia per iniziare.").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary) }
            }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy6) {
                Text("Modalità").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                if compact {
                    modePicker
                } else {
                    PastelSegmentedControl("Modalità", values: TimerMode.allCases, selection: Binding(get: { store.preparedMode }, set: { store.chooseMode($0) })) { $0.rawValue }
                }
            }
            if store.preparedMode == .pomodoro {
                HStack {
                    Text("Studio").foregroundStyle(appTheme.palette.textSecondary)
                    Spacer()
                    StudyNumberField(title: "Minuti di studio", value: $store.settings.pomodoroDuration).frame(width: DesignSystem.TimerLayout.studyField).multilineTextAlignment(.trailing)
                    Text("min").foregroundStyle(appTheme.palette.textSecondary)
                }.font(appTheme.typography.legacyCallout)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach([25, 50, 90], id: \.self) { minutes in
                        DurationChip(minutes: minutes, value: $store.settings.pomodoroDuration)
                    }
                }
                if !compact {
                    Text("Pausa breve: \(durationText(store.settings.shortBreakDuration * 60)) · lunga ogni \(store.settings.longBreakEvery) sessioni")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            } else if store.preparedMode == .custom {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    HStack { Text("Studio"); Spacer(); StudyNumberField(title: "Minuti di studio", value: $store.settings.customMinutes, range: 1...1440).frame(width: DesignSystem.TimerLayout.studyField) }
                    HStack { Text("Pausa"); Spacer(); StudyNumberField(title: "Minuti di pausa", value: $store.settings.customBreak, range: 0...360).frame(width: DesignSystem.TimerLayout.studyField) }
                }.font(appTheme.typography.caption)
            } else {
                Text("Senza conto alla rovescia. Termina quando vuoi.").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }
    }
    var modePicker: some View {
        StudyDropdown(title: "Modalità", options: TimerMode.allCases.map { ($0, $0.rawValue) }, selection: Binding(get: { store.preparedMode }, set: { store.chooseMode($0) })).frame(maxWidth: .infinity)
    }
}
struct TimerFace: View {
    @Environment(\.studyTheme) private var appTheme
    var minimal = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject var store: StudyStore
    var target: Double? { store.active.map { $0.target } ?? store.preparedTarget }
    var elapsed: Double { store.active?.elapsed(at: store.now) ?? 0 }
    var color: Color { store.active?.isBreak == true ? appTheme.palette.interval : appTheme.palette.accent }
    var time: String { store.active.map { clockText($0.displayed(at: store.now)) } ?? clockText(store.preparedTarget ?? 0) }
    @ViewBuilder private var timerTime: some View {
        if appTheme.cifreCellaFissa {
            ThemeFixedTimerDigits(text: time, pointSize: appTheme.typography.timerPointSize)
        } else {
            Text(time).font(appTheme.typography.timerDigits)
                .contentTransition(.numericText()).minimumScaleFactor(DesignSystem.TimerLayout.minimumDigitScale).lineLimit(1)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.legacy18) {
            Text(store.active?.subjectName ?? store.preparedSubject?.name ?? "Il tuo studio")
                .font(appTheme.typography.timerSubject).lineLimit(2).multilineTextAlignment(.center)
            GeometryReader { geometry in
                ZStack {
                    TimerProgressRing(value: elapsed, total: target, running: store.studying)
                        .modifier(TimerRingMotion(running: store.studying, completion: store.completionPulse))
                    timerTime
                        .foregroundStyle(appTheme.palette.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: time)
                        .accessibilityLabel("Tempo").accessibilityValue(time)
                    if !minimal { VStack {
                        Image(systemName: store.active?.isBreak == true ? "cup.and.saucer" : store.studying ? "book" : "book.closed")
                            .font(appTheme.typography.timerSymbol).foregroundStyle(color)
                            .opacity(DesignSystem.TimerLayout.symbolOpacity).accessibilityHidden(true)
                        Spacer()
                        Text(target == nil ? "tempo trascorso" : store.active?.isBreak == true ? "tempo per te" : "tempo rimanente")
                            .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, geometry.size.height * DesignSystem.TimerLayout.faceInsetRatio)
                    }
                }
            }.aspectRatio(1, contentMode: .fit)
            if !minimal && store.active?.mode == .pomodoro {
                Text("Pomodoro \(store.cycles + (store.active?.isBreak == true ? 0 : 1))").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }
    }
}
struct FocusView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var lastMovement = Date()
    @State private var controlsVisible = true
    @FocusState private var controlFocused: Bool
    @FocusState private var surfaceFocused: Bool
    private var visible: Bool { controlsVisible || controlFocused || voiceOver }
    var body: some View {
        ZStack {
            Landscape(theme: store.settings.landscape, animations: store.settings.animations, driftingLight: true).ignoresSafeArea()
            TimerFace(minimal: true).frame(maxWidth: DesignSystem.PreservedGeometry.points360).padding(DesignSystem.Spacing.xxl)
            VStack {
                HStack {
                    Spacer()
                    Button("Esci da Focus", systemImage: "arrow.down.right.and.arrow.up.left", action: exitFocus)
                        .keyboardShortcut(.escape, modifiers: [])
                        .focused($controlFocused)
                }
                Spacer()
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button(store.actionTitle, systemImage: store.studying ? "pause.fill" : "play.fill") { store.toggle() }
                        .buttonStyle(StudyActionStyle()).focused($controlFocused)
                    Button("Esci", action: exitFocus).focused($controlFocused)
                }
            }.padding(DesignSystem.Spacing.xxl)
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(visible)
                // Keep controls in the keyboard and VoiceOver traversal even when visually hidden.
                .animation(reduceMotion || store.settings.animations == "Off" ? nil : .easeOut(duration: DesignSystem.Interaction.sectionDuration), value: visible)
        }.contentShape(Rectangle())
            .focusable().focusEffectDisabled().focused($surfaceFocused)
            .onAppear { surfaceFocused = true }
            .onKeyPress(.escape) { exitFocus(); return .handled }
            .onKeyPress(.tab) { controlsVisible = true; return .ignored }
            .onContinuousHover { phase in
                if case .active = phase { controlsVisible = true; lastMovement = Date() }
            }
            .task(id: lastMovement) {
                do { try await Task.sleep(nanoseconds: DesignSystem.Interaction.controlsTimeout) }
                catch { return }
                controlsVisible = false
            }
            .onExitCommand(perform: exitFocus)
    }
    private func exitFocus() {
        store.focus = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == true { NSApp.keyWindow?.toggleFullScreen(nil) }
    }
}
struct CompletionView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    let session: StudySession
    @State private var note = ""
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "leaf.fill").font(appTheme.preservedTypography.completionSymbol).foregroundStyle(appTheme.palette.accent)
            Text("Sessione salvata").font(appTheme.preservedTypography.completionTitle)
            Text("\(session.subjectName) · \(durationText(session.duration))").font(appTheme.preservedTypography.title3)
            Text("Oggi \(durationText(store.liveToday)) · Settimana \(durationText(store.liveWeekly))").foregroundStyle(appTheme.palette.textSecondary)
            StudyTextEntry("Una nota per la prossima volta…", text: $note, axis: .vertical).interactiveHover(textEntry: true).lineLimit(3...5).textFieldStyle(StudyTextFieldStyle())
            Button("Continua") { session.note = note; if store.save() { store.completed = nil } }.buttonStyle(ResponsiveButtonStyle(prominent: true)).keyboardShortcut(.defaultAction)
        }.padding(DesignSystem.PreservedGeometry.gap36).frame(width: DesignSystem.PreservedGeometry.points440).onAppear { note = session.note }
    }
}
struct OnboardingView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "leaf").font(appTheme.preservedTypography.welcomeSymbol).foregroundStyle(appTheme.palette.accent)
            Text(ProductText.welcome).font(appTheme.preservedTypography.pageTitle)
            Text("Timer\nIl tuo tempo si salva automaticamente.\nCostruisci una routine sostenibile.").multilineTextAlignment(.center).lineSpacing(DesignSystem.Spacing.xs)
            Text("Quanto vorresti studiare al giorno?").font(appTheme.preservedTypography.headline)
            HStack { ForEach([2,3,4], id: \.self) { h in Button("\(h) ore") { store.settings.dailyGoal = Double(h) } } }
            HStack { Text("Obiettivo in ore"); StudyNumberField(title: "Ore", value: $store.settings.dailyGoal).frame(width: DesignSystem.TimerLayout.studyField) }
            Button("Entra nel tuo spazio") {
                store.settings.dailyGoal = store.settings.dailyGoal.isFinite && store.settings.dailyGoal > 0 ? min(24, max(0.25, store.settings.dailyGoal)) : 3.0
                store.settings.onboarded = true
            }.buttonStyle(ResponsiveButtonStyle(prominent: true)).controlSize(.large)
            Text("Offline. Nessun account. Solo il tuo Mac.").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
        }.padding(DesignSystem.PreservedGeometry.gap40).frame(width: DesignSystem.PreservedGeometry.points480)
    }
}

struct OverviewView: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var openTimer: () -> Void
    var openCalendar: () -> Void
    var openThemeSettings: () -> Void
    var upcoming: [StudyExam] { store.exams.filter { $0.date >= store.day.start } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
                        Text("Il tuo studio, oggi.").font(appTheme.preservedTypography.homeTitle)
                        Text(appTheme.copy.text(.homeSubtitle, fallback: "Riparti da una materia. Il resto può aspettare.")).foregroundStyle(appTheme.palette.textSecondary)
                    }
                    Spacer()
                    if store.streak > 0 {
                        Label(appTheme.copy.streak(store.streak), systemImage: "leaf")
                            .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.accent).padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                ForEach(ThemeCampaign.available(settings: store.settings, date: store.now)) { campaign in
                    ThemeSuggestionCard(campaign: campaign, open: openThemeSettings) { store.dismissThemeCampaign(campaign.id) }
                }
                ViewThatFits(in: .horizontal) {
                    EqualHeightCardRow(spacing: DesignSystem.Spacing.lg) {
                        quickStart.frame(minWidth: DesignSystem.PreservedGeometry.points310)
                        DailyGoalCard(stretches: true).frame(width: DesignSystem.PreservedGeometry.points240)
                    }
                    VStack(spacing: DesignSystem.Spacing.lg) { quickStart; DailyGoalCard() }
                }
                Card {
                    HStack {
                        Text("Il ritmo della settimana").font(appTheme.preservedTypography.homeCardTitle)
                        Spacer()
                        GoalEditButton().labelStyle(.iconOnly).help("Modifica obiettivi")
                    }
                    GoalBar(title: "Questa settimana", value: store.liveWeekly, goal: store.settings.weeklyGoal * 3600)
                }
                ViewThatFits(in: .horizontal) {
                    EqualHeightCardRow(spacing: DesignSystem.Spacing.lg) {
                        upcomingCard.frame(minWidth: DesignSystem.PreservedGeometry.points280)
                        recentCard.frame(minWidth: DesignSystem.PreservedGeometry.points280)
                    }
                    VStack(spacing: DesignSystem.Spacing.lg) { upcomingCard; recentCard }
                }
            }.padding(DesignSystem.Layout.contentPadding).frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }.background(appTheme.palette.background)
    }
    var quickStart: some View {
        Card(stretches: true) {
            SessionStatusPill()
            Text(store.active == nil ? "Da dove ripartiamo?" : store.active?.subjectName ?? "La tua sessione")
                .font(appTheme.preservedTypography.editorTitle).fixedSize(horizontal: false, vertical: true)
            if store.active == nil {
                StudyDropdown(title: "Materia", options: store.subjects.map { (Optional($0.id), $0.name) }, selection: Binding(get: { store.preparedSubject?.id }, set: { store.chooseSubject($0) }))
                Label(store.preparedSummary, systemImage: "timer").font(appTheme.preservedTypography.callout).foregroundStyle(appTheme.palette.textSecondary)
                HStack {
                    Button {
                        store.start(); if store.active != nil { openTimer() }
                    } label: { Label("Inizia a studiare", systemImage: "play.fill").padding(.vertical, DesignSystem.Spacing.xxs) }
                        .buttonStyle(StudyActionStyle()).disabled(store.subjects.isEmpty)
                    Button("Configura", action: openTimer)
                }
            } else {
                Text(store.active.map { clockText($0.displayed(at: store.now)) } ?? "")
                    .font(appTheme.preservedTypography.homeTimerValue).monospacedDigit()
                HStack {
                    Button("Torna alla sessione", action: openTimer).buttonStyle(ResponsiveButtonStyle(prominent: true))
                    Button(store.actionTitle) { store.toggle() }
                }
            }
        }
    }
    var upcomingCard: some View {
        Card(stretches: true) {
            HStack {
                Text("Prossimi esami").font(appTheme.preservedTypography.homeCardTitle)
                Spacer()
                Button(action: openCalendar) { Image(systemName: "arrow.up.right") }.help("Apri calendario").accessibilityLabel("Apri calendario")
            }
            if upcoming.isEmpty {
                Text("Nessuna scadenza in vista.").foregroundStyle(appTheme.palette.textSecondary)
                Button("Aggiungi dal calendario", action: openCalendar)
            }
            ForEach(Array(upcoming.prefix(2))) { exam in ExamRow(exam: exam) }
        }
    }
    var recentCard: some View {
        Card(stretches: true) {
            Text("Ultime sessioni").font(appTheme.preservedTypography.homeCardTitle)
            if store.sessions.isEmpty { Text("Le tue sessioni appariranno qui, una alla volta.").foregroundStyle(appTheme.palette.textSecondary) }
            ForEach(Array(store.sessions.prefix(2))) { session in SessionRow(session: session) }
        }
    }
}
struct DailyGoalCard: View {
    var stretches = false
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var goal: Double { store.settings.dailyGoal * 3600 }
    var body: some View {
        Card(stretches: stretches) {
            HStack { Text("Il tuo obiettivo di oggi").font(appTheme.preservedTypography.headline); Spacer() }
            VStack(spacing: 0) {
                if stretches { Spacer(minLength: 0) }
                ZStack {
                ProgressRing(value: store.liveToday, total: goal)
                VStack(spacing: DesignSystem.PreservedGeometry.gap5) {
                    Text(durationText(store.liveToday)).font(appTheme.preservedTypography.dailyGoalValue).monospacedDigit()
                    Text("di \(durationText(goal))").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            }.frame(width: DesignSystem.PreservedGeometry.points132, height: DesignSystem.PreservedGeometry.points132).frame(maxWidth: .infinity).padding(.vertical, DesignSystem.PreservedGeometry.gap3)
                if stretches { Spacer(minLength: 0) }
            }.frame(maxHeight: stretches ? .infinity : nil)
            Text(store.liveToday >= goal ? "Obiettivo raggiunto. Ben fatto." : "Ancora \(durationText(goal - store.liveToday)), al tuo ritmo.")
                .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary).frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct ThemeSuggestionCard: View {
    @Environment(\.studyTheme) private var appTheme
    let campaign: ThemeCampaign
    let open: () -> Void
    let dismiss: () -> Void
    var body: some View {
        Card {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                ThemeTimerPreview(preview: campaign.package.resolve(mode: appTheme.mode))
                    .frame(width: DesignSystem.ThemeLayout.previewWidth).allowsHitTesting(false).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Prova il tema " + campaign.package.name).font(appTheme.typography.heading)
                    Text(campaign.package.subtitle).font(appTheme.typography.small).foregroundStyle(appTheme.palette.textSecondary)
                    Button("Apri le impostazioni del tema", action: open)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Button(action: dismiss) { Image(systemName: "xmark").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control)) }
                    .accessibilityLabel("Chiudi suggerimento del tema " + campaign.package.name)
            }
        }
    }
}
