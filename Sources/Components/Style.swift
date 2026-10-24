import SwiftUI
import Combine
import AppKit
import QuartzCore

extension Color {
    static func adaptive(_ light: (Double, Double, Double), _ dark: (Double, Double, Double)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let rgb = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
    static let sage = DesignSystem.PreservedColors.sage
    static let sageFill = DesignSystem.PreservedColors.sageFill
    static let softTeal = DesignSystem.PreservedColors.softTeal
    static let softAmber = DesignSystem.PreservedColors.softAmber
    static let mutedRed = DesignSystem.PreservedColors.mutedRed
    static let workspace = DesignSystem.Palette.background
    static let cardSurface = DesignSystem.Palette.surface
    static let cream = DesignSystem.PreservedColors.cream
    static func subject(_ name: String) -> Color { SubjectPalette.choice(name).ink }
    static func subjectFill(_ name: String) -> Color { SubjectPalette.choice(name).ink.opacity(DesignSystem.PreservedAppearance.opacity0_22) }

}

/// Semantic tokens. Legacy metrics keep existing components unchanged during migration.
enum DesignSystem {
    enum CalendarAppearance {
        static let pigmentOpacity = 0.28
        static let neutralOpacity = 0.18
        static let cellHeight: CGFloat = 76
        static let boundaryFeather = 0.25
        static let waveAmplitude = 0.035
        static let waveShareLimit = 0.2
    }
    enum Palette {
        static let background = Color.adaptive((0.979, 0.975, 0.962), (0.105, 0.13, 0.112))
        static let surface = Color.adaptive((0.997, 0.994, 0.984), (0.145, 0.17, 0.15))
        static let elevatedSurface = Color.adaptive((1, 0.998, 0.99), (0.18, 0.205, 0.18))
        static let border = Color.adaptive((0.78, 0.77, 0.72), (0.38, 0.37, 0.33))
        static let textPrimary = Color.adaptive((0.22, 0.23, 0.20), (0.94, 0.92, 0.87))
        static let textSecondary = Color.adaptive((0.36, 0.37, 0.33), (0.79, 0.78, 0.72))
        static let textTertiary = Color.adaptive((0.43, 0.44, 0.39), (0.70, 0.69, 0.63))
        static let accent = Color.sage
        static let accentHover = Color.adaptive((0.26, 0.33, 0.28), (0.77, 0.82, 0.75))
        static let accentSurface = Color.sageFill
        static let success = Color.adaptive((0.29, 0.39, 0.31), (0.73, 0.81, 0.71))
        static let successSurface = Color.adaptive((0.85, 0.90, 0.82), (0.24, 0.30, 0.23))
        static let warning = Color.adaptive((0.46, 0.36, 0.23), (0.85, 0.77, 0.62))
        static let warningSurface = Color.adaptive((0.94, 0.88, 0.76), (0.32, 0.27, 0.20))
        static let error = Color.adaptive((0.55, 0.30, 0.31), (0.88, 0.70, 0.69))
        static let errorSurface = Color.adaptive((0.95, 0.84, 0.82), (0.33, 0.23, 0.22))
        static let interval = Color.softTeal
        static let action = Color.adaptive((0.28, 0.37, 0.29), (0.29, 0.39, 0.30))
        static let actionHover = Color.adaptive((0.32, 0.41, 0.33), (0.34, 0.44, 0.35))
        static let onAction = Color.white
        static let light = Color.adaptive((1, 0.96, 0.81), (0.79, 0.84, 0.66))
        static func landscapeTint(_ theme: String) -> Color {
            switch theme {
            case "Sunset": return Color.softAmber.opacity(0.045)
            case "Rain": return Color.softTeal.opacity(0.035)
            case "Forest": return accentSurface.opacity(0.08)
            case "Night": return accent.opacity(0.045)
            default: return light.opacity(0.025)
            }
        }
        static let hill = Color.adaptive((0.53, 0.64, 0.48), (0.40, 0.51, 0.36))
        static let timerDivider = accent.opacity(0.1)
        static let timerBorder = accent.opacity(0.12)
        static let timerTrack = accent.opacity(0.07)
        static let timerGradientStart = Color.adaptive((0.62, 0.71, 0.59), (0.52, 0.64, 0.52))
        static let timerGradientEnd = Color.adaptive((0.37, 0.49, 0.39), (0.78, 0.84, 0.73))
    }
    enum Typography {
        static let caption = Font.system(size: 12)
        static let small = Font.system(size: 14)
        static let body = Font.system(size: 16)
        static let heading = Font.system(size: 20, design: .serif)
        static let title = Font.system(size: 28, design: .serif)
        static let display = Font.system(size: 40, weight: .light, design: .serif)
        // Compatibility aliases preserve current Timer typography in this first pass.
        static let timerTitle = Font.system(size: 29, weight: .medium, design: .serif)
        static let timerSetupTitle = Font.system(size: 23, design: .serif)
        static let timerMessage = Font.system(size: 25, design: .serif)
        static let timerTotal = Font.system(size: 25, weight: .medium, design: .rounded).monospacedDigit()
        static let timerSubject = Font.system(size: 15, weight: .medium)
        static let timerDigits = Font.system(size: 60, weight: .light, design: .rounded).monospacedDigit()
        static let timerSymbol = Font.system(size: 14, weight: .light)
        static let control = Font.system(size: 13, weight: .semibold)
        static let legacyHeadline = Font.headline
        static let legacyCallout = Font.callout
    }
    enum Spacing {
        static let xxs: CGFloat = 4, xs: CGFloat = 8, sm: CGFloat = 12
        static let md: CGFloat = 16, lg: CGFloat = 20, xl: CGFloat = 24, xxl: CGFloat = 32
        // Transitional metrics: migrate layout separately from token extraction.
        static let legacy6: CGFloat = 6, legacy7: CGFloat = 7, legacy9: CGFloat = 9
        static let legacy14: CGFloat = 14, legacy18: CGFloat = 18
        static let legacy22: CGFloat = 22, legacy30: CGFloat = 30
    }
    enum Radius {
        static let control: CGFloat = 8, card: CGFloat = 14, panel: CGFloat = 22
        static let action: CGFloat = 12
        static let legacyTimerPanel: CGFloat = 28
    }
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
    enum Shadows {
        private static let tint = Color.adaptive((0.70, 0.67, 0.57), (0.32, 0.29, 0.23))
        static let low = Shadow(color: tint.opacity(0.10), radius: 4, y: 2)
        static let medium = Shadow(color: tint.opacity(0.14), radius: 12, y: 4)
        static let high = Shadow(color: tint.opacity(0.18), radius: 24, y: 8)
    }
    enum SubjectAppearance {
        static let sectionTransitionDuration = 0.25
        static let tile: CGFloat = 36, radius: CGFloat = 10
        static let symbolGrid: CGFloat = 24, symbolSize: CGFloat = 20
        static let fillOpacity: Double = 0.15
        static let swatch: CGFloat = 28, swatchHitArea: CGFloat = 44
        static let pickerWidth: CGFloat = 336, pickerHeight: CGFloat = 420
    }
    enum ControlGeometry {
        static let toggleThumb: CGFloat = 20, toggleTrack: CGFloat = 26, toggleInset: CGFloat = 3
        static let toggleDuration: Double = 0.15
    }
    enum SubjectEditorLayout {
        static let minimumWidth: CGFloat = 520
        static let windowHeightFraction: CGFloat = 0.8
        static let padding = PreservedGeometry.gap28
        static let scrollGutter = Spacing.lg
        static let fallbackWindowHeight = PreservedGeometry.points650
        static func bodyLimit(windowHeight: CGFloat, chromeHeight: CGFloat) -> CGFloat {
            max(Interaction.controlHeight, windowHeight * windowHeightFraction - padding * 2 - Spacing.md * 2 - chromeHeight)
        }
    }
    enum SettingsLayout {
        static let dropdownWidth: CGFloat = 220
        static let segmentWidth: CGFloat = 260
    }
    enum Layout {
        static let sidebarWidth: CGFloat = 224
        static let headerHeight: CGFloat = 52
        static let contentPadding: CGFloat = 30
        static let contentMaximum: CGFloat = 1100
        static let dividerWidth: CGFloat = 1
        static let windowControlsSpace: CGFloat = 84
    }
    enum Interaction {
        static let hoverDuration = 0.18, sectionDuration = 0.20, chartDuration = 0.30
        static let hoverLift: CGFloat = 1, pressedScale: CGFloat = 0.98
        static let spotlightRadius: CGFloat = 140, spotlightOpacity = 0.10
        static let controlHeight: CGFloat = 44, actionHeight: CGFloat = 48
        static let thumbSize: CGFloat = 14, sliderTrack: CGFloat = 3
        static let focusWidth: CGFloat = 2, focusInset: CGFloat = 2
        static let nativeProbeOpacity = 1.0 / 65_536
        static let breatheScale: CGFloat = 1.02, breatheDuration = 2.0
        static let controlsTimeout: UInt64 = 2_000_000_000
        static let sectionOffset: CGFloat = 8
    }
    enum TimerLayout {
        static let faceWide: CGFloat = 280, faceMedium: CGFloat = 208, faceCompact: CGFloat = 180
        static let panelWide: CGFloat = 300, panelMedium: CGFloat = 284, panelCompact: CGFloat = 340
        static let wideMinimum: CGFloat = 612, mediumMinimum: CGFloat = 516, contentMaximum: CGFloat = 1100
        static let studyField: CGFloat = 160, breakField: CGFloat = 160
        static let ringWidth: CGFloat = 9, trackWidth: CGFloat = 2
        static let glowRadius: CGFloat = 5
        static let glowOpacity: Double = 0.22
        static let symbolOpacity: Double = 0.65
        static let faceInsetRatio: CGFloat = 0.24
        static let progressDuration: Double = 0.45
        static let trackDash: [CGFloat] = [2, 7]
        static let trackOpacity: Double = 0.23
        static let minimumDigitScale: CGFloat = 0.65
    }
}


/// Exact baseline values; structural metrics stay independent of future theme palettes.
extension DesignSystem {
    enum PreservedTypography {
        static let callout: Font = Font.callout
        static let caption: Font = Font.caption
        static let chartTooltipValue: Font = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let comparisonSymbol: Font = Font.system(size: 18, weight: .medium)
        static let completionSymbol: Font = Font.system(size: 42)
        static let completionTitle: Font = Font.system(size: 28, design: .serif)
        static let dailyGoalValue: Font = Font.system(size: 28, weight: .medium, design: .rounded)
        static let editorTitle: Font = Font.system(size: 25, design: .serif)
        static let headline: Font = Font.headline
        static let homeCardTitle: Font = Font.system(size: 20, design: .serif)
        static let homeTimerValue: Font = Font.system(size: 34, weight: .light, design: .rounded)
        static let homeTitle: Font = Font.system(size: 31, design: .serif)
        static let lightWeight: Font.Weight = .light
        static let mediumWeight: Font.Weight = .medium
        static let menuGreeting: Font = Font.system(size: 22, design: .serif)
        static let menuTimerDigits: Font = Font.system(size: 44, weight: .light, design: .rounded)
        static let menuWordmark: Font = Font.system(size: 18, weight: .medium, design: .serif)
        static let pageTitle: Font = Font.system(size: 30, design: .serif)
        static let regularWeight: Font.Weight = .regular
        static let semiboldWeight: Font.Weight = .semibold
        static let statusLabel: Font = Font.system(size: 11, weight: .medium)
        static let subjectMetric: Font = Font.system(size: 23, weight: .medium, design: .rounded)
        static let subjectSymbol: Font = Font.system(size: DesignSystem.SubjectAppearance.symbolSize, weight: .regular)
        static let title2: Font = Font.title2
        static let title3: Font = Font.title3
        static let ultraLightWeight: Font.Weight = .ultraLight
        static let welcomeSymbol: Font = Font.system(size: 52)
        static func segmented(selected: Bool) -> Font { .system(size: 12, weight: selected ? .semibold : .regular) }
    }
    enum PreservedGeometry {
        static let points920: CGFloat = 920
        static let points550: CGFloat = 550
        static let points1140: CGFloat = 1140
        static let points790: CGFloat = 790
        static let gap10: CGFloat = 10
        static let gap11: CGFloat = 11
        static let gap28: CGFloat = 28
        static let gap3: CGFloat = 3
        static let gap36: CGFloat = 36
        static let gap40: CGFloat = 40
        static let gap5: CGFloat = 5
        static let minimumScale0_6: CGFloat = 0.6
        static let minimumScale0_8: CGFloat = 0.8
        static let points1: CGFloat = 1
        static let points132: CGFloat = 132
        static let points2: CGFloat = 2
        static let points220: CGFloat = 220
        static let points230: CGFloat = 230
        static let points240: CGFloat = 240
        static let points260: CGFloat = 260
        static let points280: CGFloat = 280
        static let points300: CGFloat = 300
        static let points310: CGFloat = 310
        static let points320: CGFloat = 320
        static let points340: CGFloat = 340
        static let points350: CGFloat = 350
        static let points360: CGFloat = 360
        static let points380: CGFloat = 380
        static let points40: CGFloat = 40
        static let points400: CGFloat = 400
        static let points420: CGFloat = 420
        static let points440: CGFloat = 440
        static let points45: CGFloat = 45
        static let points470: CGFloat = 470
        static let points480: CGFloat = 480
        static let points650: CGFloat = 650
        static let points9: CGFloat = 9
        static let radius10: CGFloat = 10
        static let radius9: CGFloat = 9
        static let stroke1: CGFloat = 1
    }
    enum PreservedAppearance {
        static let opacity0_035: Double = 0.035
        static let opacity0_055: Double = 0.055
        static let opacity0_07: Double = 0.07
        static let opacity0_08: Double = 0.08
        static let opacity0_09: Double = 0.09
        static let opacity0_10: Double = 0.10
        static let opacity0_11: Double = 0.11
        static let opacity0_12: Double = 0.12
        static let opacity0_13: Double = 0.13
        static let opacity0_15: Double = 0.15
        static let opacity0_16: Double = 0.16
        static let opacity0_22: Double = 0.22
        static let opacity0_30: Double = 0.30
        static let opacity0_35: Double = 0.35
        static let opacity0_4: Double = 0.4
        static let opacity0_45: Double = 0.45
        static let opacity0_5: Double = 0.5
        static let opacity0_55: Double = 0.55
        static let opacity0_65: Double = 0.65
        static let opacity0_75: Double = 0.75
        static let opacity0_76: Double = 0.76
        static let opacity0_90: Double = 0.90
        static let destructiveInk = Color.mutedRed
        static let amberInk = Color.softAmber
    }
}


extension DesignSystem {
    enum PreservedColors {
    // Readable ink and pastel surfaces are separate: a soft fill never forces pale text.
    static let sage = Color.adaptive((0.30, 0.37, 0.32), (0.70, 0.76, 0.71))
    static let sageFill = Color.adaptive((0.83, 0.88, 0.82), (0.29, 0.35, 0.31))
    static let softTeal = Color.adaptive((0.35, 0.48, 0.47), (0.66, 0.76, 0.74))
    static let softAmber = Color.adaptive((0.55, 0.43, 0.31), (0.79, 0.71, 0.60))
    static let mutedRed = Color.adaptive((0.61, 0.34, 0.35), (0.83, 0.62, 0.63))
    static let cream = Color(red: 0.975, green: 0.965, blue: 0.94)
    static let subjectChoices: [SubjectColorChoice] = [
        .init(id: "classici.salvia", name: "Salvia", ink: .sage),
        .init(id: "classici.azzurro-polvere", name: "Azzurro polvere", ink: .adaptive((0.36, 0.46, 0.55), (0.67, 0.75, 0.82))),
        .init(id: "classici.lavanda", name: "Lavanda", ink: .adaptive((0.48, 0.42, 0.56), (0.76, 0.71, 0.82))),
        .init(id: "classici.rosa-antico", name: "Rosa antico", ink: .adaptive((0.57, 0.36, 0.40), (0.83, 0.66, 0.69))),
        .init(id: "classici.terracotta", name: "Terracotta", ink: .adaptive((0.57, 0.37, 0.29), (0.84, 0.66, 0.55))),
        .init(id: "classici.ocra", name: "Ocra", ink: .softAmber),
        .init(id: "classici.verde-muschio", name: "Verde muschio", ink: .adaptive((0.39, 0.44, 0.29), (0.73, 0.77, 0.59))),
        .init(id: "classici.grigio-caldo", name: "Grigio caldo", ink: .adaptive((0.44, 0.42, 0.38), (0.76, 0.73, 0.66)))
    ]
    }
    enum PreservedDecoration {
        static let frameInterval: Double = 1.0 / 20
        static let ringFrameInterval: Double = 1.0 / 30
        static let lightDiameter: CGFloat = 0.65
        static let lightX: Double = 0.70
        static let lightY: CGFloat = 0.25
        static let driftPeriod: Double = 45
        static let driftAmplitude: Double = 0.12
        static let hillBase: Double = 0.64
        static let hillOffset: Double = 0.10
        static let hillOverdraw: CGFloat = 10
        static let hillControlX1: CGFloat = 0.3
        static let hillControlX2: CGFloat = 0.7
        static let hillControlY1: CGFloat = 0.22
        static let hillControlY2: CGFloat = 0.13
        static let hillOpacityStep: Double = 0.015
        static let hillCount: Int = 3
        static let particleCount: Int = 5
        static let particleSeedX: Double = 137
        static let particleSeedY: Double = 83
        static let particlePeriod: Double = 19
        static let particleDrift: Double = 18
        static let particleSpeed: Double = 1.2
        static let parallax: Double = 1.5
        static let ringRotation: Double = -90
        static let sidebarMaterial: Material = .ultraThinMaterial
    }
    enum PreservedMotion {
        static let springResponse = 0.32, springDamping = 0.86
        static let sliderDragScale: CGFloat = 1.15
        static let chartHeadroom = 1.35
        static let ruleDash: [CGFloat] = [3, 4]
    }
}

private struct SectionVisibleKey: EnvironmentKey { static let defaultValue = true }
private struct MotionLevelKey: EnvironmentKey { static let defaultValue = "Reduced" }
extension EnvironmentValues {
    var komorebiSectionVisible: Bool {
        get { self[SectionVisibleKey.self] }
        set { self[SectionVisibleKey.self] = newValue }
    }
    var komorebiMotion: String {
        get { self[MotionLevelKey.self] }
        set { self[MotionLevelKey.self] = newValue }
    }
}
/// Only this small subtree listens to seconds. Hidden/inactive subtrees keep their
/// identity and drafts, but do not schedule body updates for a ticking clock.
struct LiveStudyTime<Content: View>: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.komorebiSectionVisible) private var visible
    @Environment(\.komorebiRendering) private var rendering
    @State private var date: Date?
    var updatesWhenIdle = false
    @ViewBuilder let content: (Date) -> Content
    var body: some View {
        content(date ?? store.now)
            .onReceive(store.clock.$now) { next in
                guard visible, rendering.visible, updatesWhenIdle || (store.active?.pausedAt == nil && store.active != nil) else { return }
                date = next
            }
            .onAppear { date = store.now }
            .onChange(of: visible) { if visible { date = store.now } }
            .onChange(of: rendering.visible) { if rendering.visible { date = store.now } }
            .onChange(of: store.active?.id) { date = store.now }
            .onChange(of: store.active?.pausedAt) { date = store.now }
    }
}

