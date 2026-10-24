import SwiftUI

struct SettingsView: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var revealTheme: Bool
    @EnvironmentObject var store: StudyStore
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedback: String?
    @State private var feedbackRevision = 0
    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(L10n.tr("Impostazioni")).font(appTheme.typography.title)
                        Text(L10n.tr("Preferenze dell’app.")).foregroundStyle(appTheme.palette.textSecondary)
                    }
                    Spacer()
                    Label(feedback ?? L10n.tr("Salvato"), systemImage: "checkmark.circle")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.accent)
                        .opacity(feedback == nil ? 0 : 1).accessibilityHidden(feedback == nil)
                }
                SettingsCard(title: L10n.tr("Lingua")) {
                    SettingRow(L10n.tr("Lingua dell’app"), detail: L10n.tr("La lingua dell’app cambia subito. Alcuni pannelli di macOS richiedono il riavvio dell’app."), width: DesignSystem.SettingsLayout.dropdownWidth) {
                        StudyDropdown(title: L10n.tr("Lingua dell’app"), options: AppLanguage.allCases.map { ($0.rawValue, $0.name) }, selection: Binding(get: { store.settings.appLanguage.rawValue }, set: { store.settings.language = $0 }))
                    }
                }
                PersonalPhrasesSettings()
                SettingsCard(title: L10n.tr("Obiettivi")) {
                    SettingRow(L10n.tr("Obiettivo giornaliero"), detail: L10n.tr("Ore di studio al giorno.")) {
                        StudyNumberField(title: L10n.tr("Obiettivo giornaliero in ore"), value: $store.settings.dailyGoal, range: 0.25...24, step: 0.25)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Obiettivo settimanale"), detail: L10n.tr("Ore di studio alla settimana.")) {
                        StudyNumberField(title: L10n.tr("Obiettivo settimanale in ore"), value: $store.settings.weeklyGoal, range: 0.25...168, step: 0.25)
                    }
                    settingDivider
                    Toggle(L10n.tr("Per la serie, richiedi l’obiettivo giornaliero"), isOn: $store.settings.streakUsesGoal)
                    if !store.settings.streakUsesGoal {
                        SettingRow(L10n.tr("Minuti per completare un giorno"), detail: L10n.tr("Durata minima giornaliera per il conteggio della serie.")) {
                            StudyNumberField(title: L10n.tr("Minuti per completare un giorno"), value: $store.settings.streakMinutes, range: 1...1440)
                        }
                    }
                }
                SettingsCard(title: "Pomodoro") {
                    SettingRow(L10n.tr("Studio"), detail: L10n.tr("Minuti per ogni sessione.")) {
                        StudyNumberField(title: L10n.tr("Minuti di studio Pomodoro"), value: $store.settings.pomodoroDuration, range: 1...600)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Pausa breve"), detail: L10n.tr("Minuti tra una sessione e l’altra.")) {
                        StudyNumberField(title: L10n.tr("Minuti di pausa breve"), value: $store.settings.shortBreakDuration, range: 1...120)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Pausa lunga"), detail: L10n.tr("Durata della pausa lunga.")) {
                        StudyNumberField(title: L10n.tr("Minuti di pausa lunga"), value: $store.settings.longBreakDuration, range: 1...180)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Pausa lunga ogni N sessioni"), detail: L10n.tr("Scegli quante sessioni completare prima della pausa lunga.")) {
                        StudyNumberField(title: L10n.tr("Sessioni prima della pausa lunga"), value: Binding(get: { Double(store.settings.longBreakEvery) }, set: { if $0.isFinite { store.settings.longBreakEvery = Int(min(12, max(1, $0))) } }), range: 1...12)
                    }
                    Text(L10n.tr("Le nuove durate si applicano al prossimo timer. Le pause si avviano manualmente."))
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                SettingsCard(title:L10n.tr("Pause per unità")) {
                    SettingRow(L10n.tr("Frazione del tempo studiato"),detail:L10n.tr("0,2 corrisponde a 1/5 del tempo di studio.")) {
                        StudyNumberField(title:L10n.tr("Frazione del tempo studiato"),value:Binding(get:{ store.settings.unitBreakFraction ?? 0.2 },set:{ store.settings.unitBreakFraction=$0 }),range:0.01...1,step:0.01)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Pausa minima"),detail:L10n.tr("Minuti")) {
                        StudyNumberField(title:L10n.tr("Pausa minima"),value:Binding(get:{ store.settings.unitBreakMinimum ?? 5 },set:{ store.settings.unitBreakMinimum=$0 }),range:1...180)
                    }
                    settingDivider
                    SettingRow(L10n.tr("Pausa massima"),detail:L10n.tr("Minuti")) {
                        StudyNumberField(title:L10n.tr("Pausa massima"),value:Binding(get:{ max(store.settings.unitBreakMinimum ?? 5,store.settings.unitBreakMaximum ?? 20) },set:{ store.settings.unitBreakMaximum=$0 }),range:max(1,store.settings.unitBreakMinimum ?? 5)...180)
                    }
                }
                SettingsCard(title: L10n.tr("Tema")) {
                    SettingRow(L10n.tr("Modalità"), detail: L10n.tr("Aspetto chiaro, scuro o di sistema."), width: DesignSystem.SettingsLayout.segmentWidth) {
                        PastelSegmentedControl(L10n.tr("Modalità"), values: ["Light", "Dark", "System"], selection: $store.settings.appearance) { $0 == "Light" ? L10n.tr("Chiaro") : $0 == "Dark" ? L10n.tr("Scuro") : L10n.tr("Sistema") }
                    }
                    settingDivider
                    ThemePicker(selection: Binding(get: { store.settings.themeID }, set: { store.selectTheme($0) }))
                    ForEach(appTheme.package.options) { option in
                        settingDivider
                        Toggle(isOn: Binding(get: {
                            store.settings.themeOptions?[appTheme.package.id]?[option.id] ?? option.defaultValue
                        }, set: { value in
                            var options = store.settings.themeOptions ?? [:]
                            options[appTheme.package.id, default: [:]][option.id] = value
                            store.settings.themeOptions = options
                        })) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Text(L10n.tr(option.title))
                                Text(L10n.tr(option.detail)).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                            }
                        }.accessibilityLabel(L10n.tr(option.title)).accessibilityHint(L10n.tr(option.detail))
                    }
                }
                .id(ThemeSettingsAnchor.theme)
                SettingsCard(title: L10n.tr("Ambiente")) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text(L10n.tr("Paesaggio")).font(appTheme.typography.small)
                        Text(L10n.tr("Sfondo del timer.")).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        if appTheme.package.behavior.replacesLandscapes {
                            Text(L10n.tr("Con il tema %@ attivo, il paesaggio è sostituito." , String(describing: appTheme.package.name)))
                                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        } else { ScenePicker(selection: $store.settings.landscape) }
                    }
                    settingDivider
                    SettingRow(L10n.tr("Animazioni"), detail: L10n.tr("Le preferenze di accessibilità del Mac hanno sempre la precedenza."), width: DesignSystem.SettingsLayout.dropdownWidth) {
                        StudyDropdown(title: L10n.tr("Animazioni"), options: [("Off", L10n.tr("Disattivate")), ("Reduced", L10n.tr("Delicate")), ("Full", L10n.tr("Complete"))], selection: $store.settings.animations)
                    }
                    settingDivider
                    SettingsAmbientRows(audio: store.audio, onApply: { signal(L10n.tr("Applicato")) })
                }
                SettingsCard(title: L10n.tr("Notifiche")) {
                    Toggle(L10n.tr("Avvisi di fine sessione"), isOn: Binding(get: { store.settings.notifications }, set: { on in if on { store.requestNotifications() } else { store.settings.notifications = false; store.scheduleNotification() } }))
                    settingDivider
                    Toggle(L10n.tr("Suono di fine timer"), isOn: $store.settings.sounds).onChange(of: store.settings.sounds) { store.scheduleNotification() }
                }
                SettingsCard(title: L10n.tr("Dati e privacy")) {
                    Text(L10n.tr("Tutto rimane su questo Mac. Nessun account, pubblicità o servizio di analisi."))
                        .foregroundStyle(appTheme.palette.textSecondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DesignSystem.Spacing.sm) { archiveActions }
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) { archiveActions }
                    }
                    Text(L10n.tr("L’importazione aggiunge i record mancanti senza cancellare quelli esistenti. Termina prima il timer attivo."))
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                SettingsCard(title: L10n.tr("Tastiera")) {
                    shortcut(L10n.tr("Avvia, sospendi o riprendi"), keys: "⌘ ⇧ P")
                    settingDivider
                    shortcut(L10n.tr("Avvia una sessione"), keys: L10n.tr("⌘ Invio"))
                    settingDivider
                    shortcut(L10n.tr("Termina e salva"), keys: "⌘ .")
                }
                SettingsCard(title: L10n.tr("Timer e barra dei menu")) {
                    Toggle(L10n.tr("Sospendi automaticamente durante lo stop"), isOn: $store.pauseOnSleep)
                    settingDivider
                    Toggle(L10n.tr("Mostra il tempo nella barra dei menu"), isOn: $store.showMenuTime)
                    Text(L10n.tr("Le nuove sessioni registrano gli intervalli effettivi di studio. Quelle precedenti o corrette manualmente mantengono il conteggio proporzionale tra i giorni."))
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            }
            .padding(DesignSystem.Layout.contentPadding)
            .frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.top, for: .initialOffset)
        .background(appTheme.palette.background)
        .toggleStyle(StudyToggleStyle())
        .onChange(of: store.settings) { signal(L10n.tr("Salvato")) }
        .onChange(of: store.pauseOnSleep) { signal(L10n.tr("Salvato")) }
        .onChange(of: store.showMenuTime) { signal(L10n.tr("Salvato")) }
        .task(id: feedbackRevision) {
            guard feedback != nil else { return }
            do { try await Task.sleep(nanoseconds: 1_800_000_000) } catch { return }
            feedback = nil
        }
        .animation(reduceMotion || motion == "Off" ? nil : .easeOut(duration: DesignSystem.Interaction.hoverDuration), value: feedback)
        .onChange(of: revealTheme) { if revealTheme { proxy.scrollTo(ThemeSettingsAnchor.theme, anchor: .top); revealTheme = false } }
        }
    }
    private var settingDivider: some View { Rectangle().fill(appTheme.palette.border.opacity(appTheme.appearance.opacity0_22)).frame(height: DesignSystem.Layout.dividerWidth).allowsHitTesting(false) }
    @ViewBuilder private var archiveActions: some View {
        Button(L10n.tr("Esporta CSV")) { store.export(csv: true) }
        Button(L10n.tr("Backup JSON")) { store.export(csv: false) }
        Button(L10n.tr("Importa backup")) { store.restore() }.disabled(store.active != nil)
    }
    private func shortcut(_ title: String, keys: String) -> some View {
        HStack { Text(title); Spacer(); Text(keys).font(appTheme.typography.small).foregroundStyle(appTheme.palette.textSecondary) }
    }
    private func signal(_ message: String) { guard sectionVisible else { return }; feedback = message; feedbackRevision += 1 }
}
struct SettingRow<Control: View>: View {
    @Environment(\.studyTheme) private var appTheme
    let title: String
    var detail: String?
    var width: CGFloat
    @ViewBuilder var control: Control
    init(_ title: String, detail: String? = nil, width: CGFloat = DesignSystem.TimerLayout.studyField, @ViewBuilder control: () -> Control) {
        self.title = title; self.detail = detail; self.width = width; self.control = control()
    }
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(title).font(appTheme.typography.small)
                if let detail { Text(detail).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary) }
            }.frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            control.frame(width: width)
        }.frame(minHeight: DesignSystem.Interaction.controlHeight)
    }
}
struct SettingsCard<Content: View>: View {
    @Environment(\.studyTheme) private var appTheme
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Card {
            Text(title).font(appTheme.typography.heading)
            content
        }.shadow(color: appTheme.shadows.low.color.opacity(scheme == .dark ? 0 : 1), radius: appTheme.shadows.low.radius, y: appTheme.shadows.low.y)
    }
}
struct ScenePicker: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var selection: String
    private let scenes = [("Morning", "Mattino"), ("Forest", "Bosco"), ("Rain", "Pioggia"), ("Sunset", "Tramonto"), ("Night", "Notte")]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xs), count: 5), spacing: DesignSystem.Spacing.xs) {
            ForEach(scenes, id: \.0) { id, name in
                Button { selection = id } label: {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ZStack {
                            Landscape(theme: id, animations: "Off").allowsHitTesting(false)
                            Image(systemName: id == "Night" ? "moon" : id == "Rain" ? "cloud.rain" : id == "Forest" ? "leaf" : id == "Sunset" ? "sun.haze" : "sun.max")
                                .font(appTheme.typography.heading).foregroundStyle(appTheme.palette.accent)
                        }.frame(height: DesignSystem.Interaction.controlHeight).clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                        Text(L10n.tr(name)).font(appTheme.typography.caption).lineLimit(1).foregroundStyle(appTheme.palette.textPrimary)
                    }.padding(DesignSystem.Spacing.xs).frame(maxWidth: .infinity)
                        .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                        .overlay(StudySelectionBorder(selected: selection == id, color: appTheme.palette.accent, normalColor: appTheme.palette.border, radius: DesignSystem.Radius.card))
                        .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                }.buttonStyle(.plain).interactiveHover(cornerRadius: DesignSystem.Radius.card, selected: selection == id)
                    .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card))
                    .accessibilityLabel(L10n.tr("Paesaggio ") + L10n.tr(name)).accessibilityAddTraits(selection == id ? .isSelected : [])
            }
        }
    }
}

