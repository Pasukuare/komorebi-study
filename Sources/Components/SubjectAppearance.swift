import SwiftUI

struct SubjectColorChoice: Identifiable {
    let id: String
    let name: String
    let ink: Color
    // Separate semantic roles may resolve to the same accessible ink.
    var text: Color { ink }
    var icon: Color { ink }
    var tileFill: Color { ink.opacity(DesignSystem.SubjectAppearance.fillOpacity) }
}
enum SubjectPalette {
    static let choices = DesignSystem.PreservedColors.subjectChoices
    static func choice(_ id: String) -> SubjectColorChoice {
        let canonical = SubjectColorID.canonical(id)
        if let choice = choices.first(where: { $0.id == canonical }) { return choice }
        let neutral = choices.first { $0.id == SubjectColorID.neutralID }!
        return SubjectColorChoice(id: id, name: neutral.name, ink: neutral.ink)
    }
}
struct SubjectSymbol: Identifiable { let id: String; let name: String }
struct SubjectIconCategory: Identifiable {
    let name: String
    let symbols: [SubjectSymbol]
    var id: String { name }
}
enum SubjectIcons {
    static let categories: [SubjectIconCategory] = [
        .init(name: "Scienze", symbols: [
            .init(id: "atom", name: "Atomo"), .init(id: "testtube.2", name: "Provetta"),
            .init(id: "function", name: "Calcolo"), .init(id: "chart.xyaxis.line", name: "Grafico"),
            .init(id: "scope", name: "Osservazione"), .init(id: "stethoscope", name: "Medicina")]),
        .init(name: "Tecnologia", symbols: [
            .init(id: "chevron.left.forwardslash.chevron.right", name: "Codice"), .init(id: "cpu", name: "Chip"),
            .init(id: "terminal", name: "Terminale"), .init(id: "network", name: "Rete"),
            .init(id: "waveform", name: "Segnali"), .init(id: "antenna.radiowaves.left.and.right", name: "Comunicazioni")]),
        .init(name: "Ingegneria", symbols: [
            .init(id: "gearshape", name: "Ingranaggi"), .init(id: "pencil.and.ruler", name: "Disegno tecnico"),
            .init(id: "bolt", name: "Elettricità"), .init(id: "compass.drawing", name: "Compasso"),
            .init(id: "gauge.with.dots.needle.50percent", name: "Controllo"), .init(id: "wrench.and.screwdriver", name: "Strumenti")]),
        .init(name: "Lettere e società", symbols: [
            .init(id: "book", name: "Libro aperto"), .init(id: "scroll", name: "Pergamena"),
            .init(id: "building.columns", name: "Storia e diritto"), .init(id: "theatermasks", name: "Teatro"),
            .init(id: "bubble.left.and.bubble.right", name: "Lingue"), .init(id: "character.book.closed", name: "Letteratura")]),
        .init(name: "Arte e musica", symbols: [
            .init(id: "paintpalette", name: "Tavolozza"), .init(id: "music.note", name: "Musica"),
            .init(id: "camera", name: "Fotografia"), .init(id: "pencil", name: "Matita"),
            .init(id: "paintbrush", name: "Pittura"), .init(id: "film", name: "Cinema")]),
        .init(name: "Generale", symbols: [
            .init(id: "graduationcap", name: "Laurea"), .init(id: "lightbulb", name: "Idea"),
            .init(id: "star", name: "Stella"), .init(id: "heart", name: "Cuore"),
            .init(id: "leaf", name: "Foglia"), .init(id: "flag", name: "Traguardo")])
    ]
    static var all: [SubjectSymbol] { categories.flatMap(\.symbols) }
    static func name(for symbol: String) -> String { L10n.tr(all.first { $0.id == symbol }?.name ?? "Icona attuale") }
}
struct SubjectIconTile: View {
    @Environment(\.studyTheme) private var appTheme
    let symbol: String
    let color: Color
    var body: some View {
        Image(systemName: symbol).symbolRenderingMode(.monochrome)
            .font(appTheme.preservedTypography.subjectSymbol)
            .frame(width: DesignSystem.SubjectAppearance.symbolGrid, height: DesignSystem.SubjectAppearance.symbolGrid)
            .foregroundStyle(color)
            .frame(width: DesignSystem.SubjectAppearance.tile, height: DesignSystem.SubjectAppearance.tile)
            .background(color.opacity(DesignSystem.SubjectAppearance.fillOpacity), in: RoundedRectangle(cornerRadius: DesignSystem.SubjectAppearance.radius))
            .accessibilityHidden(true)
    }
}
struct SubjectIconPicker: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var selection: String
    let color: Color
    @State private var showing = false
    @State private var focusedIcon: String?
    @FocusState private var openerFocused: Bool
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Button(action: activate) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                SubjectIconTile(symbol: selection, color: color)
                Image(systemName: "chevron.down").font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
            }.padding(.horizontal, DesignSystem.Spacing.xs)
                .frame(height: DesignSystem.Interaction.controlHeight)
                .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.control).stroke(appTheme.palette.border).allowsHitTesting(false))
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
        }.buttonStyle(.plain).focusable(interactions: .edit).focusEffectDisabled().focused($openerFocused)
            .interactiveHover().modifier(KeyboardFocusBorder(explicitFocus: openerFocused))
            .onKeyPress(.return, phases: .down) { key in
                guard key.modifiers.isEmpty else { return .ignored }
                activate(); return .handled
            }
            .onKeyPress(.space, phases: .down) { key in
                guard key.modifiers.isEmpty else { return .ignored }
                activate(); return .handled
            }
            .accessibilityLabel(L10n.tr("Icona della materia")).accessibilityValue(SubjectIcons.name(for: selection))
            .popover(isPresented: $showing, arrowEdge: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            ForEach(SubjectIcons.categories) { category in
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text(L10n.tr(category.name)).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(DesignSystem.Interaction.controlHeight), spacing: DesignSystem.Spacing.xs), count: 6), spacing: DesignSystem.Spacing.xs) {
                                        ForEach(category.symbols) { icon in
                                            Button { selection = icon.id; showing = false } label: {
                                                SubjectIconTile(symbol: icon.id, color: color)
                                                    .frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight)
                                                    .overlay(StudySelectionBorder(selected: selection == icon.id, color: color, radius: DesignSystem.SubjectAppearance.radius, explicitFocus: focusedIcon == icon.id))
                                                    .contentShape(RoundedRectangle(cornerRadius: DesignSystem.SubjectAppearance.radius))
                                            }.id(icon.id).buttonStyle(.plain)
                                                .interactiveHover(cornerRadius: DesignSystem.SubjectAppearance.radius, selected: selection == icon.id)
                                                .modifier(KeyboardFocusBorder(radius: DesignSystem.SubjectAppearance.radius, explicitFocus: focusedIcon == icon.id))
                                                .help(L10n.tr(icon.name)).accessibilityLabel(L10n.tr(icon.name))
                                                .accessibilityAddTraits(selection == icon.id ? .isSelected : [])
                                        }
                                    }
                                }
                            }
                        }.padding(DesignSystem.Spacing.md)
                    }.frame(width: DesignSystem.SubjectAppearance.pickerWidth, height: DesignSystem.SubjectAppearance.pickerHeight)
                        .background(appTheme.palette.elevatedSurface)
                        .onAppear { focusedIcon = SubjectIcons.all.contains { $0.id == selection } ? selection : SubjectIcons.all.first?.id }
                        .onChange(of: focusedIcon) { if let focusedIcon { proxy.scrollTo(focusedIcon) } }
                        .onMoveCommand { direction in
                            let index = SubjectIcons.all.firstIndex { $0.id == focusedIcon } ?? 0
                            let delta = direction == .left ? -1 : direction == .right ? 1 : direction == .up ? -6 : 6
                            focusedIcon = SubjectIcons.all[min(SubjectIcons.all.count - 1, max(0, index + delta))].id
                        }
                        .background(PopoverKeyboardCapture { key in
                            // The highlighted item is selection state, not native first-responder
                            // focus: AppKit delivers these keys while the opener still has focus.
                            let index = SubjectIcons.all.firstIndex { $0.id == focusedIcon } ?? 0
                            let delta: Int
                            switch key {
                            case 123: delta = -1
                            case 124: delta = 1
                            case 126: delta = -6
                            case 125: delta = 6
                            case 36, 76, 49: selection = focusedIcon ?? selection; showing = false; return true
                            case 53: showing = false; return true
                            default: return false
                            }
                            focusedIcon = SubjectIcons.all[min(SubjectIcons.all.count - 1, max(0, index + delta))].id
                            return true
                        })
                        .onExitCommand { showing = false }
                }.preferredColorScheme(scheme)
            }
            .onChange(of: showing) { if !showing { openerFocused = true } }
    }
    private func activate() {
        if showing, let focusedIcon { selection = focusedIcon; showing = false }
        else { showing = true }
    }
}
struct SubjectColorPicker: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var selection: String
    var isEditing = false
    @State private var tab: SubjectColorGroup = .classics
    @State private var initialized = false
    @FocusState private var focusedColor: String?
    private var colors: [SubjectColorChoice] { appTheme.subjectColors.filter { SubjectColorGroup.group(for: $0.id) == tab } }
    private var tabSelection: Binding<String> { Binding(get: { tab.rawValue }, set: { if let next = SubjectColorGroup(rawValue: $0) { tab = next } }) }
    private func resetTab() {
        tab = .initial(editing: isEditing, colorID: selection, behavior: appTheme.package.behavior)
        initialized = true
    }
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignSystem.Spacing.xxs) { tabs }
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) { tabs }
            }
            Text(tab.paletteDescription)
                .font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(colors) { choice in
                    Button { focusedColor = choice.id; selection = choice.id } label: {
                        Circle().fill(choice.ink).frame(width: DesignSystem.SubjectAppearance.swatch, height: DesignSystem.SubjectAppearance.swatch)
                            .frame(width: DesignSystem.SubjectAppearance.swatchHitArea, height: DesignSystem.Interaction.controlHeight)
                            .overlay(StudySelectionBorder(selected: appTheme.subjectChoice(selection).id == choice.id, color: choice.ink, shape: .circle, explicitFocus: focusedColor == choice.id).padding(DesignSystem.Spacing.xxs))
                            .contentShape(Circle())
                    }.buttonStyle(.plain).focusable(interactions: .edit).focusEffectDisabled().focused($focusedColor, equals: choice.id)
                        .interactiveHover(cornerRadius: DesignSystem.Radius.panel, shape: .circle, selected: appTheme.subjectChoice(selection).id == choice.id)
                        .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.panel, explicitFocus: focusedColor == choice.id, shape: .circle))
                        .onKeyPress(.return) { selection = choice.id; return .handled }
                        .onKeyPress(.space) { selection = choice.id; return .handled }
                        .help(L10n.tr(choice.name)).accessibilityLabel(L10n.tr(choice.name))
                        .accessibilityAddTraits(appTheme.subjectChoice(selection).id == choice.id ? .isSelected : [])
                }
            }.onMoveCommand { direction in
                guard let index = colors.firstIndex(where: { $0.id == focusedColor }) else { return }
                if direction == .right, index + 1 < colors.count { focusedColor = colors[index + 1].id }
                if direction == .left, index > 0 { focusedColor = colors[index - 1].id }
            }
        }.accessibilityElement(children: .contain).accessibilityLabel(L10n.tr("Colore della materia"))
            .onAppear { if !initialized { resetTab() } }
            .onChange(of: isEditing) { resetTab() }
            .onChange(of: selection) { if isEditing, let group = SubjectColorGroup.group(for: selection) { tab = group } }
            .onChange(of: appTheme.package.id) { if !isEditing { resetTab() } }
    }
    @ViewBuilder private var tabs: some View {
        ForEach(SubjectColorGroup.allCases) { group in
            ColorGroupTab(group: group, selected: group == tab) { tab = group }
        }
    }
}
private struct ColorGroupTab: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @FocusState private var focused: Bool
    let group: SubjectColorGroup
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button { focused = true; action() } label: {
            Label(group.title, systemImage: group.symbol).font(appTheme.typography.caption)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .frame(minHeight: DesignSystem.Interaction.controlHeight)
                .foregroundStyle(selected ? appTheme.palette.onAccentSurface : appTheme.palette.textPrimary)
                .background(selected ? appTheme.palette.accentSurface : .clear, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
        }.buttonStyle(.plain).focusable(interactions: .edit).focusEffectDisabled().focused($focused)
            .interactiveHover(cornerRadius: DesignSystem.Radius.action)
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.action, explicitFocus: focused))
            .onKeyPress(.return) { action(); return .handled }
            .onKeyPress(.space) { action(); return .handled }
            .accessibilityLabel(L10n.tr("Palette ") + group.title).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