func interfaceAnimation(_ level: String, reduceMotion: Bool) -> Animation? {
    guard level != "Off", !reduceMotion else { return nil }
    return level == "Full" ? .spring(response: DesignSystem.PreservedMotion.springResponse, dampingFraction: DesignSystem.PreservedMotion.springDamping) : .easeOut(duration: DesignSystem.Interaction.hoverDuration)
}
/// One owner per pointer, with no focus/spotlight state attached to a label alone.
struct InteractiveHover: ViewModifier {
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.studyInteraction) private var session
    @Environment(\.isFocused) private var focused
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.komorebiSectionVisible) private var visible
    @Environment(\.komorebiRendering) private var rendering
    var cornerRadius: CGFloat = DesignSystem.Radius.control
    var textEntry = false
    var decorative = false
    var listRow = false
    var shape: StudyControlShape = .rounded
    var selected = false
    var identity: AnyHashable? = nil
    var hoverChanged: ((Bool) -> Void)? = nil
    @State private var hovering = false
    @State private var location = CGPoint.zero
    @State private var inputKind: StudyInputKind = .none
    private var active: Bool { enabled && visible && rendering.visible && hovering && !(focused && inputKind == .keyboard) }
    func body(content: Content) -> some View {
        content.contentShape(StudySurfaceShape(kind: shape, radius: cornerRadius))
            .background {
                StudyPointerTarget(session: session, eligible: enabled && visible && rendering.visible, decorative: decorative, textEntry: textEntry, radius: cornerRadius, shape: shape) { inside, point in
                    if hovering != inside { hovering = inside; hoverChanged?(inside) }
                    if inside && StudyHoverAppearance.spotlight(mode: appTheme.mode, listRow: listRow, selected: selected) && location != point { location = point }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).opacity(DesignSystem.Interaction.nativeProbeOpacity).allowsHitTesting(false).accessibilityHidden(true)
            }
            .overlay {
                StudyHoverDecoration(active: active, location: location, radius: cornerRadius, shape: shape, listRow: listRow, selected: selected)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .offset(y: StudyHoverAppearance.lifts(active: active, listRow: listRow, decorative: decorative, reduceMotion: reduceMotion, motion: motion) ? -DesignSystem.Interaction.hoverLift : 0)
            .onReceive(session?.$input.eraseToAnyPublisher() ?? Just(.none).eraseToAnyPublisher()) { inputKind = $0 }
            .onChange(of: visible) { if !visible { hovering = false; hoverChanged?(false) } }
            .onChange(of: rendering.visible) { if !rendering.visible { hovering = false; hoverChanged?(false) } }
            .onChange(of: enabled) { if !enabled { hovering = false; hoverChanged?(false) } }
            .onChange(of: identity) { session?.resetHover(); hovering = false; hoverChanged?(false) }
            .onDisappear { hovering = false; hoverChanged?(false) }
            .animation(motion == "Off" || reduceMotion ? nil : .easeOut(duration: DesignSystem.Interaction.hoverDuration), value: active)
    }
}
extension View {
    func interactiveHover(cornerRadius: CGFloat = DesignSystem.Radius.control, textEntry: Bool = false, decorative: Bool = false, listRow: Bool = false, shape: StudyControlShape = .rounded, selected: Bool = false, identity: AnyHashable? = nil, hoverChanged: ((Bool) -> Void)? = nil) -> some View {
        modifier(InteractiveHover(cornerRadius: cornerRadius, textEntry: textEntry, decorative: decorative, listRow: listRow, shape: shape, selected: selected, identity: identity, hoverChanged: hoverChanged))
    }
}
struct KeyboardFocusBorder: ViewModifier {
    @Environment(\.studyInteraction) private var session
    @Environment(\.isFocused) private var focused
    @FocusState private var controlFocused: Bool
    var radius: CGFloat = DesignSystem.Radius.control
    var explicitFocus: Bool? = nil
    var shape: StudyControlShape = .rounded
    @ViewBuilder func body(content: Content) -> some View {
        if let explicitFocus {
            // Keep existing component bindings intact; never attach a competing one.
            content.focusEffectDisabled().overlay { outline(explicitFocus) }
        } else {
            // Plain buttons outside a ButtonStyle need their own focus binding.
            // Style labels also inherit isFocused from the button itself.
            content.focused($controlFocused).focusEffectDisabled().overlay { outline(controlFocused || focused) }
        }
    }
    @ViewBuilder private func outline(_ active: Bool) -> some View {
        if let session { KeyboardFocusOutline(session: session, focused: active, radius: radius, shape: shape) }
    }
}
struct StudyActionStyle: ButtonStyle {
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        ActionLabel(configuration: configuration, enabled: enabled, dark: scheme == .dark, animated: motion != "Off" && !reduceMotion)
    }
    private struct ActionLabel: View {
    @Environment(\.studyTheme) private var appTheme
        let configuration: ButtonStyle.Configuration
        let enabled: Bool
        let dark: Bool
        let animated: Bool
        @State private var hover = false
        var body: some View {
            configuration.label.font(appTheme.typography.control)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .frame(minHeight: DesignSystem.Interaction.actionHeight)
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
                .foregroundStyle(enabled ? appTheme.palette.onAction : appTheme.palette.onDisabledAction)
                .background(!enabled ? appTheme.palette.disabledAction : configuration.isPressed ? (appTheme.palette.actionPressed ?? (hover ? appTheme.palette.actionHover : appTheme.palette.action)) : hover ? appTheme.palette.actionHover : appTheme.palette.action, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.action))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.action).stroke(appTheme.palette.accent.opacity(enabled && dark ? appTheme.appearance.opacity0_35 : 0)).allowsHitTesting(false))
                .shadow(color: appTheme.shadows.medium.color.opacity(!enabled || dark ? 0 : 1), radius: appTheme.shadows.medium.radius, y: appTheme.shadows.medium.y)
                .scaleEffect(enabled && configuration.isPressed && animated ? DesignSystem.Interaction.pressedScale : 1)
                .opacity(1)
                .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.action))
                .interactiveHover(cornerRadius: DesignSystem.Radius.action, hoverChanged: { hover = $0 })
                .animation(animated ? .easeOut(duration: DesignSystem.Interaction.hoverDuration) : nil, value: configuration.isPressed)
                .animation(animated ? .easeOut(duration: DesignSystem.Interaction.hoverDuration) : nil, value: hover)
        }
    }
}
struct ResponsiveButtonStyle: ButtonStyle {
    @Environment(\.studyTheme) private var appTheme
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Spacing.sm).padding(.vertical, DesignSystem.Spacing.xs)
            .frame(minHeight: DesignSystem.Interaction.controlHeight)
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.PreservedGeometry.radius9))
            .foregroundStyle((enabled ? nil : appTheme.palette.disabledText) ?? (configuration.role == .destructive ? appTheme.palette.buttonDestructiveInk : prominent ? appTheme.palette.onAccentSurface : appTheme.palette.accent))
            .background(!enabled ? appTheme.palette.disabledAction : configuration.role == .destructive ? appTheme.palette.buttonDestructiveInk.opacity(configuration.isPressed ? appTheme.appearance.opacity0_16 : appTheme.appearance.opacity0_07) : prominent ? appTheme.palette.accentSurface.opacity(configuration.isPressed ? appTheme.appearance.opacity0_76 : 1) : appTheme.palette.accent.opacity(configuration.isPressed ? appTheme.appearance.opacity0_13 : appTheme.appearance.opacity0_055), in: RoundedRectangle(cornerRadius: DesignSystem.PreservedGeometry.radius9))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.PreservedGeometry.radius9).stroke(appTheme.palette.accent.opacity(enabled && prominent ? appTheme.appearance.opacity0_13 : 0)).allowsHitTesting(false))
            .scaleEffect(enabled && configuration.isPressed && motion == "Full" && !reduceMotion ? DesignSystem.Interaction.pressedScale : 1)
            .opacity(1)
            .animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: configuration.isPressed)
            .modifier(KeyboardFocusBorder(radius: DesignSystem.PreservedGeometry.radius9))
            .interactiveHover(cornerRadius: DesignSystem.PreservedGeometry.radius9)
    }
}
struct PastelSegmentedControl<Value: Hashable>: View {
    @Environment(\.studyTheme) private var appTheme
    let title: String
    let values: [Value]
    @Binding var selection: Value
    let label: (Value) -> String
    @Namespace private var selectionAnimation
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    init(_ title: String, values: [Value], selection: Binding<Value>, label: @escaping (Value) -> String) {
        self.title = title; self.values = values; _selection = selection; self.label = label
    }
    var body: some View {
        HStack(spacing: DesignSystem.PreservedGeometry.gap3) {
            ForEach(values, id: \.self) { value in
                Button { selection = value } label: {
                    Text(label(value)).font(appTheme.preservedTypography.segmented(selected: selection == value))
                        .lineLimit(1).frame(maxWidth: .infinity).frame(height: DesignSystem.Interaction.controlHeight).padding(.horizontal, DesignSystem.Spacing.xxs)
                        .foregroundStyle(selection == value ? appTheme.palette.onAccentSurface : appTheme.palette.textPrimary)
                        .background {
                            if selection == value {
                                Capsule().fill(appTheme.palette.accentSurface).matchedGeometryEffect(id: "selection", in: selectionAnimation)
                            }
                        }.contentShape(Capsule())
                }.buttonStyle(.plain).modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.panel)).interactiveHover(cornerRadius: DesignSystem.Radius.panel)
                    .accessibilityLabel(title + ", " + label(value))
                    .accessibilityAddTraits(selection == value ? .isSelected : [])
            }
        }.background(appTheme.palette.accent.opacity(appTheme.appearance.opacity0_055), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            .animation(motion == "Off" || reduceMotion ? nil : .easeOut(duration: DesignSystem.Interaction.sectionDuration), value: selection)
            .onMoveCommand { direction in
                guard let index = values.firstIndex(of: selection) else { return }
                if direction == .left, index > 0 { selection = values[index - 1] }
                if direction == .right, index + 1 < values.count { selection = values[index + 1] }
            }
    }
}
struct Card<Content: View>: View {
    @Environment(\.studyTheme) private var appTheme
    var stretches = false
    var identity: AnyHashable? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) { content }
            .frame(maxWidth: .infinity, maxHeight: stretches ? .infinity : nil, alignment: .topLeading)
            .padding(DesignSystem.Spacing.xl)
            .background(appTheme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card).stroke(appTheme.palette.border.opacity(appTheme.appearance.opacity0_35)).allowsHitTesting(false))
            .interactiveHover(cornerRadius: DesignSystem.Radius.card, decorative: true, identity: identity)
    }
}
struct Metric: View {
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var title: String; var value: String; var icon: String
    var body: some View { Card(stretches: true) { Label(title, systemImage: icon).foregroundStyle(appTheme.palette.textSecondary); Text(value).font(appTheme.typography.title).monospacedDigit().lineLimit(2).minimumScaleFactor(DesignSystem.PreservedGeometry.minimumScale0_8).contentTransition(.numericText()).animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: value) } }
}
struct GoalBar: View {
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var title: String; var value: Double; var goal: Double
    var color: Color? = nil
    var body: some View {
        let color = color ?? appTheme.palette.accent
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.legacy9) {
            HStack { Text(title); Spacer(); Text("\(durationText(value)) / \(durationText(goal))").foregroundStyle(appTheme.palette.textSecondary) }
            StudyProgressBar(value: min(value, max(1, goal)), total: max(1, goal), color: color).animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: value)
        }
    }
}
struct Landscape: View {
    @Environment(\.studyTheme) private var appTheme
    var theme: String
    var animations = "Reduced"
    var driftingLight = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pointer = CGSize.zero
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    @Environment(\.komorebiRendering) private var rendering
    private var moving: Bool { sectionVisible && rendering.ambientMotion && !reduceMotion && animations != "Off" }
    var body: some View {
        if appTheme.decoration.atmosphere == .moonlit {
            if appTheme.decorationsEnabled { MoonlitLandscape(animations: animations) }
            else { appTheme.palette.surface.allowsHitTesting(false).accessibilityHidden(true) }
        } else {

        TimelineView(.animation(minimumInterval: appTheme.decoration.frameInterval, paused: !moving)) { timeline in
            GeometryReader { geometry in
                let size = geometry.size
                let t = moving ? timeline.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    appTheme.palette.background
                    appTheme.palette.landscapeTint(theme)
                    Ellipse().fill(appTheme.palette.light.opacity(appTheme.appearance.opacity0_16))
                        .frame(width: size.width * appTheme.decoration.lightDiameter, height: size.height * appTheme.decoration.lightDiameter)
                        .blur(radius: DesignSystem.Spacing.xxl)
                        .position(x: size.width * (appTheme.decoration.lightX + (driftingLight ? sin(t / appTheme.decoration.driftPeriod) * appTheme.decoration.driftAmplitude : 0)), y: size.height * appTheme.decoration.lightY)
                    LandscapeHills(size: size, pointer: pointer, moving: moving)
                    if moving {
                        Canvas { context, canvasSize in
                            for n in 0..<appTheme.decoration.particleCount {
                                let x = (Double(n) * appTheme.decoration.particleSeedX + sin(t / appTheme.decoration.particlePeriod + Double(n)) * appTheme.decoration.particleDrift + canvasSize.width).truncatingRemainder(dividingBy: max(1, canvasSize.width))
                                let y = (Double(n) * appTheme.decoration.particleSeedY + t * appTheme.decoration.particleSpeed).truncatingRemainder(dividingBy: max(1, canvasSize.height))
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: DesignSystem.PreservedGeometry.points2, height: DesignSystem.PreservedGeometry.points2)), with: .color(appTheme.palette.light.opacity(appTheme.appearance.opacity0_09)))
                            }
                        }.allowsHitTesting(false)
                    }
                }
                .onContinuousHover { phase in
                    guard moving else { pointer = .zero; return }
                    switch phase {
                    case .active(let point): pointer = CGSize(width: (point.x / max(1, size.width) - 0.5) * appTheme.decoration.parallax, height: (point.y / max(1, size.height) - 0.5) * appTheme.decoration.parallax)
                    case .ended: pointer = .zero
                    }
                }
            }
        }.accessibilityHidden(true)
        }
    }
}

