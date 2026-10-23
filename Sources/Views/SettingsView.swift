import SwiftUI

struct SettingsView: View {
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
                        Text("Impostazioni").font(appTheme.typography.title)
                        Text("Il tuo ritmo, il tuo spazio.").foregroundStyle(appTheme.palette.textSecondary)
                    }
                    Spacer()
                    Label(feedback ?? "Salvato", systemImage: "checkmark.circle")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.accent)
                        .opacity(feedback == nil ? 0 : 1).accessibilityHidden(feedback == nil)
                }
                SettingsCard(title: "Obiettivi") {
                    SettingRow("Obiettivo giornaliero", detail: "Ore di studio al giorno.") {
                        StudyNumberField(title: "Obiettivo giornaliero in ore", value: $store.settings.dailyGoal, range: 0.25...24, step: 0.25)
                    }
                    settingDivider
                    SettingRow("Obiettivo settimanale", detail: "Il tempo che vuoi dedicarti ogni settimana.") {
                        StudyNumberField(title: "Obiettivo settimanale in ore", value: $store.settings.weeklyGoal, range: 0.25...168, step: 0.25)
                    }
                    settingDivider
                    Toggle("Per la serie, richiedi l’obiettivo giornaliero", isOn: $store.settings.streakUsesGoal)
                    if !store.settings.streakUsesGoal {
                        SettingRow("Minuti per completare un giorno", detail: "La soglia che fa proseguire la tua serie.") {
                            StudyNumberField(title: "Minuti per completare un giorno", value: $store.settings.streakMinutes, range: 1...1440)
                        }
                    }
                }
                SettingsCard(title: "Pomodoro") {
                    SettingRow("Studio", detail: "Minuti per ogni sessione.") {
                        StudyNumberField(title: "Minuti di studio Pomodoro", value: $store.settings.pomodoroDuration, range: 1...600)
                    }
                    settingDivider
                    SettingRow("Pausa breve", detail: "Minuti tra una sessione e l’altra.") {
                        StudyNumberField(title: "Minuti di pausa breve", value: $store.settings.shortBreakDuration, range: 1...120)
                    }
                    settingDivider
                    SettingRow("Pausa lunga", detail: "Minuti per una sosta più ampia.") {
                        StudyNumberField(title: "Minuti di pausa lunga", value: $store.settings.longBreakDuration, range: 1...180)
                    }
                    settingDivider
                    SettingRow("Pausa lunga ogni N sessioni", detail: "Scegli quante sessioni completare prima della pausa lunga.") {
                        StudyNumberField(title: "Sessioni prima della pausa lunga", value: Binding(get: { Double(store.settings.longBreakEvery) }, set: { if $0.isFinite { store.settings.longBreakEvery = Int(min(12, max(1, $0))) } }), range: 1...12)
                    }
                    Text("Le nuove durate valgono dal prossimo timer. Ogni pausa parte quando vuoi tu.")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                SettingsCard(title: "Tema") {
                    SettingRow("Modalità", detail: "Chiaro, scuro oppure in sintonia con il Mac.", width: DesignSystem.SettingsLayout.segmentWidth) {
                        PastelSegmentedControl("Modalità", values: ["Light", "Dark", "System"], selection: $store.settings.appearance) { $0 == "Light" ? "Chiaro" : $0 == "Dark" ? "Scuro" : "Sistema" }
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
                                Text(option.title)
                                Text(option.detail).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                            }
                        }.accessibilityLabel(option.title).accessibilityHint(option.detail)
                    }
                }
                .id(ThemeSettingsAnchor.theme)
                SettingsCard(title: "Il tuo ambiente") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Paesaggio").font(appTheme.typography.small)
                        Text("La luce che accompagna il timer.").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        if appTheme.package.behavior.replacesLandscapes {
                            Text("Con il tema \(appTheme.package.name) attivo, il paesaggio è sostituito.")
                                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                        } else { ScenePicker(selection: $store.settings.landscape) }
                    }
                    settingDivider
                    SettingRow("Animazioni", detail: "Le preferenze di accessibilità del Mac hanno sempre la precedenza.", width: DesignSystem.SettingsLayout.dropdownWidth) {
                        StudyDropdown(title: "Animazioni", options: [("Off", "Disattivate"), ("Reduced", "Delicate"), ("Full", "Complete")], selection: $store.settings.animations)
                    }
                    settingDivider
                    SettingsAmbientRows(audio: store.audio, onApply: { signal("Applicato") })
                }
                SettingsCard(title: "Notifiche") {
                    Toggle("Avvisi di fine sessione", isOn: Binding(get: { store.settings.notifications }, set: { on in if on { store.requestNotifications() } else { store.settings.notifications = false; store.scheduleNotification() } }))
                    settingDivider
                    Toggle("Suono di fine timer", isOn: $store.settings.sounds).onChange(of: store.settings.sounds) { store.scheduleNotification() }
                }
                SettingsCard(title: "Dati e privacy") {
                    Text("Tutto rimane su questo Mac. Nessun account, pubblicità o servizio di analisi.")
                        .foregroundStyle(appTheme.palette.textSecondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DesignSystem.Spacing.sm) { archiveActions }
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) { archiveActions }
                    }
                    Text("L’importazione aggiunge i record mancanti senza cancellare quelli esistenti. Termina prima il timer attivo.")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
                SettingsCard(title: "Tastiera") {
                    shortcut("Avvia, sospendi o riprendi", keys: "⌘ ⇧ P")
                    settingDivider
                    shortcut("Avvia una sessione", keys: "⌘ Invio")
                    settingDivider
                    shortcut("Termina e salva", keys: "⌘ .")
                }
                SettingsCard(title: "Timer e barra dei menu") {
                    Toggle("Sospendi automaticamente durante lo stop", isOn: $store.pauseOnSleep)
                    settingDivider
                    Toggle("Mostra il tempo nella barra dei menu", isOn: $store.showMenuTime)
                    Text("Le nuove sessioni registrano gli intervalli effettivi di studio. Quelle precedenti o corrette manualmente mantengono il conteggio proporzionale tra i giorni.")
                        .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                }
            }
            .padding(DesignSystem.Layout.contentPadding)
            .frame(maxWidth: DesignSystem.Layout.contentMaximum).frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.top, for: .initialOffset)
        .background(appTheme.palette.background)
        .toggleStyle(StudyToggleStyle())
        .onChange(of: store.settings) { signal("Salvato") }
        .onChange(of: store.pauseOnSleep) { signal("Salvato") }
        .onChange(of: store.showMenuTime) { signal("Salvato") }
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
        Button("Esporta CSV") { store.export(csv: true) }
        Button("Backup JSON") { store.export(csv: false) }
        Button("Importa backup") { store.restore() }.disabled(store.active != nil)
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
                        Text(name).font(appTheme.typography.caption).lineLimit(1).foregroundStyle(appTheme.palette.textPrimary)
                    }.padding(DesignSystem.Spacing.xs).frame(maxWidth: .infinity)
                        .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(selection == id ? appTheme.palette.accent : appTheme.palette.border, lineWidth: selection == id ? DesignSystem.Interaction.focusWidth : DesignSystem.PreservedGeometry.stroke1).allowsHitTesting(false))
                        .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                }.buttonStyle(.plain).interactiveHover(cornerRadius: DesignSystem.Radius.card)
                    .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card))
                    .accessibilityLabel("Paesaggio " + name).accessibilityAddTraits(selection == id ? .isSelected : [])
            }
        }
    }
}

