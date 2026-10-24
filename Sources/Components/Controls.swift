import SwiftUI
import AppKit

// Shared dropdown extracted from the Home; its selection and popover behavior are preserved.
struct StudyDropdown<Value: Hashable>: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    let title: String
    let options: [(Value, String)]
    @Binding var selection: Value
    var sectionLabels: [Value: String] = [:]
    @State private var showing = false
    @FocusState private var fieldFocused: Bool
    @State private var rowFocused: Int?
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme
    private var selectedIndex: Int? { options.firstIndex { $0.0 == selection } }
    var body: some View {
        Button {
            if showing {
                if let index = rowFocused, options.indices.contains(index) { selection = options[index].0 }
                showing = false
            } else { showing = true }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(selectedIndex.map { options[$0].1 } ?? title).lineLimit(1).truncationMode(.tail)
                Spacer(minLength: DesignSystem.Spacing.xs)
                Image(systemName: "chevron.down").font(appTheme.typography.caption).fontWeight(appTheme.preservedTypography.lightWeight)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .frame(minHeight: DesignSystem.Interaction.controlHeight)
            .foregroundStyle(appTheme.palette.textPrimary)
            .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.control).stroke(appTheme.palette.controlBorder).allowsHitTesting(false))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
        }.buttonStyle(.plain).focusable().focusEffectDisabled().focused($fieldFocused)
            .opacity(enabled ? 1 : appTheme.appearance.disabledOpacity)
            .interactiveHover()
            .modifier(KeyboardFocusBorder(explicitFocus: fieldFocused))
            .accessibilityLabel(title).accessibilityValue(selectedIndex.map { options[$0].1 } ?? L10n.tr("Nessuna scelta"))
            .onKeyPress(.downArrow) { showing = true; return .handled }
            .onKeyPress(.return) {
                guard showing else { showing = true; return .handled }
                if let index = rowFocused, options.indices.contains(index) { selection = options[index].0 }
                showing = false; return .handled
            }
            .popover(isPresented: $showing, arrowEdge: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.xxs) {
                            ForEach(options.indices, id: \.self) { index in
                                if let header = sectionLabels[options[index].0] {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Divider()
                                        Text(header).font(appTheme.typography.caption).foregroundStyle(appTheme.palette.textSecondary)
                                    }.padding(.horizontal, DesignSystem.Spacing.sm)
                                        .accessibilityAddTraits(.isHeader).allowsHitTesting(false)
                                }
                                Button {
                                    selection = options[index].0; showing = false
                                } label: {
                                    HStack {
                                        Text(options[index].1).fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: DesignSystem.Spacing.md)
                                        Image(systemName: "checkmark").opacity(selection == options[index].0 ? 1 : 0)
                                    }.padding(DesignSystem.Spacing.sm)
                                        .frame(minHeight: DesignSystem.Interaction.controlHeight)
                                        .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                                        .foregroundStyle(appTheme.palette.textPrimary)
                                }.id(index).buttonStyle(.plain)
                                    .interactiveHover(listRow: true, hoverChanged: { if $0 { rowFocused = index } })
                                    .modifier(KeyboardFocusBorder(explicitFocus: rowFocused == index))
                                    .accessibilityAddTraits(selection == options[index].0 ? .isSelected : [])
                            }
                        }.padding(DesignSystem.Spacing.xs)
                    }.frame(minWidth: DesignSystem.PreservedGeometry.points220, maxWidth: DesignSystem.PreservedGeometry.points340, maxHeight: DesignSystem.PreservedGeometry.points320)
                        .background(appTheme.palette.elevatedSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(appTheme.palette.controlBorder.opacity(appTheme.appearance.opacity0_5)).allowsHitTesting(false))
                        .onAppear { rowFocused = selectedIndex ?? options.indices.first }
                        .background(PopoverKeyboardCapture { key in
                            let index = rowFocused ?? selectedIndex ?? 0
                            switch key {
                            case 126: rowFocused = max(0, index - 1)
                            case 125: rowFocused = min(options.count - 1, index + 1)
                            case 36, 76, 49:
                                if options.indices.contains(index) { selection = options[index].0; showing = false }
                            case 53: showing = false
                            default: return false
                            }
                            return true
                        })
                        .onKeyPress(.return) {
                            guard let index = rowFocused, options.indices.contains(index) else { return .ignored }
                            selection = options[index].0; showing = false; return .handled
                        }
                        .onKeyPress(.space) {
                            guard let index = rowFocused, options.indices.contains(index) else { return .ignored }
                            selection = options[index].0; showing = false; return .handled
                        }
                        .onChange(of: rowFocused) { if let rowFocused { proxy.scrollTo(rowFocused) } }
                        .onMoveCommand { direction in
                            let index = rowFocused ?? selectedIndex ?? 0
                            if direction == .down { rowFocused = min(options.count - 1, index + 1) }
                            if direction == .up { rowFocused = max(0, index - 1) }
                        }
                        .onExitCommand { showing = false }
                }
                .preferredColorScheme(scheme)
                .shadow(color: appTheme.shadows.medium.color.opacity(scheme == .dark ? 0 : 1), radius: appTheme.shadows.medium.radius, y: appTheme.shadows.medium.y)
            }
            .onChange(of: showing) { if !showing { fieldFocused = true } }
            .disabled(options.isEmpty)
            .onChange(of: options.map { $0.0 }) { rowFocused = selectedIndex ?? options.indices.first }
    }
}
/// Scoped to this visible popover and this app; removed when the popover closes.
struct PopoverKeyboardCapture: NSViewRepresentable {
    @Environment(\.studyInteraction) private var interaction
    let action: (UInt16) -> Bool
    func makeNSView(context: Context) -> KeyView { let view = KeyView(); view.action = action; view.interaction = interaction; return view }
    func updateNSView(_ nsView: KeyView, context: Context) { nsView.action = action; nsView.interaction = interaction }
    static func dismantleNSView(_ nsView: KeyView, coordinator: ()) { nsView.stop() }
    final class KeyView: NSView {
        var action: ((UInt16) -> Bool)?
        weak var interaction: StudyInteractionSession?
        private var monitor: Any?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.window?.isVisible == true,
                      event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return event }
                if StudyFocusPolicy.isNavigationKey(event.keyCode, modifiers: event.modifierFlags) { self.interaction?.setInput(.keyboard); self.interaction?.resetHover() }
                return self.action?(event.keyCode) == true ? nil : event
            }
        }
        func stop() { if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil } }
    }
}