struct GoalEditButton: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @State private var showing = false
    var body: some View {
        Button(L10n.tr("Modifica obiettivi"), systemImage: "pencil") { showing = true }
            .sheet(isPresented: $showing) { GoalEditor() }
    }
}
struct GoalEditor: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    @State private var daily = 3.0
    @State private var weekly = 15.0
    var valid: Bool { daily.isFinite && weekly.isFinite && (0.25...24).contains(daily) && (0.25...168).contains(weekly) }
    var body: some View {
        Form {
            Text(L10n.tr("Obiettivi di studio")).font(appTheme.preservedTypography.title2)
            StudyNumberField(title: L10n.tr("Ore al giorno"), value: $daily)
            StudyNumberField(title: L10n.tr("Ore alla settimana"), value: $weekly)
            Text(L10n.tr("Puoi usare valori decimali, per esempio 2,5 ore. I nuovi obiettivi si applicano ai progressi correnti.")).font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
            if !valid { Text(L10n.tr("Giornaliero: da 0,25 a 24 ore. Settimanale: da 0,25 a 168 ore.")).foregroundStyle(appTheme.appearance.destructiveInk).font(appTheme.preservedTypography.caption) }
            HStack { Button(L10n.tr("Annulla")) { dismiss() }; Spacer(); Button(L10n.tr("Salva")) { store.settings.dailyGoal = daily; store.settings.weeklyGoal = weekly; dismiss() }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(!valid) }
        }.padding(DesignSystem.PreservedGeometry.gap28).frame(width: DesignSystem.PreservedGeometry.points420).onAppear { daily = store.settings.dailyGoal; weekly = store.settings.weeklyGoal }
    }
}