struct GoalEditButton: View {
    @Environment(\.studyTheme) private var appTheme
    @State private var showing = false
    var body: some View {
        Button("Modifica obiettivi", systemImage: "pencil") { showing = true }
            .sheet(isPresented: $showing) { GoalEditor() }
    }
}
struct GoalEditor: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    @State private var daily = 3.0
    @State private var weekly = 15.0
    var valid: Bool { daily.isFinite && weekly.isFinite && (0.25...24).contains(daily) && (0.25...168).contains(weekly) }
    var body: some View {
        Form {
            Text("Obiettivi di studio").font(appTheme.preservedTypography.title2)
            StudyNumberField(title: "Ore al giorno", value: $daily)
            StudyNumberField(title: "Ore alla settimana", value: $weekly)
            Text("Puoi usare valori decimali, per esempio 2,5 ore. I nuovi obiettivi si applicano ai progressi correnti.").font(appTheme.preservedTypography.caption).foregroundStyle(appTheme.palette.textSecondary)
            if !valid { Text("Giornaliero: da 0,25 a 24 ore. Settimanale: da 0,25 a 168 ore.").foregroundStyle(appTheme.appearance.destructiveInk).font(appTheme.preservedTypography.caption) }
            HStack { Button("Annulla") { dismiss() }; Spacer(); Button("Salva") { store.settings.dailyGoal = daily; store.settings.weeklyGoal = weekly; dismiss() }.buttonStyle(ResponsiveButtonStyle(prominent: true)).disabled(!valid) }
        }.padding(DesignSystem.PreservedGeometry.gap28).frame(width: DesignSystem.PreservedGeometry.points420).onAppear { daily = store.settings.dailyGoal; weekly = store.settings.weeklyGoal }
    }
}

private struct SettingsAmbientRows: View {
    @Environment(\.studyTheme) private var appTheme
    @ObservedObject var audio: AmbientAudio
    let onApply: () -> Void
    var body: some View {
        Group {
            SettingRow("Suono ambiente", detail: "Suoni sintetizzati, senza registrazioni esterne.", width: DesignSystem.SettingsLayout.dropdownWidth) {
                StudyDropdown(title: "Suono ambiente", options: [("Off", "Silenzio"), ("Pioggia", "Pioggia"), ("Vento", "Vento"), ("Camino", "Camino")], selection: $audio.sound)
            }
            SettingRow("Volume ambiente", width: DesignSystem.SettingsLayout.dropdownWidth) {
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
                Text(package.subtitle).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }.padding(DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(selected ? appTheme.palette.accent : appTheme.palette.border, lineWidth: selected ? DesignSystem.Interaction.focusWidth : DesignSystem.PreservedGeometry.stroke1).allowsHitTesting(false))
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }.buttonStyle(.plain).focusable().focusEffectDisabled().focused($focused)
            .onKeyPress(.return) { action(); return .handled }
            .onKeyPress(.space) { action(); return .handled }
            .interactiveHover(cornerRadius: DesignSystem.Radius.card)
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.card, explicitFocus: focused))
            .accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton).accessibilityLabel("Tema " + package.name)
            .accessibilityValue(package.subtitle).accessibilityAddTraits(selected ? .isSelected : [])
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