struct ProgressRing: View {
    @Environment(\.studyTheme) private var appTheme
    var value: Double
    var total: Double
    var color: Color? = nil
    var lineWidth: CGFloat = DesignSystem.PreservedGeometry.gap5
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var fraction: Double { min(1, max(0, value / max(1, total))) }
    var body: some View {
        let color = color ?? appTheme.palette.accent
        ZStack {
            Circle().stroke(color.opacity(appTheme.appearance.opacity0_13), lineWidth: lineWidth)
            Circle().trim(from: 0, to: fraction)
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(appTheme.decoration.ringRotation))
        }.animation(interfaceAnimation(motion, reduceMotion: reduceMotion), value: fraction)
            .accessibilityHidden(true)
    }
}
/// Dedicated Timer ring; overview and goal rings retain their existing style.
struct TimerProgressRing: View {
    @Environment(\.studyTheme) private var appTheme
    let value: Double
    let total: Double?
    var running = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.komorebiSectionVisible) private var visible
    @Environment(\.komorebiRendering) private var rendering
    @State private var origin = Date()
    private var candleActive: Bool { running && appTheme.decoration.candle && ThemeAnimationPolicy.moving(visible: visible && rendering.ambientMotion && scenePhase != .background, decorations: appTheme.decorationsEnabled, reduceMotion: reduceMotion, animations: motion) }
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var fraction: Double {
        guard let total else { return 0 }
        return min(1, max(0, value / max(1, total)))
    }
    private var gradient: LinearGradient {
        LinearGradient(colors: [appTheme.palette.timerGradientStart, appTheme.palette.timerGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        TimelineView(.animation(minimumInterval: appTheme.decoration.ringFrameInterval, paused: !candleActive)) { timeline in
            ring(glow: ThemeAnimationPolicy.candleOpacity(elapsed: timeline.date.timeIntervalSince(origin), decoration: appTheme.decoration, active: candleActive))
        }.accessibilityHidden(true)
    }
    private func ring(glow: Double) -> some View {
        ZStack {
            Circle().strokeBorder(appTheme.palette.timerTrack, lineWidth: DesignSystem.TimerLayout.ringWidth)
            Circle().inset(by: DesignSystem.TimerLayout.ringWidth / 2)
                .trim(from: 0, to: fraction)
                .stroke(gradient, style: StrokeStyle(lineWidth: DesignSystem.TimerLayout.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(appTheme.decoration.ringRotation))
                .opacity(fraction > 0 ? 1 : 0)
                .blur(radius: DesignSystem.TimerLayout.glowRadius)
                .opacity(DesignSystem.TimerLayout.glowOpacity * glow)
                .clipShape(Circle())
            Circle().inset(by: DesignSystem.TimerLayout.ringWidth / 2)
                .trim(from: 0, to: fraction)
                .stroke(gradient, style: StrokeStyle(lineWidth: DesignSystem.TimerLayout.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(appTheme.decoration.ringRotation))
                .opacity(fraction > 0 ? 1 : 0)
        }
        .animation(motion == "Off" || reduceMotion || !visible || !rendering.visible ? nil : .easeOut(duration: DesignSystem.TimerLayout.progressDuration), value: fraction)
        .accessibilityHidden(true)
    }
}
struct SessionStatusPill: View {
    @Environment(\.studyTheme) private var appTheme
    @EnvironmentObject var store: StudyStore
    var color: Color { store.active?.isBreak == true ? appTheme.palette.interval : store.active?.pausedAt != nil ? appTheme.appearance.amberInk : appTheme.palette.accent }
    var icon: String { store.active?.isBreak == true ? "cup.and.saucer" : store.active?.pausedAt != nil ? "pause.circle" : store.active == nil ? "book.closed" : "book" }
    var body: some View {
        Label {
            Text(store.stateText).foregroundStyle(appTheme.palette.textPrimary)
        } icon: {
            Image(systemName: icon).foregroundStyle(color)
        }
            .font(appTheme.preservedTypography.statusLabel)
            .padding(.horizontal, DesignSystem.PreservedGeometry.gap11).padding(.vertical, DesignSystem.Spacing.legacy7)
            .foregroundStyle(color).background(color.opacity(appTheme.appearance.opacity0_11), in: Capsule())
    }
}

struct StudyVolumeSlider: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @Binding var value: Double
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    @State private var dragging = false
    @FocusState private var focused: Bool
    private var fraction: Double { min(1, max(0, value)) }
    var body: some View {
        GeometryReader { geometry in
            let travel = max(1, geometry.size.width - DesignSystem.Interaction.thumbSize)
            ZStack(alignment: .leading) {
                Capsule().fill(appTheme.palette.sliderTrack).frame(height: DesignSystem.Interaction.sliderTrack)
                Capsule().fill(appTheme.palette.accent).frame(width: DesignSystem.Interaction.thumbSize / 2 + travel * fraction, height: DesignSystem.Interaction.sliderTrack)
                Circle().fill(appTheme.palette.accent)
                    .frame(width: DesignSystem.Interaction.thumbSize, height: DesignSystem.Interaction.thumbSize)
                    .shadow(color: appTheme.shadows.low.color, radius: appTheme.shadows.low.radius, y: appTheme.shadows.low.y)
                    .scaleEffect(dragging && !reduceMotion && motion != "Off" ? appTheme.motion.sliderDragScale : 1)
                    .offset(x: travel * fraction)
            }.frame(maxHeight: .infinity).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    guard enabled else { return }; focused = true; dragging = true
                    value = min(1, max(0, (drag.location.x - DesignSystem.Interaction.thumbSize / 2) / travel))
                }.onEnded { _ in dragging = false })
        }.frame(height: DesignSystem.Interaction.controlHeight)
            .focusable(enabled).focused($focused)
            .modifier(KeyboardFocusBorder(explicitFocus: focused))
            .interactiveHover().opacity(enabled ? 1 : appTheme.appearance.disabledOpacity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.tr("Volume ambiente")).accessibilityValue(L10n.tr("%@ per cento" , String(describing: Int(fraction * 100))))
            .accessibilityRepresentation {
                Slider(value: $value, in: 0...1).accessibilityLabel(L10n.tr("Volume ambiente")).disabled(!enabled)
            }
            .onMoveCommand { direction in
                if direction == .right || direction == .up { adjust(0.05) }
                if direction == .left || direction == .down { adjust(-0.05) }
            }
            .animation(motion == "Off" || reduceMotion ? nil : .easeOut(duration: DesignSystem.Interaction.hoverDuration), value: dragging)
    }
    private func adjust(_ delta: Double) { if enabled { value = min(1, max(0, value + delta)) } }
}
struct DurationChip: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    let minutes: Int
    @Binding var value: Double
    private var selected: Bool { value == Double(minutes) }
    var body: some View {
        Button { value = Double(minutes) } label: {
            Text(L10n.tr("%@ min" , String(describing: minutes))).font(appTheme.typography.caption)
                .padding(.horizontal, DesignSystem.Spacing.sm).padding(.vertical, DesignSystem.Spacing.xs)
                .foregroundStyle(selected ? appTheme.palette.onAction : appTheme.palette.textSecondary)
                .background(selected ? appTheme.palette.action : appTheme.palette.surface, in: Capsule())
                .overlay(Capsule().stroke(selected ? appTheme.palette.action : appTheme.palette.border).allowsHitTesting(false))
                .contentShape(Capsule())
        }.buttonStyle(.plain).interactiveHover(cornerRadius: DesignSystem.Radius.panel)
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.panel))
            .accessibilityLabel(L10n.tr("%@ minuti" , String(describing: minutes))).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct StudyEmptyState: View {
    @Environment(\.studyTheme) private var appTheme
    let symbol: String
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if appTheme.copy.emptyIllustration == .ghost { ThemeGhost() }
            else {
            Image(systemName: appTheme.copy.text(.emptySymbol, fallback: symbol)).font(appTheme.typography.display).fontWeight(appTheme.preservedTypography.ultraLightWeight).foregroundStyle(appTheme.palette.accent).accessibilityHidden(true)
            }
            Text(appTheme.copy.text(.emptyTitle, fallback: title)).font(appTheme.typography.heading)
            Text(appTheme.copy.text(.emptyDetail, fallback: detail)).font(appTheme.typography.small).foregroundStyle(appTheme.palette.textSecondary).multilineTextAlignment(.center)
            Button(actionTitle, action: action).buttonStyle(StudyActionStyle())
        }.padding(DesignSystem.Spacing.xl).frame(maxWidth: .infinity)
    }
}

