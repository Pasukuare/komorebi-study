import SwiftUI

enum Page: String, CaseIterable, Identifiable {
    case home = "Home", timer = "Timer", calendar = "Calendario", statistics = "Statistiche", history = "Cronologia", subjects = "Materie", settings = "Impostazioni"
    var id: String { rawValue }
    var icon: String {
        switch self { case .home: return "house"; case .timer: return "timer"; case .calendar: return "calendar"; case .statistics: return "chart.bar.xaxis"; case .history: return "clock.arrow.circlepath"; case .subjects: return "books.vertical"; case .settings: return "slider.horizontal.3" }
    }
}
struct RootView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Page = .home
    @State private var visitedPages: Set<Page> = [.home]
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
                                    Text(L10n.tr(item.rawValue)).font(appTheme.typography.small).fontWeight(page == item ? appTheme.preservedTypography.semiboldWeight : appTheme.preservedTypography.regularWeight)
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
                Text(L10n.tr("Il tuo studio rimane sul tuo Mac.")).font(appTheme.typography.caption)
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
                    Text(store.now, format: .dateTime.weekday(.wide).day().month(.wide))
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
        .renderingLifecycle()
        .interactionHost(scope: page.rawValue + String(store.focus), clearNativeFocus: !store.focus)
        .onChange(of: page) { previous, current in
            visitedPages.insert(previous)
            visitedPages.insert(current)
        }
        .onChange(of: store.openSubjects, initial: true) { if store.openSubjects { page = .subjects; store.openSubjects = false } }
        .onChange(of: store.openTimer) { if store.openTimer { page = .timer; store.openTimer = false } }
        .sheet(isPresented: Binding(get: { !store.settings.onboarded }, set: { if !$0 { store.settings.onboarded = true } })) { OnboardingView() }
        .sheet(item: Binding(get: { store.menuCompletion ? nil : store.completed }, set: { store.completed = $0 })) { session in CompletionView(session: session) }
        .alert(ProductText.name, isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(L10n.message(store.error ?? "")) }
    }
    private var sidebarToggle: some View {
        SidebarGhostToggle(isOpen: sidebarVisible) { store.settings.sidebarIsVisible = !sidebarVisible }
            .disabled(store.focus)
    }
    @ViewBuilder private func section<Content: View>(_ item: Page, @ViewBuilder content: () -> Content) -> some View {
        // Defer Charts, lists and their native tracking views until the first visit.
        // Afterwards retain the same identity so scroll, filters and drafts survive.
        if page == item || visitedPages.contains(item) {
        content()
            .environment(\.komorebiSectionVisible, page == item && !store.focus)
            .opacity(page == item ? 1 : 0)
            .offset(y: page == item || !animated ? 0 : DesignSystem.Interaction.sectionOffset)
            .allowsHitTesting(page == item && !store.focus).disabled(page != item || store.focus)
            .accessibilityHidden(page != item || store.focus)
            .zIndex(page == item ? 1 : 0)
        }
    }
}
struct HomeView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
                        Text(appTheme.copy.text(.timerSubtitle, fallback: "Timer")).font(appTheme.typography.timerTitle)
                        PersonalPhrase(slot: .timer)
                    }
                    Spacer(minLength: DesignSystem.Spacing.md)
                    Button {
                        store.focus = true
                        if NSApp.keyWindow?.styleMask.contains(.fullScreen) != true { NSApp.keyWindow?.toggleFullScreen(nil) }
                    } label: { Label("Focus", systemImage: "arrow.up.left.and.arrow.down.right") }.help(L10n.tr("Riduci le distrazioni"))
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
                            Button(L10n.tr("Correggi fine…")) { store.finishDate = Date(); store.correctingEnd = true }.font(appTheme.typography.caption)
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
                            Text(L10n.tr("Studio di oggi")).font(appTheme.typography.legacyHeadline)
                            Text(store.active?.isBreak == false ? L10n.tr("Il tempo in corso è incluso nel progresso di oggi.") : L10n.tr("Tempo registrato oggi.")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        }
                        Spacer()
                        LiveStudyTime { _ in Text(durationText(store.liveToday)).font(appTheme.typography.timerTotal).monospacedDigit() }
                    }
                    LiveStudyTime { _ in GoalBar(title: L10n.tr("Obiettivo di oggi"), value: store.liveToday, goal: store.settings.dailyGoal * 3600) }
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
                Text(store.nextSubject == nil ? L10n.tr("Configurazione della sessione") : L10n.tr("Configurazione della sessione")).font(appTheme.typography.timerSetupTitle)
                TimerSetup(compact: compact).transition(.opacity)
            } else {
                Text(store.active?.isBreak == true ? L10n.tr("Pausa in corso.") : store.active?.pausedAt != nil ? L10n.tr("Timer in pausa.") : L10n.tr("Timer in corso."))
                    .font(appTheme.typography.timerMessage).fixedSize(horizontal: false, vertical: true)
                Label(store.active?.mode.displayName ?? "", systemImage: "timer").font(appTheme.typography.legacyCallout).foregroundStyle(appTheme.palette.textSecondary)
            }
            SessionControls()
            Text(store.active?.isBreak == true ? L10n.tr("La prossima sessione partirà quando lo decidi tu.") : L10n.tr("Al termine, il tuo tempo viene salvato nell’archivio."))
                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary).fixedSize(horizontal: false, vertical: true)
            if let message = store.statusMessage {
                Label(L10n.message(message), systemImage: "info.circle").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion), value: store.stateText)
    }
}
struct SessionControls: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var fromMenu = false
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.legacy9) {
            Button { store.toggle() } label: {
                Label(store.actionTitle, systemImage: store.active != nil && store.active?.pausedAt == nil ? "pause.fill" : "play.fill")
                    .font(appTheme.typography.control)
                    .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.Spacing.legacy6)
            }.buttonStyle(StudyActionStyle()).disabled(store.active == nil && store.activeSubjects.isEmpty)
                .help(store.active == nil && store.activeSubjects.isEmpty ? L10n.tr("Aggiungi o riapri una materia per iniziare") : store.actionTitle)
            if let active = store.active {
                Button(active.isBreak ? L10n.tr("Salta pausa") : L10n.tr("Termina e salva")) {
                    if active.isBreak { store.skipBreak() } else { store.finish(fromMenu: fromMenu) }
                }.frame(maxWidth: .infinity)
            }
        }
    }
}
struct TimerSetup: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy14) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy6) {
                Text(L10n.tr("Materia")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                StudyDropdown(title: L10n.tr("Materia"), options: store.activeSubjectChoices, selection: Binding(get: { store.preparedSubject?.id }, set: { store.chooseSubject($0) })).frame(maxWidth: .infinity)
                if store.activeSubjects.isEmpty { NoActiveSubjects() }
            }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy6) {
                Text(L10n.tr("Modalità")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                if compact {
                    modePicker
                } else {
                    PastelSegmentedControl(L10n.tr("Modalità"), values: TimerMode.allCases, selection: Binding(get: { store.preparedMode }, set: { store.chooseMode($0) })) { $0.displayName }
                }
            }
            if store.preparedMode == .pomodoro {
                HStack {
                    Text(L10n.tr("Studio")).foregroundStyle(appTheme.palette.textSecondary)
                    Spacer()
                    StudyNumberField(title: L10n.tr("Minuti di studio"), value: $store.settings.pomodoroDuration).frame(width: DesignSystem.TimerLayout.studyField).multilineTextAlignment(.trailing)
                    Text("min").foregroundStyle(appTheme.palette.textSecondary)
                }.font(appTheme.typography.legacyCallout)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach([25, 50, 90], id: \.self) { minutes in
                        DurationChip(minutes: minutes, value: $store.settings.pomodoroDuration)
                    }
                }
                if !compact {
                    Text(L10n.tr("Pausa breve: %@ · lunga ogni %@ sessioni" , String(describing: durationText(store.settings.shortBreakDuration * 60)), String(describing: store.settings.longBreakEvery)))
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            } else if store.preparedMode == .custom {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    HStack { Text(L10n.tr("Studio")); Spacer(); StudyNumberField(title: L10n.tr("Minuti di studio"), value: $store.settings.customMinutes, range: 1...1440).frame(width: DesignSystem.TimerLayout.studyField) }
                    HStack { Text(L10n.tr("Pausa")); Spacer(); StudyNumberField(title: L10n.tr("Minuti di pausa"), value: $store.settings.customBreak, range: 0...360).frame(width: DesignSystem.TimerLayout.studyField) }
                }.font(appTheme.typography.caption)
            } else {
                Text(L10n.tr("Senza conto alla rovescia. Termina quando vuoi.")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }
    }
    var modePicker: some View {
        StudyDropdown(title: L10n.tr("Modalità"), options: TimerMode.allCases.map { ($0, $0.displayName) }, selection: Binding(get: { store.preparedMode }, set: { store.chooseMode($0) })).frame(maxWidth: .infinity)
    }
}
struct TimerFace: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    var minimal = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiSectionVisible) private var visible
    @Environment(\.komorebiRendering) private var rendering
    @EnvironmentObject var store: StudyStore
    var target: Double? { store.active.map { $0.target } ?? store.preparedTarget }
    var color: Color { store.active?.isBreak == true ? appTheme.palette.interval : appTheme.palette.accent }
    func time(at date: Date) -> String { store.active.map { clockText($0.displayed(at: date)) } ?? clockText(store.preparedTarget ?? 0) }
    @ViewBuilder private func timerTime(_ time: String) -> some View {
        if appTheme.cifreCellaFissa {
            ThemeFixedTimerDigits(text: time, pointSize: appTheme.typography.timerPointSize)
        } else {
            Text(time).font(appTheme.typography.timerDigits)
                .contentTransition(.numericText()).minimumScaleFactor(DesignSystem.TimerLayout.minimumDigitScale).lineLimit(1)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.legacy18) {
            Text(store.active?.subjectName ?? store.preparedSubject?.name ?? L10n.tr("Studio"))
                .font(appTheme.typography.timerSubject).lineLimit(2).multilineTextAlignment(.center)
            LiveStudyTime { date in
            let time = time(at: date)
            GeometryReader { geometry in
                ZStack {
                    TimerProgressRing(value: store.active?.elapsed(at: date) ?? 0, total: target, running: store.studying)
                        .modifier(TimerRingMotion(running: store.studying, completion: store.completionPulse))
                    timerTime(time)
                        .foregroundStyle(appTheme.palette.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .animation(interfaceAnimation(store.settings.animations, reduceMotion: reduceMotion || !visible || !rendering.visible), value: time)
                        .accessibilityLabel(L10n.tr("Tempo")).accessibilityValue(time)
                    if !minimal { VStack {
                        Image(systemName: store.active?.isBreak == true ? "cup.and.saucer" : store.studying ? "book" : "book.closed")
                            .font(appTheme.typography.timerSymbol).foregroundStyle(color)
                            .opacity(DesignSystem.TimerLayout.symbolOpacity).accessibilityHidden(true)
                        Spacer()
                        Text(target == nil ? L10n.tr("tempo trascorso") : store.active?.isBreak == true ? L10n.tr("tempo di pausa") : L10n.tr("tempo rimanente"))
                            .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, geometry.size.height * DesignSystem.TimerLayout.faceInsetRatio)
                    }
                }
            }.aspectRatio(1, contentMode: .fit)
            }
            if !minimal && store.active?.mode == .pomodoro {
                Text(L10n.tr("Pomodoro %@" , String(describing: store.cycles + (store.active?.isBreak == true ? 0 : 1)))).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }
        }
    }
}
struct FocusView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @StateObject private var activity = FocusControlsActivity()
    @Environment(\.komorebiRendering) private var rendering
    private enum FocusControl: Hashable { case exitTop, pause, exitBottom }
    @FocusState private var controlFocused: FocusControl?
    @FocusState private var surfaceFocused: Bool
    private var visible: Bool { activity.controlsVisible || controlFocused != nil || voiceOver }
    var body: some View {
        ZStack {
            Landscape(theme: store.settings.landscape, animations: store.settings.animations, driftingLight: true).ignoresSafeArea()
            TimerFace(minimal: true).frame(maxWidth: DesignSystem.PreservedGeometry.points360).padding(DesignSystem.Spacing.xxl)
            VStack {
                HStack {
                    Spacer()
                    Button(L10n.tr("Esci da Focus"), systemImage: "arrow.down.right.and.arrow.up.left", action: exitFocus)
                        .keyboardShortcut(.escape, modifiers: [])
                        .focused($controlFocused, equals: .exitTop)
                }
                Spacer()
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button(store.actionTitle, systemImage: store.studying ? "pause.fill" : "play.fill") { store.toggle() }
                        .buttonStyle(StudyActionStyle()).focused($controlFocused, equals: .pause)
                    Button(L10n.tr("Esci"), action: exitFocus).focused($controlFocused, equals: .exitBottom)
                }
            }.padding(DesignSystem.Spacing.xxl)
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(visible)
                // Keep controls in the keyboard and VoiceOver traversal even when visually hidden.
                .animation(reduceMotion || store.settings.animations == "Off" ? nil : .easeOut(duration: DesignSystem.Interaction.sectionDuration), value: visible)
        }.contentShape(Rectangle())
            .focusable().focusEffectDisabled().focused($surfaceFocused)
            .onAppear { surfaceFocused = true; activity.noteMovement() }
            .onKeyPress(.escape) { exitFocus(); return .handled }
            .onKeyPress(.tab) { activity.noteMovement(); return .ignored }
            .onContinuousHover { phase in
                if case .active = phase, rendering.visible { activity.noteMovement() }
            }
            .onChange(of: rendering.visible) { _, visible in
                if visible { activity.noteMovement() } else { activity.stop() }
            }
            .onDisappear { activity.stop() }
            .onExitCommand(perform: exitFocus)
    }
    private func exitFocus() {
        store.focus = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == true { NSApp.keyWindow?.toggleFullScreen(nil) }
    }
}
struct CompletionView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    let session: StudySession
    @State private var note = ""
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "leaf.fill").font(appTheme.preservedTypography.completionSymbol).foregroundStyle(appTheme.palette.accent)
            Text(L10n.tr("Sessione salvata")).font(appTheme.preservedTypography.completionTitle)
            Text("\(session.subjectName) · \(durationText(session.duration))").font(appTheme.preservedTypography.title3)
            Text(L10n.tr("Oggi %@ · Settimana %@" , String(describing: durationText(store.liveToday)), String(describing: durationText(store.liveWeekly)))).foregroundStyle(appTheme.palette.textSecondary)
            StudyTextEntry(L10n.tr("Nota della sessione…"), text: $note, axis: .vertical).interactiveHover(textEntry: true).lineLimit(3...5).textFieldStyle(StudyTextFieldStyle())
            Button(L10n.tr("Continua")) { session.note = note; if store.save() { store.completed = nil } }.buttonStyle(ResponsiveButtonStyle(prominent: true)).keyboardShortcut(.defaultAction)
        }.padding(DesignSystem.PreservedGeometry.gap36).frame(width: DesignSystem.PreservedGeometry.points440).onAppear { note = session.note }
    }
}
struct OnboardingView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "leaf").font(appTheme.preservedTypography.welcomeSymbol).foregroundStyle(appTheme.palette.accent)
            Text(ProductText.welcome).font(appTheme.preservedTypography.pageTitle)
            Text(L10n.tr("Il tempo delle sessioni viene salvato automaticamente.")).multilineTextAlignment(.center).lineSpacing(DesignSystem.Spacing.xs)
            Text(L10n.tr("Obiettivo giornaliero")).font(appTheme.preservedTypography.headline)
            HStack { ForEach([2,3,4], id: \.self) { h in Button(L10n.count(h, singular: "%@ ora", plural: "%@ ore")) { store.settings.dailyGoal = Double(h) } } }
            HStack { Text(L10n.tr("Obiettivo in ore")); StudyNumberField(title: L10n.tr("Ore"), value: $store.settings.dailyGoal).frame(width: DesignSystem.TimerLayout.studyField) }
            Button(L10n.tr("Apri app")) {
                store.settings.dailyGoal = store.settings.dailyGoal.isFinite && store.settings.dailyGoal > 0 ? min(24, max(0.25, store.settings.dailyGoal)) : 3.0
                store.settings.onboarded = true
            }.buttonStyle(ResponsiveButtonStyle(prominent: true)).controlSize(.large)
            Text(L10n.tr("Offline. Nessun account. Solo il tuo Mac.")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
        }.padding(DesignSystem.PreservedGeometry.gap40).frame(width: DesignSystem.PreservedGeometry.points480)
    }
}