struct StudyFieldChrome: ViewModifier {
    @Environment(\.studyTheme) private var appTheme
    @FocusState private var focused: Bool
    @Environment(\.isEnabled) private var enabled
    func body(content: Content) -> some View {
        content.focused($focused)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .frame(minHeight: DesignSystem.Interaction.controlHeight)
            .foregroundStyle(appTheme.palette.textPrimary)
            .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.control).stroke(appTheme.palette.controlBorder, lineWidth: DesignSystem.PreservedGeometry.stroke1).allowsHitTesting(false))
            .modifier(KeyboardFocusBorder(explicitFocus: focused))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            .simultaneousGesture(TapGesture().onEnded { if enabled { focused = true } })
            .interactiveHover(textEntry: true).opacity(enabled ? 1 : appTheme.appearance.disabledOpacity)
    }
}
struct StudyTextFieldStyle: TextFieldStyle {
    @Environment(\.studyTheme) private var appTheme
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.textFieldStyle(.plain).modifier(StudyFieldChrome())
    }
}
struct StudyNumberField: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = -1_000_000_000...1_000_000_000
    var step: Double = 1
    private enum Part: Hashable { case minus, value, plus }
    @FocusState private var focus: Part?
    private var focused: Bool { focus == .value }
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        HStack(spacing: 0) {
            adjustment("minus", delta: -step).disabled(value <= range.lowerBound)
            TextField(title, value: $value, format: .number)
                .textFieldStyle(.plain).labelsHidden().focused($focus, equals: .value).focusEffectDisabled().multilineTextAlignment(.center).monospacedDigit()
                .frame(minWidth: DesignSystem.Spacing.xxl)
                .frame(height: DesignSystem.Interaction.controlHeight)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded { if enabled { focus = .value } })
                .onSubmit { commit() }
                .onChange(of: focus) { old, new in if old == .value && new != .value { commit() } }
                .onKeyPress(.upArrow) { adjust(step); return .handled }
                .onKeyPress(.downArrow) { adjust(-step); return .handled }
                .accessibilityLabel(title)
            adjustment("plus", delta: step).disabled(value >= range.upperBound)
        }
        .frame(height: DesignSystem.Interaction.controlHeight)
        .background(appTheme.palette.surface, in: Capsule())
        .overlay(Capsule().stroke(appTheme.palette.controlBorder, lineWidth: DesignSystem.PreservedGeometry.stroke1).allowsHitTesting(false))
        .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.panel, explicitFocus: focus != nil))
        .contentShape(Capsule()).interactiveHover(cornerRadius: DesignSystem.Radius.panel, decorative: true)
        .foregroundStyle(enabled ? appTheme.palette.textPrimary : appTheme.palette.onDisabledAction)
        .accessibilityElement(children: .contain)
    }
    private func adjustment(_ symbol: String, delta: Double) -> some View {
        Button { adjust(delta) } label: {
            Image(systemName: symbol).font(appTheme.typography.small)
                .frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.Interaction.controlHeight)
                .contentShape(Rectangle())
        }.buttonStyle(NumberAdjustmentStyle())
            .interactiveHover(cornerRadius: DesignSystem.Radius.panel, listRow: true)
            .focusEffectDisabled().focused($focus, equals: delta < 0 ? .minus : .plus)
            .accessibilityLabel((delta > 0 ? L10n.tr("Aumenta ") : L10n.tr("Riduci ")) + title)
    }
    private func commit() {
        value = value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : range.lowerBound
    }
    private func adjust(_ delta: Double) {
        guard enabled else { return }
        value = min(range.upperBound, max(range.lowerBound, (value.isFinite ? value : range.lowerBound) + delta))
    }
}
/// The pill's boundary buttons share the same neutral disabled tokens as other buttons.
private struct NumberAdjustmentStyle: ButtonStyle {
    @Environment(\.studyTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(enabled ? theme.palette.accent : theme.palette.onDisabledAction)
            .background(enabled ? .clear : theme.palette.disabledAction, in: Capsule())
    }
}
struct StudyToggleStyle: ToggleStyle {
    @Environment(\.studyTheme) private var appTheme
    func makeBody(configuration: Configuration) -> some View { SwitchBody(configuration: configuration) }
    private struct SwitchBody: View {
    @Environment(\.studyTheme) private var appTheme
        let configuration: Configuration
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.komorebiMotion) private var motion
        var body: some View {
            Button { configuration.isOn.toggle() } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    configuration.label.foregroundStyle(appTheme.palette.textPrimary)
                    Spacer(minLength: DesignSystem.Spacing.sm)
                    Capsule().fill(configuration.isOn ? appTheme.palette.action : appTheme.palette.controlBorder.opacity(appTheme.appearance.controlBorderOpacity))
                        .frame(width: DesignSystem.Interaction.controlHeight, height: DesignSystem.ControlGeometry.toggleTrack)
                        .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                            Circle().fill(appTheme.palette.onAction).frame(width: DesignSystem.ControlGeometry.toggleThumb, height: DesignSystem.ControlGeometry.toggleThumb).padding(DesignSystem.ControlGeometry.toggleInset).allowsHitTesting(false)
                        }
                        .overlay(Capsule().stroke(appTheme.palette.controlBorder.opacity(appTheme.appearance.controlBorderOpacity)).allowsHitTesting(false))
                }.padding(.horizontal, DesignSystem.Spacing.xs)
                    .frame(minHeight: DesignSystem.Interaction.controlHeight)
                    .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            }.buttonStyle(.plain).interactiveHover(listRow: true)
                .modifier(KeyboardFocusBorder())
                .opacity(enabled ? 1 : appTheme.appearance.disabledOpacity)
                .animation(reduceMotion || motion == "Off" ? nil : .easeOut(duration: DesignSystem.ControlGeometry.toggleDuration), value: configuration.isOn)
                .accessibilityRepresentation {
                    Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
                }
        }
    }
}

/// Explicit themed placeholder: AppKit dims native prompt text even when it has a color.
/// A nil token preserves the original system placeholder exactly.
struct StudyTextEntry: View {
    @Environment(\.studyTheme) private var appTheme
    let title: String
    @Binding var text: String
    var axis: Axis
    init(_ title: String, text: Binding<String>, axis: Axis = .horizontal) {
        self.title = title; self._text = text; self.axis = axis
    }
    var body: some View {
        TextField(title, text: $text, prompt: appTheme.palette.placeholder == nil ? nil : Text(""), axis: axis)
            .overlay(alignment: .leading) {
                if let ink = appTheme.palette.placeholder, text.isEmpty {
                    Text(title).foregroundStyle(ink).padding(.horizontal, DesignSystem.Spacing.sm)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }.accessibilityLabel(title)
    }
}