struct TimerRingMotion: ViewModifier {
    @Environment(\.studyTheme) private var appTheme
    let running: Bool
    let completion: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    @State private var origin = Date()
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    @Environment(\.komorebiRendering) private var rendering
    private var enabled: Bool { sectionVisible && rendering.ambientMotion && !reduceMotion && motion != "Off" }
    func body(content: Content) -> some View {
        let animate = enabled
        TimelineView(.animation(minimumInterval: appTheme.decoration.ringFrameInterval, paused: !running || !animate)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(origin))
            let wave = (1 - cos(elapsed * .pi / DesignSystem.Interaction.breatheDuration)) / 2
            content.scaleEffect(running && enabled ? 1 + wave * (DesignSystem.Interaction.breatheScale - 1) : 1)
        }
        .onChange(of: running) { origin = Date() }
        .keyframeAnimator(initialValue: CGFloat(1), trigger: completion) { view, scale in
            view.scaleEffect(animate ? scale : 1)
        } keyframes: { _ in
            CubicKeyframe(DesignSystem.Interaction.breatheScale, duration: DesignSystem.Interaction.chartDuration)
            CubicKeyframe(1, duration: DesignSystem.TimerLayout.progressDuration)
        }
    }
}

/// A single surface spans the sidebar and its header, avoiding separate material seams.
struct SidebarChromeSurface: View {
    @Environment(\.studyTheme) private var appTheme
    var body: some View {
        Rectangle().fill(appTheme.decoration.sidebarMaterial)
            .overlay(appTheme.palette.sidebar.opacity(appTheme.appearance.sidebarOpacity))
    }
}