struct OverviewView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var openTimer: () -> Void
    var openCalendar: () -> Void
    var openThemeSettings: () -> Void
    var upcoming: [StudyExam] { store.homeExams.filter { $0.date >= store.day.start } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy7) {
                        Text(L10n.tr("Riepilogo")).font(appTheme.preservedTypography.homeTitle)
                        PersonalPhrase(slot: .home)
                    }
                    Spacer()
                    HomeExamCountdown(exams: store.homeExams, date: store.now, streak: store.streak)
                        .frame(maxWidth: DesignSystem.PreservedGeometry.points280, alignment: .trailing)
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
                        Text(L10n.tr("Obiettivo settimanale")).font(appTheme.preservedTypography.homeCardTitle)
                        Spacer()
                        GoalEditButton().labelStyle(.iconOnly).help(L10n.tr("Modifica obiettivi"))
                    }
                    LiveStudyTime { _ in GoalBar(title: L10n.tr("Questa settimana"), value: store.weeklyGoalProgress, goal: store.settings.weeklyGoal * 3600) }
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
            Text(store.active == nil ? L10n.tr("Sessione") : store.active?.subjectName ?? L10n.tr("Sessione"))
                .font(appTheme.preservedTypography.editorTitle).fixedSize(horizontal: false, vertical: true)
            if store.active == nil {
                StudyDropdown(title: L10n.tr("Materia"), options: store.activeSubjectChoices, selection: Binding(get: { store.preparedSubject?.id }, set: { store.chooseSubject($0) }))
                if store.activeSubjects.isEmpty { NoActiveSubjects() }
                Label(store.preparedSummary, systemImage: "timer").font(appTheme.preservedTypography.callout).foregroundStyle(appTheme.palette.textSecondary)
                HStack {
                    Button {
                        store.start(); if store.active != nil { openTimer() }
                    } label: { Label(L10n.tr("Inizia a studiare"), systemImage: "play.fill").padding(.vertical, DesignSystem.Spacing.xxs) }
                        .buttonStyle(StudyActionStyle()).disabled(store.activeSubjects.isEmpty)
                        .help(store.activeSubjects.isEmpty ? L10n.tr("Aggiungi o riapri una materia per iniziare") : L10n.tr("Inizia a studiare"))
                    Button(L10n.tr("Configura"), action: openTimer)
                }
            } else {
                LiveStudyTime { date in
                    Text(store.active.map { clockText($0.displayed(at: date)) } ?? "")
                        .font(appTheme.preservedTypography.homeTimerValue).monospacedDigit()
                }
                HStack {
                    Button(L10n.tr("Torna alla sessione"), action: openTimer).buttonStyle(ResponsiveButtonStyle(prominent: true))
                    Button(store.actionTitle) { store.toggle() }
                }
            }
        }
    }
    var upcomingCard: some View {
        Card(stretches: true) {
            HStack {
                Text(L10n.tr("Prossimi esami")).font(appTheme.preservedTypography.homeCardTitle)
                Spacer()
                Button(action: openCalendar) { Image(systemName: "arrow.up.right") }.help(L10n.tr("Apri calendario")).accessibilityLabel(L10n.tr("Apri calendario"))
            }
            if upcoming.isEmpty {
                Text(L10n.tr("Nessun esame programmato.")).foregroundStyle(appTheme.palette.textSecondary)
                Button(L10n.tr("Aggiungi dal calendario"), action: openCalendar)
            }
            ForEach(Array(upcoming.prefix(2))) { exam in ExamRow(exam: exam) }
        }
    }
    var recentCard: some View {
        Card(stretches: true) {
            Text(L10n.tr("Ultime sessioni")).font(appTheme.preservedTypography.homeCardTitle)
            if store.sessions.isEmpty { Text(L10n.tr("Le sessioni salvate appariranno qui.")).foregroundStyle(appTheme.palette.textSecondary) }
            ForEach(Array(store.sessions.prefix(2))) { session in SessionRow(session: session) }
        }
    }
}
struct DailyGoalCard: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    var stretches = false
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var goal: Double { store.settings.dailyGoal * 3600 }
    var body: some View {
        Card(stretches: stretches) {
            LiveStudyTime { _ in
            HStack { Text(L10n.tr("Obiettivo giornaliero")).font(appTheme.preservedTypography.headline); Spacer() }
            VStack(spacing: 0) {
                if stretches { Spacer(minLength: 0) }
                ZStack {
                ProgressRing(value: store.liveToday, total: goal)
                VStack(spacing: DesignSystem.PreservedGeometry.gap5) {
                    Text(durationText(store.liveToday)).font(appTheme.preservedTypography.dailyGoalValue).monospacedDigit()
                    Text(L10n.tr("di %@" , String(describing: durationText(goal)))).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            }.frame(width: DesignSystem.PreservedGeometry.points132, height: DesignSystem.PreservedGeometry.points132).frame(maxWidth: .infinity).padding(.vertical, DesignSystem.PreservedGeometry.gap3)
                if stretches { Spacer(minLength: 0) }
            }.frame(maxHeight: stretches ? .infinity : nil)
            Text(store.liveToday >= goal ? L10n.tr("Obiettivo raggiunto.") : L10n.tr("Tempo rimanente: %@" , String(describing: durationText(goal - store.liveToday))))
                .font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary).frame(maxWidth: .infinity, alignment: .center)
            PersonalPhrase(slot: .dailyGoal).frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

/// No fallback slogans or periodic rotation: empty preferences render no extra view.
struct PersonalPhrase: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    let slot: PersonalPhraseSlot
    var body: some View {
        if let phrase = store.settings.personalPhrase(for: slot) {
            Text(verbatim: phrase).font(theme.typography.caption).lineLimit(3)
                .help(phrase).accessibilityLabel(phrase)
                .foregroundStyle(theme.palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

private struct ThemeSuggestionCard: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
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
                    Text(L10n.tr("Prova il tema ") + campaign.package.name).font(appTheme.typography.heading)
                    Text(L10n.tr(campaign.package.subtitle)).font(appTheme.typography.small).foregroundStyle(appTheme.palette.textSecondary)
                    Button(L10n.tr("Apri le impostazioni del tema"), action: open)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Button(action: dismiss) { Image(systemName: "xmark").frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight).contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control)) }
                    .accessibilityLabel(L10n.tr("Chiudi suggerimento del tema ") + campaign.package.name)
            }
        }
    }
}