private struct SettingsAmbientRows: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @ObservedObject var audio: AmbientAudio
    let onApply: () -> Void
    var body: some View {
        Group {
            SettingRow(L10n.tr("Suono ambiente"), detail: L10n.tr("Suoni sintetizzati, senza registrazioni esterne."), width: DesignSystem.SettingsLayout.dropdownWidth) {
                StudyDropdown(title: L10n.tr("Suono ambiente"), options: [("Off", L10n.tr("Silenzio")), ("Pioggia", L10n.tr("Pioggia")), ("Vento", L10n.tr("Vento")), ("Camino", L10n.tr("Camino"))], selection: $audio.sound)
            }
            SettingRow(L10n.tr("Volume ambiente"), width: DesignSystem.SettingsLayout.dropdownWidth) {
                StudyVolumeSlider(value: $audio.volume)
            }
        }.onChange(of: audio.sound) { onApply() }.onChange(of: audio.volume) { onApply() }
    }
}

/// A static preview uses each package directly; no timer is created or restarted.
private struct ThemePicker: View {
    @Environment(\.studyTheme) private var appTheme
    @Binding var selection: String?
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: DesignSystem.ThemeLayout.previewWidth), alignment: .leading)], alignment: .leading, spacing: DesignSystem.Spacing.md) {
            ForEach(ThemeRegistry.packages) { package in
                ThemePreviewCard(package: package, selected: ThemeRegistry.package(selection).id == package.id) { selection = package.id }
            }
        }
    }
}
private struct ThemePreviewCard: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @FocusState private var focused: Bool
    let package: ThemePackage
    let selected: Bool
    let action: () -> Void
    private var preview: ResolvedTheme { package.resolve(mode: appTheme.mode) }
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ThemeTimerPreview(preview: preview)
                Text(package.name).font(appTheme.typography.heading).foregroundStyle(appTheme.palette.textPrimary)
                Text(L10n.tr(package.subtitle)).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }.padding(DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .overlay(StudySelectionBorder(selected: selected, color: appTheme.palette.accent, normalColor: appTheme.palette.border, radius: DesignSystem.Radius.card, explicitFocus: focused))
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }.buttonStyle(.plain).focusable().focusEffectDisabled().focused($focused)
            .onKeyPress(.return) { action(); return .handled }
            .onKeyPress(.space) { action(); return .handled }
            .interactiveHover(cornerRadius: DesignSystem.Radius.card, selected: selected)
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card, explicitFocus: focused))
            .accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton).accessibilityLabel(L10n.tr("Tema ") + package.name)
            .accessibilityValue(L10n.tr(package.subtitle)).accessibilityAddTraits(selected ? .isSelected : [])
    }
}