struct StudyProgressBar: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    let value: Double
    let total: Double
    var color: Color? = nil
    private var fraction: Double { min(1, max(0, value / max(1, total))) }
    var body: some View {
        let color = color ?? appTheme.palette.accent
        GeometryReader { geometry in
            Capsule().fill(color.opacity(appTheme.appearance.opacity0_10))
                .overlay(alignment: .leading) {
                    Capsule().fill(color).frame(width: geometry.size.width * fraction).allowsHitTesting(false)
                }
        }.frame(height: DesignSystem.Spacing.legacy6)
            .accessibilityElement(children: .ignore).accessibilityLabel(L10n.tr("Progresso"))
            .accessibilityValue(L10n.tr("%@ per cento" , String(describing: Int(fraction * 100))))
            .allowsHitTesting(false)
    }
}

private struct LandscapeHills: View {
    @Environment(\.studyTheme) private var appTheme
    let size: CGSize
    var pointer = CGSize.zero
    var moving = false
    var body: some View {
                    ForEach(0..<appTheme.decoration.hillCount, id: \.self) { layer in
                        Path { path in
                            let base = size.height * (appTheme.decoration.hillBase + Double(layer) * appTheme.decoration.hillOffset)
                            path.move(to: CGPoint(x: -appTheme.decoration.hillOverdraw, y: base))
                            path.addCurve(to: CGPoint(x: size.width + appTheme.decoration.hillOverdraw, y: base), control1: CGPoint(x: size.width * appTheme.decoration.hillControlX1, y: base - size.height * appTheme.decoration.hillControlY1), control2: CGPoint(x: size.width * appTheme.decoration.hillControlX2, y: base + size.height * appTheme.decoration.hillControlY2))
                            path.addLine(to: CGPoint(x: size.width + appTheme.decoration.hillOverdraw, y: size.height + appTheme.decoration.hillOverdraw)); path.addLine(to: CGPoint(x: -appTheme.decoration.hillOverdraw, y: size.height + appTheme.decoration.hillOverdraw)); path.closeSubpath()
                        }
                        .fill(LinearGradient(colors: [appTheme.palette.hill.opacity(appTheme.decoration.hillOpacityBase + Double(layer) * appTheme.decoration.hillOpacityStep), .clear], startPoint: .top, endPoint: .bottom))
                        .blur(radius: DesignSystem.Spacing.xxs)
                        .offset(x: moving ? pointer.width * CGFloat(layer + 1) : 0, y: moving ? pointer.height * CGFloat(layer + 1) : 0)
                    }
    }
}