/// Mouse positions are not view state. Only show/hide transitions invalidate Focus.
/// One sleeping task follows a monotonic deadline instead of being cancelled/recreated
/// for every mouse event. Keyboard focus and VoiceOver remain independent visibility reasons.
@MainActor final class FocusControlsActivity: ObservableObject {
    @Published private(set) var controlsVisible = true
    private let clock = ContinuousClock()
    private let timeout: Duration
    private var deadline = ContinuousClock.now
    private var hideTask: Task<Void, Never>?
    init(timeout: Duration = .nanoseconds(Int64(DesignSystem.Interaction.controlsTimeout))) { self.timeout = timeout }
    func noteMovement() {
        deadline = clock.now.advanced(by: timeout)
        if !controlsVisible { controlsVisible = true }
        guard hideTask == nil else { return }
        let clock = clock
        hideTask = Task { [weak self] in
            while let deadline = self?.deadline {
                do { try await clock.sleep(until: deadline) } catch { return }
                guard !Task.isCancelled, let self else { return }
                if clock.now >= self.deadline {
                    self.controlsVisible = false
                    self.hideTask = nil
                    return
                }
            }
        }
    }
    func stop() { hideTask?.cancel(); hideTask = nil }
    deinit { hideTask?.cancel() }
}

/// Uses local calendar days (not 24-hour divisions), so DST does not shift the countdown.
/// Like the existing upcoming-exams card, exams remain current throughout their calendar day.
struct NextExamCountdown {
    let id: UUID
    let title: String
    let date: Date
    let days: Int
    static func nearest(in exams: [StudyExam], at date: Date, calendar: Calendar = .current) -> NextExamCountdown? {
        let today = calendar.startOfDay(for: date)
        guard let next = exams.filter({ calendar.startOfDay(for: $0.date) >= today }).min(by: {
            $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date
        }) else { return nil }
        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next.date)).day ?? 0
        return NextExamCountdown(id: next.id, title: next.title, date: next.date, days: days)
    }
    var countdownText: String {
        switch days {
        case 0: return L10n.tr("Esame oggi")
        case 1: return L10n.tr("Esame domani")
        default: return L10n.tr("Esame tra %@ giorni", String(days))
        }
    }
}

struct HomeExamCountdown: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    let exams: [StudyExam]
    let date: Date
    let streak: Int
    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
            if let next = NextExamCountdown.nearest(in: exams, at: date) {
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    Text(next.countdownText).font(theme.typography.small).foregroundStyle(theme.palette.accent)
                    Text(verbatim: next.title).font(theme.preservedTypography.caption)
                        .foregroundStyle(theme.palette.textSecondary).lineLimit(2)
                }.multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .help(next.title + " · " + L10n.date(next.date))
            }
            if streak > 0 {
                Text(theme.copy.streak(streak)).font(theme.preservedTypography.caption)
                    .foregroundStyle(theme.palette.accent)
            }
        }.padding(.top, DesignSystem.Spacing.xs)
    }
}

/// Used by Home, Timer and MenuPanel's shared TimerSetup; no duplicated eligibility filters.
struct NoActiveSubjects: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(L10n.tr("Nessuna materia da completare")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            Text(L10n.tr("Aggiungi o riapri una materia per iniziare")).font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            Button(L10n.tr("Aggiungi una materia")) {
                store.openSubjects = true
                openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