enum ThemeSettingsAnchor { case theme }
struct ThemeTimerPreview: View {
    let preview: ResolvedTheme
    var body: some View {
ZStack {
                    preview.palette.background
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ZStack {
                            Circle().stroke(preview.palette.timerTrack, lineWidth: DesignSystem.ThemeLayout.previewRingWidth)
                            Circle().trim(from: 0, to: DesignSystem.PreservedAppearance.opacity0_76)
                                .stroke(LinearGradient(colors: [preview.palette.timerGradientStart, preview.palette.timerGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: DesignSystem.ThemeLayout.previewRingWidth, lineCap: .round))
                                .rotationEffect(.degrees(preview.decoration.ringRotation))
                            Text("50:00").font(preview.typography.timerSubject).monospacedDigit().foregroundStyle(preview.palette.textPrimary)
                        }.frame(width: DesignSystem.ThemeLayout.previewRing, height: DesignSystem.ThemeLayout.previewRing)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.control).fill(preview.palette.accentSurface).frame(height: DesignSystem.Spacing.sm)
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.control).fill(preview.palette.action).frame(height: DesignSystem.Spacing.xl)
                        }.frame(maxWidth: .infinity)
                    }.padding(DesignSystem.Spacing.md)
                }.frame(height: DesignSystem.ThemeLayout.previewHeight).clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
    }
}