private struct MoonlitLandscape: View {
    @Environment(\.studyTheme) private var appTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.komorebiSectionVisible) private var visible
    @Environment(\.komorebiRendering) private var rendering
    let animations: String
    @State private var origin = Date()
    private var moving: Bool { ThemeAnimationPolicy.moving(visible: visible && rendering.ambientMotion && scenePhase != .background, decorations: appTheme.decorationsEnabled, reduceMotion: reduceMotion, animations: animations) }
    var body: some View {
        TimelineView(.animation(minimumInterval: appTheme.decoration.frameInterval, paused: !moving)) { timeline in
            GeometryReader { geometry in
                let size = geometry.size
                let d = appTheme.decoration
                let time = moving ? timeline.date.timeIntervalSince(origin) : 0
                let drift = sin(time / d.driftPeriod) * d.driftAmplitude
                ZStack {
                    appTheme.palette.background
                    LandscapeHills(size: size)
                    Circle().fill(appTheme.palette.light.opacity(d.moonHaloOpacity))
                        .frame(width: size.width * d.moonDiameter * d.moonHaloScale)
                        .blur(radius: DesignSystem.Spacing.xxl)
                        .position(x: size.width * (d.moonX + drift), y: size.height * d.moonY)
                    Circle().fill(appTheme.palette.light.opacity(d.moonDiscOpacity))
                        .frame(width: size.width * d.moonDiameter)
                        .position(x: size.width * (d.moonX + drift), y: size.height * d.moonY)
                    ThemeArtwork.branches.applying(CGAffineTransform(scaleX: size.width, y: size.height))
                        .stroke(appTheme.palette.hill.opacity(d.branchOpacity), style: StrokeStyle(lineWidth: d.branchWidth, lineCap: .round, lineJoin: .round))
                        .rotationEffect(.degrees(sin(time / d.driftPeriod) * d.branchSway), anchor: .topTrailing)
                    if moving {
                        Canvas { context, canvas in
                            for n in 0..<d.particleCount {
                                let x = (Double(n) * d.particleSeedX + sin(time / d.particlePeriod + Double(n)) * d.particleDrift + canvas.width).truncatingRemainder(dividingBy: max(1, canvas.width))
                                let y = (Double(n) * d.particleSeedY + time * d.particleSpeed).truncatingRemainder(dividingBy: max(1, canvas.height))
                                let pulse = ThemeArtwork.fireflyBase + ThemeArtwork.fireflyAmplitude * sin(time * 2 * .pi / d.fireflyPeriod + Double(n))
                                let rect = CGRect(x: x, y: y, width: d.fireflyDiameter, height: d.fireflyDiameter)
                                context.fill(Path(ellipseIn: rect), with: .color(d.fireflyTint.opacity(d.fireflyOpacity * pulse)))
                            }
                        }
                        if let phase = ThemeAnimationPolicy.batPhase(elapsed: time, decoration: d, moving: moving) {
                            ThemeArtwork.bat.applying(CGAffineTransform(scaleX: d.batSize, y: d.batSize * ThemeArtwork.batAspect))
                                .fill(appTheme.palette.hill).frame(width: d.batSize, height: d.batSize * ThemeArtwork.batAspect).opacity(d.batOpacity)
                                .position(x: size.width * phase, y: size.height * ThemeArtwork.batY)
                        }
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
private struct ThemeGhost: View {
    @Environment(\.studyTheme) private var appTheme
    var body: some View {
        GeometryReader { geometry in
            ThemeArtwork.ghost.applying(CGAffineTransform(scaleX: geometry.size.width, y: geometry.size.height))
                .stroke(appTheme.palette.accent, style: StrokeStyle(lineWidth: appTheme.decoration.ghostStroke, lineCap: .round, lineJoin: .round))
        }.frame(width: appTheme.decoration.ghostSize, height: appTheme.decoration.ghostSize)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension DesignSystem {
    enum SidebarToggle {
        static let size: CGFloat = 32
        static let glyphWidth: CGFloat = 18
        static let glyphHeight: CGFloat = 14
        static let glyphRadius: CGFloat = 2
        static let glyphStroke: CGFloat = 1.2
        static let panelWidth: CGFloat = 6
        static let hitSurfaceOpacity = 1.0 / 1024
        static let hoverOpacity = 0.07
        static let pressedOpacity = 0.12
        static let pressedScale: CGFloat = 0.96
        static let hoverDuration = 0.12
        static let fadeDuration = 0.15
        static let resizeDuration = 0.25
        static func duration(reduceMotion: Bool, animations: String) -> Double {
            reduceMotion || animations == "Off" ? 0 : resizeDuration
        }
        static let collapsedHeaderInset = Layout.windowControlsSpace + size + Spacing.sm - Layout.contentPadding
    }
}
/// A ghost control with its own hover treatment; intentionally excludes InteractiveHover/spotlight.
struct SidebarGhostToggle: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    @FocusState private var focused: Bool
    let isOpen: Bool
    let action: () -> Void
    private var animated: Bool { !reduceMotion && motion != "Off" }
    private var title: String { isOpen ? L10n.tr("Nascondi barra laterale") : L10n.tr("Mostra barra laterale") }
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.SidebarToggle.glyphRadius)
                    .stroke(lineWidth: DesignSystem.SidebarToggle.glyphStroke)
                HStack(spacing: 0) {
                    ZStack {
                        Rectangle().fill().opacity(isOpen ? 1 : 0)
                        Rectangle().stroke(lineWidth: DesignSystem.SidebarToggle.glyphStroke).opacity(isOpen ? 0 : 1)
                    }.frame(width: DesignSystem.SidebarToggle.panelWidth)
                    Spacer(minLength: 0)
                }.clipShape(RoundedRectangle(cornerRadius: DesignSystem.SidebarToggle.glyphRadius))
            }.frame(width: DesignSystem.SidebarToggle.glyphWidth, height: DesignSystem.SidebarToggle.glyphHeight)
                .animation(animated ? .easeOut(duration: DesignSystem.SidebarToggle.fadeDuration) : nil, value: isOpen)
                .frame(width: DesignSystem.SidebarToggle.size, height: DesignSystem.SidebarToggle.size)
                .background(theme.palette.textSecondary.opacity(DesignSystem.SidebarToggle.hitSurfaceOpacity))
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
        }.buttonStyle(SidebarGhostStyle())
            .focusable().focused($focused).focusEffectDisabled()
            .onKeyPress(.space) { action(); return .handled }
            .modifier(KeyboardFocusBorder(radius: DesignSystem.Radius.control, explicitFocus: focused))
            .accessibilityLabel(title + " (⌃⌘S)").help(title + " (⌃⌘S)")
    }
}
private struct SidebarGhostStyle: ButtonStyle {
    @Environment(\.studyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.komorebiMotion) private var motion
    func makeBody(configuration: Configuration) -> some View {
        GhostLabel(configuration: configuration, animated: !reduceMotion && motion != "Off")
    }
    private struct GhostLabel: View {
        @Environment(\.studyTheme) private var theme
        @Environment(\.isEnabled) private var enabled
        let configuration: ButtonStyle.Configuration
        let animated: Bool
        @State private var hovered = false
        @Environment(\.studyInteraction) private var session
        @Environment(\.komorebiRendering) private var rendering
        var body: some View {
            configuration.label
                .foregroundStyle(!enabled ? theme.palette.onDisabledAction : hovered ? theme.palette.textPrimary : theme.palette.textSecondary)
                .background(enabled ? theme.palette.accent.opacity(configuration.isPressed ? DesignSystem.SidebarToggle.pressedOpacity : hovered ? DesignSystem.SidebarToggle.hoverOpacity : 0) : theme.palette.disabledAction, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .scaleEffect(enabled && configuration.isPressed && animated ? DesignSystem.SidebarToggle.pressedScale : 1)
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .background {
                    StudyPointerTarget(session: session, eligible: enabled && rendering.visible, decorative: false, textEntry: false, radius: DesignSystem.Radius.control, shape: .rounded) { hovered = $0; _ = $1 }
                        .opacity(DesignSystem.Interaction.nativeProbeOpacity).allowsHitTesting(false).accessibilityHidden(true)
                }
                .onDisappear { hovered = false }
                .animation(animated ? .easeOut(duration: DesignSystem.SidebarToggle.hoverDuration) : nil, value: hovered)
                .animation(animated ? .easeOut(duration: DesignSystem.SidebarToggle.hoverDuration) : nil, value: configuration.isPressed)
        }
    }
}

/// Retains HStack width allocation while proposing the tallest intrinsic height to all cards.
struct EqualHeightCardRow<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: Content
    var body: some View {
        HStack(alignment: .top, spacing: spacing) { content }
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Window-level events, never a polling timer. Does not affect the study clock.
struct RenderingState: Equatable {
    var visible = true
    var lowPower = false
    var ambientMotion: Bool { visible && !lowPower }
    static func resolve(windowVisible: Bool, miniaturized: Bool, occluded: Bool, appActive: Bool, lowPower: Bool) -> Self {
        Self(visible: windowVisible && !miniaturized && !occluded && appActive, lowPower: lowPower)
    }
}
private struct RenderingStateKey: EnvironmentKey { static let defaultValue = RenderingState() }
extension EnvironmentValues {
    var komorebiRendering: RenderingState {
        get { self[RenderingStateKey.self] }
        set { self[RenderingStateKey.self] = newValue }
    }
}
private struct RenderingLifecycle: ViewModifier {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    @State private var state = RenderingState()
    var allowInactive = false
    func body(content: Content) -> some View {
        content.environment(\.komorebiRendering, state)
            .background { WindowRenderingProbe(allowInactive: allowInactive) { if state != $0 { state = $0 } }.opacity(DesignSystem.Interaction.nativeProbeOpacity).allowsHitTesting(false).accessibilityHidden(true) }
            .overlay(alignment: .bottomTrailing) {
                if state.lowPower {
                    Label(L10n.tr("Risparmio energetico · decorazioni in pausa"), systemImage: "leaf")
                        .font(theme.typography.caption).foregroundStyle(theme.palette.textSecondary)
                        .padding(DesignSystem.Spacing.sm)
                        .background(theme.palette.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                        .padding(DesignSystem.Spacing.sm)
                        .allowsHitTesting(false)
                }
            }
    }
}
extension View {
    func renderingLifecycle(allowInactive: Bool = false) -> some View { modifier(RenderingLifecycle(allowInactive: allowInactive)) }
}
private struct WindowRenderingProbe: NSViewRepresentable {
    let allowInactive: Bool
    let changed: (RenderingState) -> Void
    func makeNSView(context: Context) -> Host { Host(allowInactive: allowInactive, changed: changed) }
    func updateNSView(_ view: Host, context: Context) { view.changed = changed; view.allowInactive = allowInactive }
    static func dismantleNSView(_ view: Host, coordinator: ()) { view.stop() }
    final class Host: NSView {
        var changed: (RenderingState) -> Void
        var allowInactive: Bool
        private var observers: [NSObjectProtocol] = []
        private var pending = false
        private var stopped = false
        init(allowInactive: Bool, changed: @escaping (RenderingState) -> Void) {
            self.allowInactive = allowInactive; self.changed = changed; super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); stop(); stopped = false
            guard let window else { return }
            let center = NotificationCenter.default
            for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification] {
                observers.append(center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in self?.schedule() })
            }
            for name in [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification, Notification.Name.NSProcessInfoPowerStateDidChange] {
                observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.schedule() })
            }
            schedule()
        }
        private func schedule() {
            guard !pending, !stopped else { return }; pending = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }; self.pending = false
                guard !self.stopped, let window = self.window else { return }
                self.changed(RenderingState.resolve(windowVisible: window.isVisible, miniaturized: window.isMiniaturized,
                    occluded: !window.occlusionState.contains(.visible), appActive: NSApp.isActive || self.allowInactive,
                    lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled))
            }
        }
        func stop() {
            stopped = true
            for observer in observers { NotificationCenter.default.removeObserver(observer) }
            observers.removeAll()
        }
        deinit { for observer in observers { NotificationCenter.default.removeObserver(observer) } }
    }
}