/// Debounce typing as one settings update; flush on leaving, deactivation or termination.
/// This avoids rescheduling timer notifications for every character typed.
private struct PersonalPhrasesSettings: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @EnvironmentObject private var store: StudyStore
    @Environment(\.studyTheme) private var theme
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    @Environment(\.scenePhase) private var scenePhase
    @State private var drafts: [String: String] = [:]
    @State private var loaded = false
    var body: some View {
        SettingsCard(title: L10n.tr("Frasi personali")) {
            Text(L10n.tr("Scrivi le frasi che vuoi vedere. Lascia vuoto per mantenere i testi neutri."))
                .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
            ForEach(PersonalPhraseSlot.allCases) { slot in
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(slot.title).font(theme.typography.small)
                    StudyTextEntry(L10n.tr("La tua frase per %@", slot.title), text: Binding(
                        get: { drafts[slot.rawValue] ?? "" },
                        set: { drafts[slot.rawValue] = $0 }
                    ), axis: .vertical).lineLimit(2...4).textFieldStyle(StudyTextFieldStyle())
                }
            }
            Text(L10n.tr("Le frasi restano uguali in tutti i temi e non vengono tradotte."))
                .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
        }
        .onAppear { drafts = store.settings.personalPhrases ?? [:]; loaded = true }
        .task(id: drafts) {
            guard loaded else { return }
            do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
            persist()
        }
        .onChange(of: store.settings.personalPhrases) { drafts = store.settings.personalPhrases ?? [:] }
        .onChange(of: sectionVisible) { if !sectionVisible { persist() } }
        .onChange(of: scenePhase) { if scenePhase != .active { persist() } }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in persist() }
        .onDisappear { persist() }
    }
    private func persist() {
        guard loaded else { return }
        let phrases = drafts.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let value: [String: String]? = phrases.isEmpty ? nil : phrases
        guard value != store.settings.personalPhrases else { return }
        store.settings.personalPhrases = value
    }
}