// One interaction session per window host. Events are observed, never consumed.
enum StudyInputKind { case none, pointer, keyboard }
enum StudyFocusPolicy {
    static func showsRing(focused: Bool, input: StudyInputKind, enabled: Bool, visible: Bool) -> Bool {
        focused && input == .keyboard && enabled && visible
    }
    static func isNavigationKey(_ code: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        modifiers.intersection([.command, .control, .option]).isEmpty && [48, 123, 124, 125, 126].contains(code)
    }
}
private struct StudyInteractionKey: EnvironmentKey { static let defaultValue: StudyInteractionSession? = nil }
extension EnvironmentValues {
    var studyInteraction: StudyInteractionSession? {
        get { self[StudyInteractionKey.self] }
        set { self[StudyInteractionKey.self] = newValue }
    }
}
@MainActor final class StudyInteractionSession: NSObject, ObservableObject {
    @Published private(set) var input: StudyInputKind = .none
    private var monitor: Any?
    private var pointerDisplayLink: CADisplayLink?
    private var pointerFrameTarget: PointerFrameTarget?
    private weak var pendingPointerWindow: NSWindow?
    var pointerFramePending: Bool { pendingPointerWindow != nil }
    private var scrollTracking: [ObjectIdentifier: ScrollTracking] = [:]
    var scrollContainerCount: Int { scrollTracking.count }
    @MainActor private struct ScrollTracking {
        weak var clip: NSClipView?
        let observer: NSObjectProtocol
    }
    @MainActor private final class PointerFrameTarget: NSObject {
        weak var session: StudyInteractionSession?
        weak var link: CADisplayLink?
        func invalidate() { link?.invalidate() }
        init(_ session: StudyInteractionSession) { self.session = session }
        @objc func frame(_ link: CADisplayLink) { session?.flushPointerFrame() }
    }
    private var tracking: [ObjectIdentifier: WindowTracking] = [:]
    @MainActor private struct WindowTracking {
        weak var window: NSWindow?
        weak var content: NSView?
        let area: NSTrackingArea
        let previousMouseMoves: Bool
    }
    private weak var host: NSView?
    private var targets: [ObjectIdentifier: WeakTarget] = [:]
    private weak var active: StudyPointerTarget.Host?
    private var suppressed = false
    private var lastTimestamp: TimeInterval = -1
    private struct WeakTarget { weak var view: StudyPointerTarget.Host? }
    func start(host: NSView) {
        stop(); self.host = host
        if let window = host.window { track(window) }
        // Coalesce high-rate mouse input to this view's display. The link is paused
        // immediately after each requested frame: no continuous idle polling.
        let target = PointerFrameTarget(self)
        pointerFrameTarget = target
        let link = (host.window?.contentView ?? host).displayLink(target: target, selector: #selector(PointerFrameTarget.frame(_:)))
        target.link = link
        link.isPaused = true
        link.add(to: .main, forMode: .common)
        pointerDisplayLink = link
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .mouseMoved, .leftMouseDragged, .scrollWheel]) { [weak self] event in
            self?.receive(event); return event
        }
    }
    func receive(_ event: NSEvent) {
        guard let window = event.window, window == host?.window || targets.values.contains(where: { $0.view?.window == window }) else { return }
        switch event.type {
        case .keyDown:
            if StudyFocusPolicy.isNavigationKey(event.keyCode, modifiers: event.modifierFlags) { setInput(.keyboard); resetHover() }
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            setInput(.pointer)
        case .scrollWheel:
            resetHover()
        case .mouseMoved, .leftMouseDragged:
            guard event.timestamp != lastTimestamp else { return }; lastTimestamp = event.timestamp
            suppressed = false; requestPointerFrame(in: window)
        default: break
        }
    }
    func setInput(_ value: StudyInputKind) { if value != input { input = value } }
    func reset() { setInput(.none); resetHover() }
    func resetScope(clearNativeFocus: Bool = true) {
        reset()
        if clearNativeFocus { host?.window?.makeFirstResponder(nil) }
    }
    fileprivate func register(_ target: StudyPointerTarget.Host) {
        targets[ObjectIdentifier(target)] = WeakTarget(view: target)
        if let window = target.window { track(window) }
        if let clip = target.enclosingScrollView?.contentView { trackScroll(clip) }
    }
    /// One observer per scroll container, rather than one per row/button.
    func trackScroll(_ clip: NSClipView) {
        for (key, value) in scrollTracking where value.clip == nil {
            NotificationCenter.default.removeObserver(value.observer)
            scrollTracking.removeValue(forKey: key)
        }
        let key = ObjectIdentifier(clip)
        guard scrollTracking[key] == nil else { return }
        clip.postsBoundsChangedNotifications = true
        let observer = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.resetHover() }
        }
        scrollTracking[key] = ScrollTracking(clip: clip, observer: observer)
    }
    private func track(_ window: NSWindow) {
        tracking = tracking.filter { $0.value.window != nil }
        let key = ObjectIdentifier(window)
        guard tracking[key] == nil, let content = window.contentView else { return }
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self)
        content.addTrackingArea(area)
        tracking[key] = WindowTracking(window: window, content: content, area: area, previousMouseMoves: window.acceptsMouseMovedEvents)
        window.acceptsMouseMovedEvents = true
    }
    @objc(mouseMoved:) private func trackingMouseMoved(_ event: NSEvent) { receive(event) }
    @objc(mouseEntered:) private func trackingMouseEntered(_ event: NSEvent) { if let window = event.window { requestPointerFrame(in: window) } }
    @objc(mouseExited:) private func trackingMouseExited(_ event: NSEvent) { if let window = event.window { requestPointerFrame(in: window) } }
    fileprivate func unregister(_ target: StudyPointerTarget.Host) {
        targets.removeValue(forKey: ObjectIdentifier(target))
        if active === target { clearHover() }
    }
    fileprivate func geometryChanged(_ target: StudyPointerTarget.Host) {
        guard active === target, let window = target.window else { return }
        let point = target.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        if !target.eligible || !target.bounds.contains(point) || !target.visibleRect.contains(point) { resetHover() }
    }
    func resetHover() {
        suppressed = true
        pendingPointerWindow = nil
        pointerDisplayLink?.isPaused = true
        clearHover()
    }
    private func requestPointerFrame(in window: NSWindow) {
        pendingPointerWindow = window
        pointerDisplayLink?.isPaused = false
    }
    private func flushPointerFrame() {
        pointerDisplayLink?.isPaused = true
        guard let window = pendingPointerWindow else { return }
        pendingPointerWindow = nil
        updatePointer(in: window)
    }
    func updatePointer(in window: NSWindow) {
        guard !suppressed, window.isVisible, !window.isMiniaturized else { clearHover(); return }
        let point = window.mouseLocationOutsideOfEventStream
        // Reject inactive sections and bounding boxes before doing coordinate/path work.
        // Keep only the best target: no per-event arrays and no paths rebuilt per pixel.
        var winner: StudyPointerTarget.Host?
        var bestArea = CGFloat.infinity
        var bestDepth = Int.min
        for target in targets.values {
            guard let view = target.view, view.eligible, view.window == window else { continue }
            let frame = view.convert(view.bounds, to: nil)
            guard frame.contains(point), !view.isHiddenOrHasHiddenAncestor else { continue }
            let local = view.convert(point, from: nil)
            guard view.visibleRect.contains(local), view.containsPointer(local) else { continue }
            let area = frame.width * frame.height
            guard area <= bestArea else { continue }
            let depth = view.depth
            if StudyHoverPolicy.preferred(area: area, depth: depth, overArea: bestArea, depth: bestDepth) {
                winner = view; bestArea = area; bestDepth = depth
            }
        }
        if active !== winner {
            active?.changed(false, .zero); active = winner
            if let winner {
                (winner.decorative ? NSCursor.arrow : winner.textEntry ? NSCursor.iBeam : .pointingHand).set()
            } else { NSCursor.arrow.set() }
        }
        if let winner {
            winner.changed(true, winner.convert(point, from: nil))
        }
    }
    func clearHover() {
        let hadTarget = active != nil
        active?.changed(false, .zero); active = nil
        if hadTarget { NSCursor.arrow.set() }
    }
    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }; monitor = nil
        pointerDisplayLink?.invalidate(); pointerDisplayLink = nil; pointerFrameTarget = nil
        for value in scrollTracking.values { NotificationCenter.default.removeObserver(value.observer) }
        scrollTracking.removeAll()
        reset(); host = nil
        for item in tracking.values {
            item.content?.removeTrackingArea(item.area)
            item.window?.acceptsMouseMovedEvents = item.previousMouseMoves
        }
        tracking.removeAll()
    }
    deinit {
        // Fallback cleanup must remain on AppKit's main queue even if the last
        // reference is released elsewhere; do not capture the dying session.
        let items = tracking, token = monitor, frameTarget = pointerFrameTarget, scrolls = scrollTracking
        DispatchQueue.main.async {
            frameTarget?.invalidate()
            for value in scrolls.values { NotificationCenter.default.removeObserver(value.observer) }
            if let token { NSEvent.removeMonitor(token) }
            for item in items.values {
                item.content?.removeTrackingArea(item.area)
                item.window?.acceptsMouseMovedEvents = item.previousMouseMoves
            }
        }
    }
}
private struct StudyInteractionHost: ViewModifier {
    let scope: String
    var clearNativeFocus = true
    @StateObject private var session = StudyInteractionSession()
    func body(content: Content) -> some View {
        content.environment(\.studyInteraction, session).focusEffectDisabled()
            .background { StudyInteractionWindow(session: session, clearNativeFocus: clearNativeFocus).opacity(DesignSystem.Interaction.nativeProbeOpacity).allowsHitTesting(false).accessibilityHidden(true) }
            // Preserve the sidebar's real responder so repeated arrow navigation still works.
            .onChange(of: scope) { session.reset() }
    }
}
extension View {
    func interactionHost(scope: String, clearNativeFocus: Bool = true) -> some View { modifier(StudyInteractionHost(scope: scope, clearNativeFocus: clearNativeFocus)) }
}
private struct StudyInteractionWindow: NSViewRepresentable {
    let session: StudyInteractionSession
    let clearNativeFocus: Bool
    func makeNSView(context: Context) -> Host { Host(session: session, clearNativeFocus: clearNativeFocus) }
    func updateNSView(_ view: Host, context: Context) {}
    static func dismantleNSView(_ view: Host, coordinator: ()) { view.stop() }
    final class Host: NSView {
        let session: StudyInteractionSession
        let clearNativeFocus: Bool
        private var observers: [NSObjectProtocol] = []
        init(session: StudyInteractionSession, clearNativeFocus: Bool) { self.session = session; self.clearNativeFocus = clearNativeFocus; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); stop()
            guard let window else { return }; session.start(host: self); session.resetScope(clearNativeFocus: clearNativeFocus)
            for name in [NSWindow.didResignKeyNotification, NSWindow.didMiniaturizeNotification, NSWindow.didChangeOcclusionStateNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak session] _ in MainActor.assumeIsolated { session?.reset() } })
            }
        }
        func stop() { for observer in observers { NotificationCenter.default.removeObserver(observer) }; observers.removeAll(); session.stop() }
        deinit { for observer in observers { NotificationCenter.default.removeObserver(observer) } }
    }
}
private struct StudyPointerTarget: NSViewRepresentable {
    let session: StudyInteractionSession?
    let eligible: Bool
    let decorative: Bool
    let textEntry: Bool
    let radius: CGFloat
    let shape: StudyControlShape
    let changed: (Bool, CGPoint) -> Void
    func makeNSView(context: Context) -> Host { Host() }
    func updateNSView(_ view: Host, context: Context) {
        if view.session !== session { view.session?.unregister(view); view.session = session; session?.register(view) }
        view.changed = changed; view.decorative = decorative; view.textEntry = textEntry; view.radius = radius; view.shape = shape
        if view.eligible != eligible { view.eligible = eligible; session?.geometryChanged(view) }
    }
    static func dismantleNSView(_ view: Host, coordinator: ()) { view.stop() }
    final class Host: NSView {
        weak var session: StudyInteractionSession?
        var eligible = false, decorative = false, textEntry = false
        var radius: CGFloat = DesignSystem.Radius.control
        var shape: StudyControlShape = .rounded
        var changed: (Bool, CGPoint) -> Void = { _, _ in }
        private var oldFrame = CGRect.null
        // Cache the local outline. Scrolling changes the window transform, not this
        // path; bounds/shape changes invalidate it on the next pointer query.
        private var hitBounds = CGRect.null
        private var hitRadius = CGFloat.nan
        private var hitShape: StudyControlShape = .rounded
        private var hitPath = Path()
        func containsPointer(_ point: CGPoint) -> Bool {
            if hitBounds != bounds || hitRadius != radius || hitShape != shape {
                hitBounds = bounds; hitRadius = radius; hitShape = shape
                hitPath = StudySurfaceShape(kind: shape, radius: radius).path(in: bounds)
            }
            return hitPath.contains(point)
        }
        override var isFlipped: Bool { true }
        var depth: Int { var count = 0; var node = superview; while let next = node { count += 1; node = next.superview }; return count }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { session?.unregister(self); return }
            session?.register(self)

        }
        override func layout() {
            super.layout()
            let frame = convert(bounds, to: nil)
            if frame != oldFrame { oldFrame = frame; session?.geometryChanged(self) }
        }
        func stop() { session?.unregister(self) }
    }
}
private struct KeyboardFocusOutline: View {
    @Environment(\.studyTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    @Environment(\.komorebiSectionVisible) private var visible
    @ObservedObject var session: StudyInteractionSession
    let focused: Bool
    let radius: CGFloat
    let shape: StudyControlShape
    var body: some View {
        StudySurfaceShape(kind: shape, radius: radius)
            .inset(by: -DesignSystem.Interaction.focusInset)
            .stroke(theme.palette.accent, lineWidth: StudyFocusPolicy.showsRing(focused: focused, input: session.input, enabled: enabled, visible: visible) ? DesignSystem.Interaction.focusWidth : 0)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct StudyHoverCandidate<ID: Hashable> {
    let id: ID
    let frame: CGRect
    let visibleFrame: CGRect
    let depth: Int
    let enabled: Bool
    let path: Path
    init(id: ID, frame: CGRect, visibleFrame: CGRect, radius: CGFloat, shape: StudyControlShape = .rounded, depth: Int, enabled: Bool) {
        self.id = id; self.frame = frame; self.visibleFrame = visibleFrame
        self.depth = depth; self.enabled = enabled
        // Geometry is immutable during a pointer pass; prepare it once, not per hit test.
        path = StudySurfaceShape(kind: shape, radius: radius).path(in: frame)
    }
}
enum StudyHoverPolicy {
    static func preferred(area: CGFloat, depth: Int, overArea: CGFloat, depth oldDepth: Int) -> Bool {
        area < overArea || (area == overArea && depth > oldDepth)
    }
    static func winner<ID>(at point: CGPoint, candidates: [StudyHoverCandidate<ID>]) -> ID? {
        var winner: ID?
        var bestArea = CGFloat.infinity
        var bestDepth = Int.min
        for candidate in candidates {
            guard candidate.enabled, candidate.frame.contains(point), candidate.visibleFrame.contains(point) else { continue }
            let area = candidate.frame.width * candidate.frame.height
            guard preferred(area: area, depth: candidate.depth, overArea: bestArea, depth: bestDepth), candidate.path.contains(point) else { continue }
            winner = candidate.id; bestArea = area; bestDepth = candidate.depth
        }
        return winner
    }
}

enum StudyControlShape: Equatable { case rounded, circle, capsule }
struct StudySurfaceShape: InsettableShape {
    let kind: StudyControlShape
    var radius: CGFloat = DesignSystem.Radius.control
    var insetAmount: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch kind {
        case .rounded: return RoundedRectangle(cornerRadius: max(0, radius - insetAmount)).path(in: bounds)
        case .circle: return Circle().path(in: bounds)
        case .capsule: return Capsule().path(in: bounds)
        }
    }
    func inset(by amount: CGFloat) -> Self { var value = self; value.insetAmount += amount; return value }
}
/// Selection remains a state, but its border yields to a keyboard focus outline.
struct StudySelectionBorder: View {
    @Environment(\.studyInteraction) private var session
    @Environment(\.isFocused) private var focused
    let selected: Bool
    let color: Color
    var normalColor = Color.clear
    var radius: CGFloat = DesignSystem.Radius.control
    var shape: StudyControlShape = .rounded
    var explicitFocus: Bool? = nil
    var body: some View {
        Group {
            if let session {
                SelectionStroke(session: session, selected: selected, color: color, normalColor: normalColor, radius: radius, shape: shape, focused: explicitFocus ?? focused)
            } else {
                StudySurfaceShape(kind: shape, radius: radius).stroke(selected ? color : normalColor, lineWidth: selected ? DesignSystem.Interaction.focusWidth : DesignSystem.PreservedGeometry.stroke1)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private struct SelectionStroke: View {
        @Environment(\.isEnabled) private var enabled
        @Environment(\.komorebiSectionVisible) private var visible
        @ObservedObject var session: StudyInteractionSession
        let selected: Bool
        let color: Color
        let normalColor: Color
        let radius: CGFloat
        let shape: StudyControlShape
        let focused: Bool
        var body: some View {
            StudySurfaceShape(kind: shape, radius: radius).stroke(StudyFocusPolicy.showsRing(focused: focused, input: session.input, enabled: enabled, visible: visible) ? .clear : selected ? color : normalColor,
                lineWidth: selected ? DesignSystem.Interaction.focusWidth : DesignSystem.PreservedGeometry.stroke1)
        }
    }
}

enum StudyHoverAppearance {
    static func spotlight(mode: ThemeMode, listRow: Bool, selected: Bool) -> Bool { mode == .dark && !listRow && !selected }
    static func lifts(active: Bool, listRow: Bool, decorative: Bool, reduceMotion: Bool, motion: String) -> Bool {
        active && !listRow && !decorative && !reduceMotion && motion != "Off"
    }
}
/// Separately drawable decoration also used by deterministic state-render tests.
struct StudyHoverDecoration: View {
    @Environment(\.studyTheme) private var theme
    let active: Bool
    var location = CGPoint.zero
    var radius: CGFloat = DesignSystem.Radius.control
    var shape: StudyControlShape = .rounded
    var listRow = false
    var selected = false
    var body: some View {
        GeometryReader { geometry in
            let outline = StudySurfaceShape(kind: shape, radius: radius)
            if listRow || selected {
                outline.fill(theme.palette.accent.opacity(active ? theme.appearance.opacity0_055 : 0))
            } else if active {
                outline.stroke(theme.palette.accent.opacity(theme.appearance.opacity0_30), lineWidth: DesignSystem.PreservedGeometry.stroke1)
                if StudyHoverAppearance.spotlight(mode: theme.mode, listRow: listRow, selected: selected) {
                    let light = RadialGradient(colors: [theme.palette.spotlight.opacity(DesignSystem.Interaction.spotlightOpacity), .clear], center: UnitPoint(x: location.x / max(1, geometry.size.width), y: location.y / max(1, geometry.size.height)), startRadius: 0, endRadius: DesignSystem.Interaction.spotlightRadius)
                    outline.fill(light)
                }
            }
        }
    }
}
