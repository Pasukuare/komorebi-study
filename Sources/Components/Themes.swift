import SwiftUI
import AppKit
import CoreText

// Theme packages own appearance; layout metrics remain in DesignSystem.

struct ThemePalette {
    var sidebar: Color
    var sidebarSelection: Color
    var onAccentSurface: Color
    var sidebarSelectedIcon: Color
    var sidebarSelectedText: Color
    var controlBorder: Color
    var actionPressed: Color?
    var disabledAction: Color
    var onDisabledAction: Color
    var disabledText: Color?
    var inheritedText: Color
    var placeholder: Color?
    var sliderTrack: Color
    var background: Color
    var surface: Color
    var elevatedSurface: Color
    var border: Color
    var textPrimary: Color
    var textSecondary: Color
    var textTertiary: Color
    var accent: Color
    var accentHover: Color
    var accentSurface: Color
    var success: Color
    var successSurface: Color
    var warning: Color
    var warningSurface: Color
    var error: Color
    var errorSurface: Color
    var interval: Color
    var action: Color
    var actionHover: Color
    var onAction: Color
    var light: Color
    var spotlight: Color
    var hill: Color
    var timerDivider: Color
    var timerBorder: Color
    var timerTrack: Color
    var timerGradientStart: Color
    var timerGradientEnd: Color
    var landscapeTints: [String: Color]
    init(mode: ThemeMode) {
        sidebar = mode.resolve(DesignSystem.Palette.background)
        onAccentSurface = mode.resolve(DesignSystem.Palette.textPrimary)
        sidebarSelectedIcon = mode.resolve(DesignSystem.Palette.accent)
        sidebarSelectedText = mode.resolve(DesignSystem.Palette.textPrimary)
        sidebarSelection = mode.resolve(DesignSystem.Palette.accentSurface)
        controlBorder = mode.resolve(DesignSystem.Palette.border)
        actionPressed = nil
        disabledAction = mode.resolve(DesignSystem.Palette.action)
        onDisabledAction = mode.resolve(DesignSystem.Palette.onAction)
        disabledText = nil
        sliderTrack = mode.resolve(DesignSystem.Palette.border.opacity(DesignSystem.PreservedAppearance.opacity0_5))
        placeholder = nil
        inheritedText = .primary
        background = mode.resolve(DesignSystem.Palette.background)
        surface = mode.resolve(DesignSystem.Palette.surface)
        elevatedSurface = mode.resolve(DesignSystem.Palette.elevatedSurface)
        border = mode.resolve(DesignSystem.Palette.border)
        textPrimary = mode.resolve(DesignSystem.Palette.textPrimary)
        textSecondary = mode.resolve(DesignSystem.Palette.textSecondary)
        textTertiary = mode.resolve(DesignSystem.Palette.textTertiary)
        accent = mode.resolve(DesignSystem.Palette.accent)
        accentHover = mode.resolve(DesignSystem.Palette.accentHover)
        accentSurface = mode.resolve(DesignSystem.Palette.accentSurface)
        success = mode.resolve(DesignSystem.Palette.success)
        successSurface = mode.resolve(DesignSystem.Palette.successSurface)
        warning = mode.resolve(DesignSystem.Palette.warning)
        warningSurface = mode.resolve(DesignSystem.Palette.warningSurface)
        error = mode.resolve(DesignSystem.Palette.error)
        errorSurface = mode.resolve(DesignSystem.Palette.errorSurface)
        interval = mode.resolve(DesignSystem.Palette.interval)
        action = mode.resolve(DesignSystem.Palette.action)
        actionHover = mode.resolve(DesignSystem.Palette.actionHover)
        onAction = mode.resolve(DesignSystem.Palette.onAction)
        light = mode.resolve(DesignSystem.Palette.light)
        spotlight = mode.resolve(DesignSystem.Palette.light)
        hill = mode.resolve(DesignSystem.Palette.hill)
        timerDivider = mode.resolve(DesignSystem.Palette.timerDivider)
        timerBorder = mode.resolve(DesignSystem.Palette.timerBorder)
        timerTrack = mode.resolve(DesignSystem.Palette.timerTrack)
        timerGradientStart = mode.resolve(DesignSystem.Palette.timerGradientStart)
        timerGradientEnd = mode.resolve(DesignSystem.Palette.timerGradientEnd)
        landscapeTints = Dictionary(uniqueKeysWithValues: ["Morning", "Forest", "Rain", "Sunset", "Night"].map { ($0, mode.resolve(DesignSystem.Palette.landscapeTint($0))) })
    }
    func landscapeTint(_ landscape: String) -> Color { landscapeTints[landscape] ?? .clear }
}

struct ThemeTypography {
    var wordmark: Font
    var caption: Font
    var small: Font
    var body: Font
    var heading: Font
    var title: Font
    var display: Font
    var timerTitle: Font
    var timerSetupTitle: Font
    var timerMessage: Font
    var timerTotal: Font
    var timerSubject: Font
    var timerDigits: Font
    var timerFontName: String? = nil
    var timerPointSize: CGFloat = 60
    var menuTimerPointSize: CGFloat = 44
    var minimumDecorativeTimerSize: CGFloat = 40
    var timerGlow = Color.clear
    var timerGlowOpacity = 0.0
    var timerGlowRadius: CGFloat = 12
    var timerSymbol: Font
    var control: Font
    var legacyHeadline: Font
    var legacyCallout: Font
    func timerLineHeight(at size: CGFloat) -> CGFloat {
        guard let name = timerFontName, let font = NSFont(name: name, size: size) else { return size }
        return font.ascender - font.descender + font.leading
    }
    init(mode: ThemeMode) {
        wordmark = DesignSystem.Typography.title
        caption = DesignSystem.Typography.caption
        small = DesignSystem.Typography.small
        body = DesignSystem.Typography.body
        heading = DesignSystem.Typography.heading
        title = DesignSystem.Typography.title
        display = DesignSystem.Typography.display
        timerTitle = DesignSystem.Typography.timerTitle
        timerSetupTitle = DesignSystem.Typography.timerSetupTitle
        timerMessage = DesignSystem.Typography.timerMessage
        timerTotal = DesignSystem.Typography.timerTotal
        timerSubject = DesignSystem.Typography.timerSubject
        timerDigits = DesignSystem.Typography.timerDigits
        timerSymbol = DesignSystem.Typography.timerSymbol
        control = DesignSystem.Typography.control
        legacyHeadline = DesignSystem.Typography.legacyHeadline
        legacyCallout = DesignSystem.Typography.legacyCallout
    }
}

struct ThemeLegacyTypography {
    var callout: Font
    var caption: Font
    var chartTooltipValue: Font
    var comparisonSymbol: Font
    var completionSymbol: Font
    var completionTitle: Font
    var dailyGoalValue: Font
    var editorTitle: Font
    var headline: Font
    var homeCardTitle: Font
    var homeTimerValue: Font
    var homeTitle: Font
    var lightWeight: Font.Weight
    var mediumWeight: Font.Weight
    var menuGreeting: Font
    var menuTimerDigits: Font
    var menuWordmark: Font
    var pageTitle: Font
    var regularWeight: Font.Weight
    var semiboldWeight: Font.Weight
    var statusLabel: Font
    var subjectMetric: Font
    var subjectSymbol: Font
    var title2: Font
    var title3: Font
    var ultraLightWeight: Font.Weight
    var welcomeSymbol: Font
    var selectedSegment: Font
    var unselectedSegment: Font
    func segmented(selected: Bool) -> Font { selected ? selectedSegment : unselectedSegment }
    init(mode: ThemeMode) {
        callout = DesignSystem.PreservedTypography.callout
        caption = DesignSystem.PreservedTypography.caption
        chartTooltipValue = DesignSystem.PreservedTypography.chartTooltipValue
        comparisonSymbol = DesignSystem.PreservedTypography.comparisonSymbol
        completionSymbol = DesignSystem.PreservedTypography.completionSymbol
        completionTitle = DesignSystem.PreservedTypography.completionTitle
        dailyGoalValue = DesignSystem.PreservedTypography.dailyGoalValue
        editorTitle = DesignSystem.PreservedTypography.editorTitle
        headline = DesignSystem.PreservedTypography.headline
        homeCardTitle = DesignSystem.PreservedTypography.homeCardTitle
        homeTimerValue = DesignSystem.PreservedTypography.homeTimerValue
        homeTitle = DesignSystem.PreservedTypography.homeTitle
        lightWeight = DesignSystem.PreservedTypography.lightWeight
        mediumWeight = DesignSystem.PreservedTypography.mediumWeight
        menuGreeting = DesignSystem.PreservedTypography.menuGreeting
        menuTimerDigits = DesignSystem.PreservedTypography.menuTimerDigits
        menuWordmark = DesignSystem.PreservedTypography.menuWordmark
        pageTitle = DesignSystem.PreservedTypography.pageTitle
        regularWeight = DesignSystem.PreservedTypography.regularWeight
        semiboldWeight = DesignSystem.PreservedTypography.semiboldWeight
        statusLabel = DesignSystem.PreservedTypography.statusLabel
        subjectMetric = DesignSystem.PreservedTypography.subjectMetric
        subjectSymbol = DesignSystem.PreservedTypography.subjectSymbol
        title2 = DesignSystem.PreservedTypography.title2
        title3 = DesignSystem.PreservedTypography.title3
        ultraLightWeight = DesignSystem.PreservedTypography.ultraLightWeight
        welcomeSymbol = DesignSystem.PreservedTypography.welcomeSymbol
        selectedSegment = DesignSystem.PreservedTypography.segmented(selected: true)
        unselectedSegment = DesignSystem.PreservedTypography.segmented(selected: false)
    }
}

struct ThemeAppearance {
    var controlBorderOpacity = DesignSystem.PreservedAppearance.opacity0_45
    var disabledOpacity = DesignSystem.PreservedAppearance.opacity0_4
    var sidebarOpacity = DesignSystem.PreservedAppearance.opacity0_75
    var sidebarSelectionOpacity = DesignSystem.PreservedAppearance.opacity0_65
    var opacity0_035: Double
    var opacity0_055: Double
    var opacity0_07: Double
    var opacity0_08: Double
    var opacity0_09: Double
    var opacity0_10: Double
    var opacity0_11: Double
    var opacity0_12: Double
    var opacity0_13: Double
    var opacity0_15: Double
    var opacity0_16: Double
    var opacity0_22: Double
    var opacity0_30: Double
    var opacity0_35: Double
    var opacity0_4: Double
    var opacity0_45: Double
    var opacity0_5: Double
    var opacity0_55: Double
    var opacity0_65: Double
    var opacity0_75: Double
    var opacity0_76: Double
    var opacity0_90: Double
    var destructiveInk: Color
    var amberInk: Color
    init(mode: ThemeMode) {
        opacity0_035 = DesignSystem.PreservedAppearance.opacity0_035
        opacity0_055 = DesignSystem.PreservedAppearance.opacity0_055
        opacity0_07 = DesignSystem.PreservedAppearance.opacity0_07
        opacity0_08 = DesignSystem.PreservedAppearance.opacity0_08
        opacity0_09 = DesignSystem.PreservedAppearance.opacity0_09
        opacity0_10 = DesignSystem.PreservedAppearance.opacity0_10
        opacity0_11 = DesignSystem.PreservedAppearance.opacity0_11
        opacity0_12 = DesignSystem.PreservedAppearance.opacity0_12
        opacity0_13 = DesignSystem.PreservedAppearance.opacity0_13
        opacity0_15 = DesignSystem.PreservedAppearance.opacity0_15
        opacity0_16 = DesignSystem.PreservedAppearance.opacity0_16
        opacity0_22 = DesignSystem.PreservedAppearance.opacity0_22
        opacity0_30 = DesignSystem.PreservedAppearance.opacity0_30
        opacity0_35 = DesignSystem.PreservedAppearance.opacity0_35
        opacity0_4 = DesignSystem.PreservedAppearance.opacity0_4
        opacity0_45 = DesignSystem.PreservedAppearance.opacity0_45
        opacity0_5 = DesignSystem.PreservedAppearance.opacity0_5
        opacity0_55 = DesignSystem.PreservedAppearance.opacity0_55
        opacity0_65 = DesignSystem.PreservedAppearance.opacity0_65
        opacity0_75 = DesignSystem.PreservedAppearance.opacity0_75
        opacity0_76 = DesignSystem.PreservedAppearance.opacity0_76
        opacity0_90 = DesignSystem.PreservedAppearance.opacity0_90
        destructiveInk = mode.resolve(DesignSystem.PreservedAppearance.destructiveInk)
        amberInk = mode.resolve(DesignSystem.PreservedAppearance.amberInk)
    }
}

enum ThemeAtmosphere { case woodland, moonlit }
struct ThemeDecoration {
    var atmosphere: ThemeAtmosphere = .woodland
    var hillOpacityBase = DesignSystem.PreservedAppearance.opacity0_035
    var candle = false
    var candlePeriod = 4.0
    var candleMinimum = 0.85
    var moonDiameter: CGFloat = 0.16
    var moonX: CGFloat = 0.84
    var moonY: CGFloat = 0.18
    var moonDiscOpacity = 0.12
    var moonHaloOpacity = 0.15
    var moonHaloScale: CGFloat = 2.4
    var branchOpacity = 0.18
    var branchSway = 1.5
    var branchWidth: CGFloat = 1.5
    var fireflyOpacity = 0.18
    var fireflyDiameter: CGFloat = 3
    var fireflyPeriod = 7.0
    var fireflyTint: Color = .clear
    var batPeriod = 90.0
    var batDuration = 6.0
    var batOpacity = 0.055
    var batSize: CGFloat = 20
    var ghostSize: CGFloat = 40
    var ghostStroke: CGFloat = 1.5
    var frameInterval: Double
    var ringFrameInterval: Double
    var lightDiameter: CGFloat
    var lightX: Double
    var lightY: CGFloat
    var driftPeriod: Double
    var driftAmplitude: Double
    var hillBase: Double
    var hillOffset: Double
    var hillOverdraw: CGFloat
    var hillControlX1: CGFloat
    var hillControlX2: CGFloat
    var hillControlY1: CGFloat
    var hillControlY2: CGFloat
    var hillOpacityStep: Double
    var hillCount: Int
    var particleCount: Int
    var particleSeedX: Double
    var particleSeedY: Double
    var particlePeriod: Double
    var particleDrift: Double
    var particleSpeed: Double
    var parallax: Double
    var ringRotation: Double
    var sidebarMaterial: Material
    init(mode: ThemeMode) {
        frameInterval = DesignSystem.PreservedDecoration.frameInterval
        ringFrameInterval = DesignSystem.PreservedDecoration.ringFrameInterval
        lightDiameter = DesignSystem.PreservedDecoration.lightDiameter
        lightX = DesignSystem.PreservedDecoration.lightX
        lightY = DesignSystem.PreservedDecoration.lightY
        driftPeriod = DesignSystem.PreservedDecoration.driftPeriod
        driftAmplitude = DesignSystem.PreservedDecoration.driftAmplitude
        hillBase = DesignSystem.PreservedDecoration.hillBase
        hillOffset = DesignSystem.PreservedDecoration.hillOffset
        hillOverdraw = DesignSystem.PreservedDecoration.hillOverdraw
        hillControlX1 = DesignSystem.PreservedDecoration.hillControlX1
        hillControlX2 = DesignSystem.PreservedDecoration.hillControlX2
        hillControlY1 = DesignSystem.PreservedDecoration.hillControlY1
        hillControlY2 = DesignSystem.PreservedDecoration.hillControlY2
        hillOpacityStep = DesignSystem.PreservedDecoration.hillOpacityStep
        hillCount = DesignSystem.PreservedDecoration.hillCount
        particleCount = DesignSystem.PreservedDecoration.particleCount
        particleSeedX = DesignSystem.PreservedDecoration.particleSeedX
        particleSeedY = DesignSystem.PreservedDecoration.particleSeedY
        particlePeriod = DesignSystem.PreservedDecoration.particlePeriod
        particleDrift = DesignSystem.PreservedDecoration.particleDrift
        particleSpeed = DesignSystem.PreservedDecoration.particleSpeed
        parallax = DesignSystem.PreservedDecoration.parallax
        ringRotation = DesignSystem.PreservedDecoration.ringRotation
        sidebarMaterial = DesignSystem.PreservedDecoration.sidebarMaterial
    }
}

struct ThemeMotion {
    var springResponse: Double
    var springDamping: Double
    var sliderDragScale: CGFloat
    var chartHeadroom: Double
    var ruleDash: [CGFloat]
    init(mode: ThemeMode) {
        springResponse = DesignSystem.PreservedMotion.springResponse
        springDamping = DesignSystem.PreservedMotion.springDamping
        sliderDragScale = DesignSystem.PreservedMotion.sliderDragScale
        chartHeadroom = DesignSystem.PreservedMotion.chartHeadroom
        ruleDash = DesignSystem.PreservedMotion.ruleDash
    }
}

struct ThemeShadows {
    var low: DesignSystem.Shadow
    var medium: DesignSystem.Shadow
    var high: DesignSystem.Shadow
    init(mode: ThemeMode) {
        low = DesignSystem.Shadow(color: mode.resolve(DesignSystem.Shadows.low.color), radius: DesignSystem.Shadows.low.radius, y: DesignSystem.Shadows.low.y)
        medium = DesignSystem.Shadow(color: mode.resolve(DesignSystem.Shadows.medium.color), radius: DesignSystem.Shadows.medium.radius, y: DesignSystem.Shadows.medium.y)
        high = DesignSystem.Shadow(color: mode.resolve(DesignSystem.Shadows.high.color), radius: DesignSystem.Shadows.high.radius, y: DesignSystem.Shadows.high.y)
    }
}

enum ThemeMode: String, CaseIterable {
    case light, dark
    static func resolve(preference: String, system: ColorScheme) -> ThemeMode {
        preference == "Light" ? .light : preference == "Dark" ? .dark : system == .dark ? .dark : .light
    }
    func resolve(_ color: Color) -> Color {
        var resolved = NSColor(color)
        NSAppearance(named: self == .dark ? .darkAqua : .aqua)!.performAsCurrentDrawingAppearance {
            resolved = NSColor(color).usingColorSpace(.sRGB)!
        }
        return Color(nsColor: resolved)
    }
}

enum ThemeSeason: String {
    case spring, summer, autumn, winter
    static func current(at date: Date = Date(), calendar: Calendar = .current) -> ThemeSeason {
        let c = calendar.dateComponents([.month, .day], from: date)
        let day = (c.month ?? 1) * 100 + (c.day ?? 1)
        switch day {
        case 321..<621: return .spring
        case 621..<923: return .summer
        case 923..<1221: return .autumn
        default: return .winter
        }
    }
}
enum ThemeInitialColorTab: Equatable { case currentSeason, season(ThemeSeason) }
struct ThemeSuggestionWindow: Equatable {
    let startMonth: Int; let startDay: Int; let endMonth: Int; let endDay: Int
}
struct ThemeBehavior {
    var initialColorTab: ThemeInitialColorTab
    var replacesLandscapes: Bool
    var supportsSeason: Bool
    var suggestionWindow: ThemeSuggestionWindow?
}
struct ThemeOption: Identifiable {
    let id: String
    let title: String
    let detail: String
    let defaultValue: Bool
}
/// Only nonfunctional copy may be overridden. Controls retain their meaning.
enum ThemeTextKey: String { case greeting, homeSubtitle, timerSubtitle, streak, streakSingular, emptyTitle, emptyDetail, emptySymbol }
enum ThemeEmptyIllustration { case standard, ghost }
struct ThemeCopy {
    var emptyIllustration: ThemeEmptyIllustration = .standard
    var overrides: [ThemeTextKey: String] = [:]
    func text(_ key: ThemeTextKey, fallback: String) -> String { L10n.tr(overrides[key] ?? fallback) }
    func streak(_ days: Int) -> String {
        text(days == 1 ? .streakSingular : .streak, fallback: days == 1 ? "Serie: %d giorno" : "Serie: %d giorni").replacingOccurrences(of: "%d", with: String(days))
    }
}
struct ThemeVariant {
    var palette: ThemePalette
    var typography: ThemeTypography
    var preservedTypography: ThemeLegacyTypography
    var appearance: ThemeAppearance
    var decoration: ThemeDecoration
    var motion: ThemeMotion
    var shadows: ThemeShadows
    var subjectColors: [SubjectColorChoice]
    init(mode: ThemeMode) {
        palette = ThemePalette(mode: mode)
        typography = ThemeTypography(mode: mode)
        preservedTypography = ThemeLegacyTypography(mode: mode)
        appearance = ThemeAppearance(mode: mode)
        decoration = ThemeDecoration(mode: mode)
        motion = ThemeMotion(mode: mode)
        shadows = ThemeShadows(mode: mode)
        subjectColors = DesignSystem.PreservedColors.subjectChoices.map { .init(id: $0.id, name: $0.name, ink: mode.resolve($0.ink)) } + SeasonalSubjectColors.choices(mode: mode)
    }
}
struct ThemePackage: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    var light: ThemeVariant
    var dark: ThemeVariant
    var copy: ThemeCopy
    var themedCopy: ThemeCopy? = nil
    var behavior: ThemeBehavior
    var options: [ThemeOption]
    var cifreCellaFissa = false
    var logoMark: ThemeLogoMark = .leaf
    func resolve(mode: ThemeMode, options: [String: Bool] = [:], date: Date = Date()) -> ResolvedTheme { ResolvedTheme(package: self, mode: mode, optionValues: options, date: date) }
}
struct ResolvedTheme {
    let optionValues: [String: Bool]
    let package: ThemePackage
    let mode: ThemeMode
    init(package: ThemePackage, mode: ThemeMode, optionValues: [String: Bool] = [:], date: Date = Date()) {
        self.package = package; self.mode = mode; self.optionValues = optionValues
        let base = mode == .dark ? package.dark : package.light
        self.variant = package.behavior.supportsSeason && optionValues[ThemeOptionID.followSeason] == true
            ? ThemeRegistry.seasonalVariant(package: package, mode: mode, season: .current(at: date)) : base
    }
    func option(_ id: String) -> Bool { optionValues[id] ?? package.options.first { $0.id == id }?.defaultValue ?? true }
    var decorationsEnabled: Bool { option(ThemeOptionID.decorations) }
    private let variant: ThemeVariant
    var cifreCellaFissa: Bool { package.cifreCellaFissa }
    var logoMark: ThemeLogoMark { package.logoMark }
    var palette: ThemePalette { variant.palette }
    var typography: ThemeTypography { variant.typography }
    var preservedTypography: ThemeLegacyTypography { variant.preservedTypography }
    var appearance: ThemeAppearance { variant.appearance }
    var decoration: ThemeDecoration { variant.decoration }
    var motion: ThemeMotion { variant.motion }
    var shadows: ThemeShadows { variant.shadows }
    var subjectColors: [SubjectColorChoice] { variant.subjectColors }
    var copy: ThemeCopy { (optionValues[ThemeOptionID.themedText] ?? false) ? package.themedCopy ?? package.copy : package.copy }
    func subjectChoice(_ id: String) -> SubjectColorChoice {
        let canonical = SubjectColorID.canonical(id)
        if let choice = subjectColors.first(where: { $0.id == canonical }) { return choice }
        let neutral = subjectColors.first { $0.id == SubjectColorID.neutralID }!
        return .init(id: id, name: neutral.name, ink: neutral.ink)
    }
    func subjectColor(_ id: String) -> Color { subjectChoice(id).ink }
}
enum ThemeRegistry {
    static let packages: [ThemePackage] = [ThemePackage(
        id: "komorebi", name: "Komorebi", subtitle: "Luce tra le foglie",
        light: ThemeVariant(mode: .light), dark: ThemeVariant(mode: .dark), copy: ThemeCopy(),
        behavior: ThemeBehavior(initialColorTab: .currentSeason, replacesLandscapes: false, supportsSeason: true, suggestionWindow: nil), options: [ThemeOption(id: ThemeOptionID.followSeason, title: "Segui la stagione", detail: "Colore d’accento in base alla stagione.", defaultValue: false)], logoMark: .pagesAndLight), HalloweenTheme.package]
    private static let seasonalVariants: [String: ThemeVariant] = {
        var result: [String: ThemeVariant] = [:]
        for package in packages where package.behavior.supportsSeason {
            for mode in ThemeMode.allCases {
                for season in [ThemeSeason.spring, .summer, .autumn, .winter] {
                    let base = mode == .dark ? package.dark : package.light
                    result[package.id + ":" + mode.rawValue + ":" + season.rawValue] = SeasonalAccent.apply(to: base, mode: mode, season: season)
                }
            }
        }
        return result
    }()
    static func seasonalVariant(package: ThemePackage, mode: ThemeMode, season: ThemeSeason) -> ThemeVariant {
        seasonalVariants[package.id + ":" + mode.rawValue + ":" + season.rawValue] ?? SeasonalAccent.apply(to: mode == .dark ? package.dark : package.light, mode: mode, season: season)
    }
    static var defaultPackage: ThemePackage { packages[0] }
    static func package(_ id: String?) -> ThemePackage { packages.first { $0.id == id } ?? defaultPackage }
    static func resolve(settings: UserSettings, system: ColorScheme, date: Date = Date()) -> ResolvedTheme {
        package(settings.themeID).resolve(mode: ThemeMode.resolve(preference: settings.appearance, system: system), options: settings.themeOptions?[package(settings.themeID).id] ?? [:], date: date)
    }
}
private struct StudyThemeKey: EnvironmentKey {
    static let defaultValue = ThemeRegistry.defaultPackage.resolve(mode: .light)
}
extension EnvironmentValues {
    var studyTheme: ResolvedTheme {
        get { self[StudyThemeKey.self] }
        set { self[StudyThemeKey.self] = newValue }
    }
}
extension DesignSystem {
    enum ThemeLayout {
        static let previewWidth: CGFloat = 208
        static let previewHeight: CGFloat = 112
        static let previewRing: CGFloat = 78
        static let previewRingWidth: CGFloat = 4
        static let transitionDuration: Double = 0.3
    }
}
enum ThemeTransition {
    static func duration(reduceMotion: Bool, animations: String) -> Double {
        reduceMotion || animations == "Off" ? 0 : DesignSystem.ThemeLayout.transitionDuration
    }
}
/// Retains the content identity and state while swapping packages at the midpoint of a dissolve.
private struct StudyThemeHost: ViewModifier {
    let settings: UserSettings
    let date: Date
    @State private var activationDate = Date.distantPast
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var system
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appliedID: String?
    @State private var opacity = 1.0
    init(settings: UserSettings, date: Date) {
        self.date = date
        self.settings = settings
        _appliedID = State(initialValue: settings.themeID)
    }
    private var request: String { (settings.themeID ?? "") + "|" + String(reduceMotion) + "|" + settings.animations }
    func body(content: Content) -> some View {
        content
            .environment(\.studyTheme, ThemeRegistry.package(appliedID).resolve(mode: ThemeMode.resolve(preference: settings.appearance, system: system), options: settings.themeOptions?[ThemeRegistry.package(appliedID).id] ?? [:], date: max(date, activationDate)))
            .opacity(opacity)
            .animation(ThemeTransition.duration(reduceMotion: reduceMotion, animations: settings.animations) == 0 ? nil : .easeOut(duration: DesignSystem.ThemeLayout.transitionDuration), value: ThemeSeason.current(at: max(date, activationDate)))
            .animation(ThemeTransition.duration(reduceMotion: reduceMotion, animations: settings.animations) == 0 ? nil : .easeOut(duration: DesignSystem.ThemeLayout.transitionDuration), value: settings.themeOptions?[ThemeRegistry.package(appliedID).id]?[ThemeOptionID.followSeason])
            .onChange(of: scenePhase) { if scenePhase == .active { activationDate = Date() } }
            .task(id: request) {
                let requestedID = settings.themeID
                let duration = ThemeTransition.duration(reduceMotion: reduceMotion, animations: settings.animations)
                guard ThemeRegistry.package(appliedID).id != ThemeRegistry.package(requestedID).id, duration > 0 else {
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) { appliedID = requestedID; opacity = 1 }
                    return
                }
                withAnimation(.easeOut(duration: duration / 2)) { opacity = 0 }
                do { try await Task.sleep(for: .seconds(duration / 2)) } catch { opacity = 1; return }
                appliedID = requestedID
                withAnimation(.easeOut(duration: duration / 2)) { opacity = 1 }
            }
    }
}
extension View {
    func studyTheme(_ settings: UserSettings, date: Date = Date()) -> some View { modifier(StudyThemeHost(settings: settings, date: date)) }
}

// Semantic group identifiers never depend on translated labels or theme names.
enum SubjectColorGroup: String, CaseIterable, Identifiable {
    case classics = "classici", spring = "primavera", summer = "estate", autumn = "autunno", winter = "inverno"
    var id: String { rawValue }
    var title: String {
        switch self { case .classics: return L10n.tr("Classici"); case .spring: return L10n.tr("Primavera"); case .summer: return L10n.tr("Estate"); case .autumn: return L10n.tr("Autunno"); case .winter: return L10n.tr("Inverno") }
    }
    var symbol: String {
        switch self { case .classics: return "circle.grid.2x2"; case .spring: return "camera.macro"; case .summer: return "sun.max"; case .autumn: return "leaf"; case .winter: return "snowflake" }
    }
    var paletteDescription: String {
        switch self {
        case .classics: return L10n.tr("Neutri caldi e colori essenziali")
        case .spring: return L10n.tr("Fiori, germogli e cieli di primavera")
        case .summer: return L10n.tr("Mare, agrumi e fioriture estive")
        case .autumn: return L10n.tr("Foglie d’acero, zucca e terra")
        case .winter: return L10n.tr("Ghiaccio, bacche e sempreverdi")
        }
    }
    static func group(for colorID: String) -> SubjectColorGroup? {
        SubjectColorGroup(rawValue: String(SubjectColorID.canonical(colorID).split(separator: ".").first ?? ""))
    }
    static func initial(editing: Bool, colorID: String, behavior: ThemeBehavior, date: Date = Date(), calendar: Calendar = .current) -> SubjectColorGroup {
        if editing, let group = group(for: colorID) { return group }
        let season: ThemeSeason
        switch behavior.initialColorTab { case .currentSeason: season = .current(at: date, calendar: calendar); case .season(let fixed): season = fixed }
        switch season { case .spring: return .spring; case .summer: return .summer; case .autumn: return .autumn; case .winter: return .winter }
    }
}
struct SeasonalSubjectColor {
    let id: String; let name: String; let light: String; let dark: String
}
enum SeasonalSubjectColors {
    // Generated and audited by Scripts/audit-seasonal-colors.py. Classic values are untouched.
    static let values: [SeasonalSubjectColor] = [
        .init(id: "primavera.ciliegio", name: "Ciliegio", light: "B52B66", dark: "E49EBC"),
        .init(id: "primavera.germoglio", name: "Germoglio", light: "467022", dark: "8FC95F"),
        .init(id: "primavera.glicine", name: "Glicine", light: "8542C0", dark: "C4A7DE"),
        .init(id: "primavera.pesco", name: "Pesco", light: "AC401B", dark: "E8A189"),
        .init(id: "primavera.cielo-aprile", name: "Cielo d’aprile", light: "1F6B8E", dark: "75BCDC"),
        .init(id: "primavera.primula", name: "Primula", light: "766417", dark: "D6BC52"),
        .init(id: "estate.mare", name: "Mare", light: "006C8D", dark: "31C9F6"),
        .init(id: "estate.corallo", name: "Corallo", light: "BC280F", dark: "F19C8E"),
        .init(id: "estate.oleandro", name: "Oleandro", light: "B2208A", dark: "E898D2"),
        .init(id: "estate.menta", name: "Menta", light: "00725A", dark: "31F6CD"),
        .init(id: "estate.cobalto", name: "Cobalto", light: "235BD5", dark: "99B3EA"),
        .init(id: "estate.agrume", name: "Agrume", light: "8A5B00", dark: "F6B331"),
        .init(id: "autunno.zucca", name: "Zucca", light: "995216", dark: "E5A56F"),
        .init(id: "autunno.acero", name: "Acero", light: "AE3426", dark: "E5A199"),
        .init(id: "autunno.senape", name: "Senape", light: "7B6219", dark: "D5B453"),
        .init(id: "autunno.castagna", name: "Castagna", light: "805038", dark: "CFAC9A"),
        .init(id: "autunno.vino", name: "Vino", light: "79334D", dark: "D6A5B7"),
        .init(id: "autunno.bosco", name: "Bosco", light: "5F6A30", dark: "ABBA70"),
        .init(id: "inverno.ardesia", name: "Ardesia", light: "4F6783", dark: "A5B5C7"),
        .init(id: "inverno.mirtillo", name: "Mirtillo", light: "5451A1", dark: "B1AFD5"),
        .init(id: "inverno.agrifoglio", name: "Agrifoglio", light: "23663E", dark: "65C58B"),
        .init(id: "inverno.bacca", name: "Bacca", light: "9E3654", dark: "DCA3B3"),
        .init(id: "inverno.brina", name: "Brina", light: "2A6D7D", dark: "79BDCD"),
        .init(id: "inverno.cenere", name: "Cenere", light: "65655F", dark: "B3B3AE"),
    ]
    static func choices(mode: ThemeMode) -> [SubjectColorChoice] {
        values.map { value in
            let color = Color.themeHex(mode == .light ? value.light : value.dark)
            return SubjectColorChoice(id: value.id, name: value.name, ink: color)
        }
    }
}
extension Color {
    static func themeHex(_ hex: String) -> Color {
        let value = UInt32(hex, radix: 16) ?? 0
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
}

// Local font assets: checked, registered once per process, never fetched at runtime.
enum ThemeFonts {
    static let files = ["IMFellEnglish-Regular.ttf", "IMFellEnglish-Italic.ttf", "PirataOne-Regular.ttf"]
    static let postScriptNames = ["IM_FELL_English_Roman", "IM_FELL_English_Italic", "PirataOne-Regular"]
    static var resourceBundle: Bundle {
        // Application packages contain Fonts/ directly. SwiftPM test/build uses its resource bundle.
        if Bundle.main.url(forResource: "IMFellEnglish-Regular", withExtension: "ttf", subdirectory: "Fonts") != nil { return .main }
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
    static func register() throws {
        for (file, expected) in zip(files, postScriptNames) {
            guard let url = resourceBundle.url(forResource: file, withExtension: nil, subdirectory: "Fonts") else { throw FontError.missing(file) }
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !success {
                let registrationError = error?.takeRetainedValue()
                if registrationError.map({ CFErrorGetCode($0) }) != CTFontManagerError.alreadyRegistered.rawValue { throw FontError.registration(file) }
            }
            guard CTFontCopyPostScriptName(CTFontCreateWithName(expected as CFString, 20, nil)) as String == expected else { throw FontError.registration(file) }
        }
    }
    enum FontError: LocalizedError {
        case missing(String), registration(String)
        var errorDescription: String? {
            switch self { case .missing(let file): return L10n.tr("Manca il font locale %@.", file); case .registration(let file): return L10n.tr("Impossibile incorporare il font %@.", file) }
        }
    }
}

enum ThemeContrast {
    static func rgb(_ color: Color) -> [Double] {
        let c = NSColor(color).usingColorSpace(.sRGB)!
        return [c.redComponent, c.greenComponent, c.blueComponent]
    }
    static func color(_ channels: [Double]) -> Color { Color(.sRGB, red: channels[0], green: channels[1], blue: channels[2], opacity: 1) }
    static func luminance(_ c: [Double]) -> Double {
        zip(c, [0.2126, 0.7152, 0.0722]).reduce(0) { $0 + ($1.0 <= 0.04045 ? $1.0 / 12.92 : pow(($1.0 + 0.055) / 1.055, 2.4)) * $1.1 }
    }
    static func ratio(_ a: Color, _ b: Color) -> Double {
        let x = luminance(rgb(a)), y = luminance(rgb(b)); return (max(x,y) + 0.05) / (min(x,y) + 0.05)
    }
    static func composite(_ foreground: Color, on background: Color, opacity: Double) -> Color {
        color(zip(rgb(foreground), rgb(background)).map { $0 * opacity + $1 * (1 - opacity) })
    }
    static func accessibleInk(_ base: Color, mode: ThemeMode, surfaces: [Color], tile: Bool = false, minimum: Double = 4.5, spotlight: Color? = nil, tintOpacity: Double = 0) -> Color {
        let components = rgb(base)
        for n in 0...1000 {
            let fraction = Double(n) / 1000
            let ink = color(components.map { mode == .light ? $0 * (1 - fraction) : $0 + (1 - $0) * fraction })
            if surfaces.allSatisfy({ baseSurface in
                let surface = tintOpacity > 0 ? composite(ink, on: baseSurface, opacity: tintOpacity) : baseSurface
                guard ratio(ink, surface) >= minimum, !tile || ratio(ink, composite(ink, on: surface, opacity: DesignSystem.SubjectAppearance.fillOpacity)) >= minimum else { return false }
                guard let spotlight else { return true }
                let hoverInk = composite(spotlight, on: ink, opacity: DesignSystem.Interaction.spotlightOpacity)
                let hoverSurface = composite(spotlight, on: surface, opacity: DesignSystem.Interaction.spotlightOpacity)
                return ratio(hoverInk, hoverSurface) >= minimum
            }) { return ink }
        }
        return color(mode == .light ? [0,0,0] : [1,1,1])
    }
    static func darkSeed(_ base: Color) -> Color {
        let c = rgb(base), y = luminance(c)
        let l = y > 0.008856 ? 116 * pow(y, 1/3) - 16 : 903.3 * y
        let target = pow((min(100, l + 13) + 16) / 116, 3)
        let gray = (c.max()! + c.min()!) / 2
        let desaturated = c.map { gray + ($0 - gray) * 0.9 }
        for n in 0...1000 {
            let result = desaturated.map { $0 + (1 - $0) * Double(n) / 1000 }
            if luminance(result) >= target { return color(result) }
        }
        return .white
    }
}

enum HalloweenTheme {
    static let package = ThemePackage(
        id: "halloween", name: "Halloween", subtitle: "Luna, zucche e lucciole",
        light: variant(.light), dark: variant(.dark), copy: ThemeCopy(),
        themedCopy: ThemeCopy(emptyIllustration: .ghost, overrides: [
            .timerSubtitle: "Timer",
            .homeSubtitle: "Riepilogo delle sessioni.",
            .greeting: "Nessuna sessione attiva",
            .streak: "Serie: %d giorni", .streakSingular: "Serie: %d giorno"
        ]),
        behavior: ThemeBehavior(initialColorTab: .season(.autumn), replacesLandscapes: true, supportsSeason: false,
            suggestionWindow: ThemeSuggestionWindow(startMonth: 10, startDay: 15, endMonth: 11, endDay: 1)), options: [
                ThemeOption(id: ThemeOptionID.decorations, title: "Decorazioni", detail: "Luna, rami e piccole luci nella notte.", defaultValue: true)], cifreCellaFissa: true, logoMark: .jackOLantern)
    static func variant(_ mode: ThemeMode) -> ThemeVariant {
        var v = ThemeVariant(mode: mode)
        var p = v.palette
        func c(_ light: String, _ dark: String) -> Color { .themeHex(mode == .light ? light : dark) }
        p.background = c("F4EADB", "130F18")
        p.sidebar = c("EFE2D0", "181220")
        p.surface = c("FBF3E6", "1E1726")
        p.elevatedSurface = c("FFF9EF", "271E32")
        p.border = c("D8C7AE", "3A2D47")
        p.controlBorder = c("8B765F", "8A7897")
        p.sliderTrack = p.controlBorder
        p.textPrimary = c("2A1B33", "F1E6D2")
        p.textSecondary = c("5E4A6B", "B9AAC4")
        p.textTertiary = c("6F5C7A", "9A8BAA")
        p.inheritedText = p.textPrimary
        p.accent = c("A94E07", "E8872E")
        p.accentHover = c("9B4306", "F29A47")
        p.action = p.accent; p.actionHover = p.accentHover
        p.actionPressed = c("8B3E05", "DC7925")
        p.onAction = c("FFFFFF", "1A1220")
        p.accentSurface = c("E5D8EB", "352442")
        p.sidebarSelection = c("E0D0E9", "30203E")
        p.success = c("4F6B2A", "A8C66C")
        p.successSurface = c("E1E7CF", "29341E")
        p.warning = p.accent
        p.warningSurface = c("F0DDC2", "382519")
        p.error = c("B3261E", "E5645E")
        p.errorSurface = c("F5DBD3", "3D2229")
        p.interval = c("6F4DA3", "A98BD6")
        p.light = .themeHex("F5E6B8")
        p.spotlight = p.accent
        p.hill = c("786078", "281735")
        p.timerTrack = c("BDAACD", "32213F")
        p.timerBorder = p.border
        p.timerDivider = p.border
        p.timerGradientStart = c("A94E07", "F29A47")
        p.timerGradientEnd = c("8B3E05", "E8872E")
        p.disabledAction = c("E4D3BF", "4A354C")
        p.onDisabledAction = p.textSecondary
        p.disabledText = p.textSecondary
        p.landscapeTints = Dictionary(uniqueKeysWithValues: ["Morning", "Forest", "Rain", "Sunset", "Night"].map { ($0, Color.clear) })
        let surfaces = [p.background, p.sidebar, p.surface, p.elevatedSurface]
        // Correct only the new theme, never Komorebi's preserved palette.
        p.controlBorder = ThemeContrast.accessibleInk(p.controlBorder, mode: mode, surfaces: surfaces, minimum: 3)
        p.textPrimary = ThemeContrast.accessibleInk(p.textPrimary, mode: mode, surfaces: surfaces, spotlight: p.spotlight)
        p.textSecondary = ThemeContrast.accessibleInk(p.textSecondary, mode: mode, surfaces: surfaces, spotlight: p.spotlight)
        p.textTertiary = ThemeContrast.accessibleInk(p.textTertiary, mode: mode, surfaces: surfaces, spotlight: p.spotlight)
        p.accent = ThemeContrast.accessibleInk(p.accent, mode: mode, surfaces: surfaces, spotlight: p.spotlight, tintOpacity: 0.13)
        p.interval = ThemeContrast.accessibleInk(p.interval, mode: mode, surfaces: surfaces, spotlight: p.spotlight)
        p.success = ThemeContrast.accessibleInk(p.success, mode: mode, surfaces: surfaces, spotlight: p.spotlight)
        p.error = ThemeContrast.accessibleInk(p.error, mode: mode, surfaces: surfaces, spotlight: p.spotlight, tintOpacity: 0.16)
        p.warning = p.accent
        p.disabledText = p.textSecondary
        p.onDisabledAction = p.textSecondary
        p.sliderTrack = p.controlBorder
        p.timerTrack = c("BDAACD", "32213F").opacity(mode == .light ? 0.22 : 0.65)
        p.placeholder = p.textTertiary
        p.onAccentSurface = p.textPrimary
        p.sidebarSelectedIcon = p.accent
        p.sidebarSelectedText = p.textPrimary
        v.palette = p
        v.decoration.atmosphere = .moonlit
        v.decoration.hillOpacityBase = mode == .light ? 0.055 : 0.25
        v.decoration.hillOpacityStep = mode == .light ? 0.015 : 0.035
        v.decoration.particleCount = 7
        v.decoration.fireflyTint = c("A77920", "C3D47D")
        v.decoration.fireflyOpacity = mode == .light ? 0.10 : 0.18
        v.decoration.branchOpacity = mode == .light ? 0.10 : 0.22
        v.decoration.moonHaloOpacity = mode == .light ? 0.10 : 0.15
        v.decoration.moonDiscOpacity = mode == .light ? 0.12 : 0.15
        v.decoration.driftAmplitude = 0.025
        v.decoration.driftPeriod = 90
        v.decoration.candle = true
        v.appearance.destructiveInk = p.error; v.appearance.amberInk = p.warning
        v.appearance.controlBorderOpacity = 1
        v.appearance.disabledOpacity = 1
        v.appearance.sidebarOpacity = 1; v.appearance.sidebarSelectionOpacity = 1
        v.shadows.low = DesignSystem.Shadow(color: p.background.opacity(0.08), radius: 4, y: 2)
        v.shadows.medium = DesignSystem.Shadow(color: p.background.opacity(0.12), radius: 12, y: 4)
        v.shadows.high = DesignSystem.Shadow(color: p.background.opacity(0.16), radius: 24, y: 8)
        let base = ThemeVariant(mode: .light).subjectColors
        let seasonalColors = SeasonalSubjectColors.choices(mode: mode)
        v.subjectColors = base.map { choice in
            // Seasonal variants already retain their hue/chroma in each mode.
            // Reusing the classic white lift here would make the seasons look alike.
            let seasonal = seasonalColors.first { $0.id == choice.id }
            let seed = seasonal?.ink ?? (mode == .dark ? ThemeContrast.darkSeed(choice.ink) : choice.ink)
            return SubjectColorChoice(id: choice.id, name: choice.name, ink: ThemeContrast.accessibleInk(seed, mode: mode, surfaces: surfaces, tile: true, spotlight: p.spotlight))
        }
        func fell(_ size: CGFloat) -> Font { .custom("IM_FELL_English_Roman", fixedSize: size) }
        func pirata(_ size: CGFloat) -> Font { .custom("PirataOne-Regular", fixedSize: size) }
        v.typography.heading = fell(20)
        v.typography.title = pirata(28)
        v.typography.display = fell(40)
        v.typography.wordmark = pirata(28)
        v.typography.timerFontName = "PirataOne-Regular"
        v.typography.timerDigits = pirata(v.typography.timerPointSize)
        v.typography.timerGlow = p.accent
        v.typography.timerGlowOpacity = mode == .dark ? 0.2 : 0
        v.typography.timerTitle = fell(29)
        v.typography.timerSetupTitle = fell(23)
        v.typography.timerMessage = fell(25)
        v.preservedTypography.completionTitle = fell(28)
        v.preservedTypography.editorTitle = fell(25)
        v.preservedTypography.homeCardTitle = fell(20)
        v.preservedTypography.homeTitle = fell(31)
        v.preservedTypography.menuGreeting = fell(22)
        v.preservedTypography.menuWordmark = pirata(18)
        v.preservedTypography.pageTitle = pirata(30)
        v.preservedTypography.title2 = fell(17)
        v.preservedTypography.title3 = fell(15)
        return v
    }
}

enum ThemeOptionID {
    static let followSeason = "follow-season"
    static let decorations = "decorations"
    static let themedText = "themed-text"
}
enum ThemeAnimationPolicy {
    static func moving(visible: Bool, decorations: Bool, reduceMotion: Bool, animations: String) -> Bool {
        visible && decorations && !reduceMotion && animations != "Off"
    }
    static func candleOpacity(elapsed: Double, decoration: ThemeDecoration, active: Bool) -> Double {
        guard active else { return 1 }
        let half = (1 - decoration.candleMinimum) / 2
        return decoration.candleMinimum + half + half * cos(elapsed * 2 * .pi / decoration.candlePeriod)
    }
    static func batPhase(elapsed: Double, decoration: ThemeDecoration, moving: Bool) -> Double? {
        guard moving else { return nil }
        let phase = max(0, elapsed).truncatingRemainder(dividingBy: decoration.batPeriod)
        let start = decoration.batPeriod - decoration.batDuration
        return phase >= start ? (phase - start) / decoration.batDuration : nil
    }
}

/// Decorative vector geometry lives with the theme assets, never in individual screens.
enum ThemeArtwork {
    static let fireflyBase = 0.65
    static let fireflyAmplitude = 0.35
    static let batY = 0.075
    static let batAspect: CGFloat = 0.55
    static let bat: Path = {
        var p = Path()
        p.move(to: .init(x: 0.45, y: 0.35))
        p.addQuadCurve(to: .init(x: 0, y: 0.1), control: .init(x: 0.23, y: 0.05))
        p.addQuadCurve(to: .init(x: 0.13, y: 0.75), control: .init(x: 0.12, y: 0.45))
        p.addQuadCurve(to: .init(x: 0.28, y: 0.7), control: .init(x: 0.15, y: 0.5))
        p.addQuadCurve(to: .init(x: 0.43, y: 0.78), control: .init(x: 0.35, y: 0.52))
        p.addLine(to: .init(x: 0.5, y: 1)); p.addLine(to: .init(x: 0.57, y: 0.78))
        p.addQuadCurve(to: .init(x: 0.72, y: 0.7), control: .init(x: 0.65, y: 0.52))
        p.addQuadCurve(to: .init(x: 0.87, y: 0.75), control: .init(x: 0.85, y: 0.5))
        p.addQuadCurve(to: .init(x: 1, y: 0.1), control: .init(x: 0.88, y: 0.45))
        p.addQuadCurve(to: .init(x: 0.55, y: 0.35), control: .init(x: 0.77, y: 0.05))
        p.addLines([.init(x: 0.55, y: 0.12), .init(x: 0.5, y: 0.22), .init(x: 0.45, y: 0.12), .init(x: 0.45, y: 0.35)])
        p.closeSubpath(); return p
    }()
    static let branches: Path = {
        var p = Path()
        let lines: [[CGPoint]] = [
            [.init(x: 1, y: 0), .init(x: 0.94, y: 0.16), .init(x: 0.82, y: 0.31), .init(x: 0.76, y: 0.47)],
            [.init(x: 0.94, y: 0.16), .init(x: 0.82, y: 0.13), .init(x: 0.72, y: 0.05)],
            [.init(x: 0.89, y: 0.23), .init(x: 0.99, y: 0.38)],
            [.init(x: 0.82, y: 0.31), .init(x: 0.69, y: 0.30), .init(x: 0.63, y: 0.22)],
            [.init(x: 0.82, y: 0.13), .init(x: 0.78, y: 0.02)],
            [.init(x: 0.76, y: 0.47), .init(x: 0.68, y: 0.51)]
        ]
        for line in lines { p.addLines(line) }
        return p
    }()
    static let ghost: Path = {
        var p = Path()
        p.move(to: .init(x: 0.2, y: 0.86)); p.addLine(to: .init(x: 0.2, y: 0.40))
        p.addCurve(to: .init(x: 0.8, y: 0.40), control1: .init(x: 0.2, y: 0.03), control2: .init(x: 0.8, y: 0.03))
        p.addLine(to: .init(x: 0.8, y: 0.86)); p.addLines([.init(x: 0.7, y: 0.77), .init(x: 0.6, y: 0.86), .init(x: 0.5, y: 0.77), .init(x: 0.4, y: 0.86), .init(x: 0.3, y: 0.77), .init(x: 0.2, y: 0.86)])
        p.move(to: .init(x: 0.4, y: 0.4)); p.addLine(to: .init(x: 0.4, y: 0.46))
        p.move(to: .init(x: 0.6, y: 0.4)); p.addLine(to: .init(x: 0.6, y: 0.46))
        return p
    }()
}

enum SeasonalAccent {
    static func colorID(_ season: ThemeSeason) -> String {
        switch season { case .spring: return "primavera.ciliegio"; case .summer: return "estate.mare"; case .autumn: return "autunno.zucca"; case .winter: return "inverno.ardesia" }
    }
    static func apply(to base: ThemeVariant, mode: ThemeMode, season: ThemeSeason) -> ThemeVariant {
        var v = base
        guard let source = base.subjectColors.first(where: { $0.id == colorID(season) })?.ink else { return base }
        let surfaces = [base.palette.background, base.palette.sidebar, base.palette.surface, base.palette.elevatedSurface]
        let ink = ThemeContrast.accessibleInk(source, mode: mode, surfaces: surfaces, spotlight: base.palette.spotlight, tintOpacity: 0.13)
        let fill = ThemeContrast.accessibleInk(source, mode: .light, surfaces: [.white], minimum: 5.2)
        let hover = ThemeContrast.accessibleInk(ThemeContrast.composite(.white, on: fill, opacity: 0.06), mode: .light, surfaces: [.white])
        let pressed = ThemeContrast.composite(.black, on: fill, opacity: 0.06)
        v.palette.accent = ink; v.palette.accentHover = ink
        v.palette.action = fill; v.palette.actionHover = hover; v.palette.actionPressed = pressed
        v.palette.onAction = .white
        v.palette.disabledAction = ThemeContrast.composite(fill, on: base.palette.surface, opacity: 0.18)
        v.palette.onDisabledAction = base.palette.textSecondary
        v.palette.disabledText = base.palette.textSecondary
        v.appearance.disabledOpacity = 1
        v.palette.accentSurface = fill; v.palette.onAccentSurface = .white
        v.palette.sidebarSelection = fill
        v.palette.sidebarSelectedIcon = .white; v.palette.sidebarSelectedText = .white
        v.appearance.sidebarSelectionOpacity = 1
        v.palette.timerGradientStart = hover; v.palette.timerGradientEnd = fill
        v.palette.timerTrack = ink.opacity(0.07)
        v.palette.timerBorder = ink.opacity(0.12); v.palette.timerDivider = ink.opacity(0.10)
        return v
    }
}

struct ThemeCampaign: Identifiable {
    let package: ThemePackage
    let year: Int
    var id: String { package.id + "-" + String(year) }
    static func available(settings: UserSettings, date: Date, calendar: Calendar = .current) -> [ThemeCampaign] {
        ThemeRegistry.packages.compactMap { package in
            guard let window = package.behavior.suggestionWindow, window.contains(date, calendar: calendar), package.id != ThemeRegistry.package(settings.themeID).id else { return nil }
            let campaign = ThemeCampaign(package: package, year: window.campaignYear(date, calendar: calendar))
            return settings.dismissedThemeCampaigns?.contains(campaign.id) == true ? nil : campaign
        }
    }
}
extension ThemeSuggestionWindow {
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.month,.day], from: date)
        let value = (c.month ?? 1) * 100 + (c.day ?? 1), start = startMonth * 100 + startDay, end = endMonth * 100 + endDay
        return start <= end ? (start...end).contains(value) : value >= start || value <= end
    }
    func campaignYear(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year,.month,.day], from: date)
        let value = (c.month ?? 1) * 100 + (c.day ?? 1)
        return (c.year ?? 2000) - (startMonth * 100 + startDay > endMonth * 100 + endDay && value <= endMonth * 100 + endDay ? 1 : 0)
    }
}
extension StudyStore {
    func selectTheme(_ id: String?) {
        var next = settings; next.themeID = id
        let package = ThemeRegistry.package(id)
        if let window = package.behavior.suggestionWindow {
            let campaign = ThemeCampaign(package: package, year: window.campaignYear(now))
            var dismissed = next.dismissedThemeCampaigns ?? []
            if !dismissed.contains(campaign.id) { dismissed.append(campaign.id) }
            next.dismissedThemeCampaigns = dismissed
        }
        settings = next
    }
    func dismissThemeCampaign(_ id: String) {
        var dismissed = settings.dismissedThemeCampaigns ?? []
        guard !dismissed.contains(id) else { return }
        dismissed.append(id); settings.dismissedThemeCampaigns = dismissed
    }
}


/// Brand resources and their visual tokens belong to the package, independent of its name.
struct ThemeLogoMark {
    enum Artwork: Equatable { case systemSymbol(String), jackOLantern, pagesAndLight }
    enum ColorToken { case accent }
    var artwork: Artwork
    var colorToken: ColorToken = .accent
    var width: CGFloat = 32
    var height: CGFloat = 28
    var discOpacity = 0.6
    var glowEnabled = false
    var glowStart = Color.clear
    var glowEnd = Color.clear
    var glowOpacity = 0.18
    static let pagesAndLight = ThemeLogoMark(artwork: .pagesAndLight)
    static let leaf = ThemeLogoMark(artwork: .systemSymbol("leaf.fill"))
    static let jackOLantern = ThemeLogoMark(artwork: .jackOLantern, glowEnabled: true,
        glowStart: .themeHex("F5E6B8"), glowEnd: .themeHex("E8872E"))
    func tint(in palette: ThemePalette) -> Color {
        switch colorToken { case .accent: return palette.accent }
    }
}
struct ThemeBrand: View {
    @Environment(\.studyTheme) private var theme
    var body: some View {
        Label { Text(ProductText.wordmark) } icon: {
            ThemeLogoView()
        }.accessibilityElement(children: .ignore).accessibilityLabel(ProductText.wordmark)
    }
}
struct ThemeLogoView: View {
    @Environment(\.studyTheme) private var theme
    @Environment(\.komorebiMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.komorebiRendering) private var rendering
    @Environment(\.komorebiSectionVisible) private var sectionVisible
    private var illuminated: Bool { theme.logoMark.glowEnabled && theme.mode == .dark && theme.decorationsEnabled }
    private var moving: Bool { illuminated && ThemeAnimationPolicy.moving(visible: scenePhase != .background, decorations: theme.decorationsEnabled, reduceMotion: reduceMotion, animations: motion) }
    var body: some View {
        let mark = theme.logoMark
        Group {
            switch mark.artwork {
            case .systemSymbol(let name): Image(systemName: name)
            case .pagesAndLight:
                ZStack {
                    KomorebiPagesShape().fill(mark.tint(in: theme.palette))
                    KomorebiLightDisc().fill(mark.tint(in: theme.palette).opacity(mark.discOpacity))
                }.frame(width: mark.width, height: mark.height)
            case .jackOLantern:
                ZStack {
                    if illuminated { CompositedCandleGlow(mark: mark, decoration: theme.decoration, moving: moving && sectionVisible && rendering.ambientMotion) }
                    JackOLanternShape().fill(mark.tint(in: theme.palette), style: FillStyle(eoFill: true))
                }.frame(width: mark.width, height: mark.height)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
/// Approved B artwork: vector silhouette, transparent face and 1.5-unit incisions on a 32-unit grid.
struct JackOLanternShape: Shape {
    var faceOnly = false
    func path(in rect: CGRect) -> Path {
        var body = Path(), face = Path(), teeth = Path(), incisions = Path()
        body.move(to: CGPoint(x: 15, y: 7))
        body.addCurve(to: CGPoint(x: 18, y: 1.5), control1: CGPoint(x: 14, y: 5), control2: CGPoint(x: 15, y: 2))
        body.addQuadCurve(to: CGPoint(x: 19.5, y: 3), control: CGPoint(x: 20, y: 1))
        body.addQuadCurve(to: CGPoint(x: 17.5, y: 7), control: CGPoint(x: 17, y: 4))
        body.addCurve(to: CGPoint(x: 29, y: 12), control1: CGPoint(x: 22, y: 5), control2: CGPoint(x: 27, y: 7))
        body.addCurve(to: CGPoint(x: 23, y: 29), control1: CGPoint(x: 32, y: 19), control2: CGPoint(x: 29, y: 27))
        body.addCurve(to: CGPoint(x: 7, y: 29), control1: CGPoint(x: 19, y: 31), control2: CGPoint(x: 12, y: 31))
        body.addCurve(to: CGPoint(x: 2, y: 12), control1: CGPoint(x: 1, y: 27), control2: CGPoint(x: -1, y: 19))
        body.addCurve(to: CGPoint(x: 15, y: 7), control1: CGPoint(x: 4, y: 7), control2: CGPoint(x: 9, y: 5)); body.closeSubpath()
        face.move(to: CGPoint(x: 6, y: 12)); face.addQuadCurve(to: CGPoint(x: 8, y: 12), control: CGPoint(x: 6, y: 11))
        face.addLine(to: CGPoint(x: 13, y: 16)); face.addQuadCurve(to: CGPoint(x: 11, y: 17), control: CGPoint(x: 13, y: 17)); face.addLine(to: CGPoint(x: 7, y: 16)); face.closeSubpath()
        face.move(to: CGPoint(x: 24, y: 12)); face.addQuadCurve(to: CGPoint(x: 26, y: 13), control: CGPoint(x: 26, y: 11)); face.addLine(to: CGPoint(x: 25, y: 16)); face.addLine(to: CGPoint(x: 21, y: 17)); face.addQuadCurve(to: CGPoint(x: 20, y: 16), control: CGPoint(x: 19, y: 17)); face.closeSubpath()
        face.move(to: CGPoint(x: 16, y: 17)); face.addLines([CGPoint(x: 18, y: 20), CGPoint(x: 14, y: 20)]); face.closeSubpath()
        face.move(to: CGPoint(x: 6, y: 21)); face.addQuadCurve(to: CGPoint(x: 26, y: 21), control: CGPoint(x: 16, y: 25)); face.addQuadCurve(to: CGPoint(x: 16, y: 28), control: CGPoint(x: 24, y: 29)); face.addQuadCurve(to: CGPoint(x: 6, y: 21), control: CGPoint(x: 8, y: 29)); face.closeSubpath()
        teeth.addRect(CGRect(x: 11, y: 22, width: 2, height: 3)); teeth.addRect(CGRect(x: 19, y: 25, width: 2, height: 3))
        incisions.move(to: CGPoint(x: 9, y: 8)); incisions.addQuadCurve(to: CGPoint(x: 6, y: 18), control: CGPoint(x: 5, y: 12))
        incisions.move(to: CGPoint(x: 23, y: 8)); incisions.addQuadCurve(to: CGPoint(x: 26, y: 18), control: CGPoint(x: 27, y: 12))
        var result = faceOnly ? face : body
        if !faceOnly { result.addPath(face); result.addPath(teeth); result.addPath(incisions.strokedPath(StrokeStyle(lineWidth: 1.5, lineCap: .round))) }
        return result.applying(CGAffineTransform(scaleX: rect.width / 32, y: rect.height / 32).concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

/// Every digit receives the widest measured advance at the current font size.
struct TimerGlyphMetrics {
    let digitWidth: CGFloat
    let separatorWidth: CGFloat
    let lineHeight: CGFloat
    init(font: NSFont) {
        digitWidth = (0...9).map { (String($0) as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        separatorWidth = (":" as NSString).size(withAttributes: [.font: font]).width
        lineHeight = font.ascender - font.descender + font.leading
    }
    func width(of text: String) -> CGFloat { text.reduce(0) { $0 + ($1 == ":" ? separatorWidth : digitWidth) } }
    func centers(for text: String, available: CGSize) -> [(Character, CGPoint)] {
        let natural = width(of: text)
        let scale = min(1, available.width / max(1, natural), available.height / max(1, lineHeight))
        var x = (available.width - natural * scale) / 2
        return text.map { character in
            let width = (character == ":" ? separatorWidth : digitWidth) * scale
            defer { x += width }
            return (character, CGPoint(x: x + width / 2, y: available.height / 2))
        }
    }
    func scale(in available: CGSize, text: String) -> CGFloat {
        min(1, available.width / max(1, width(of: text)), available.height / max(1, lineHeight))
    }
}
/// Shared by Timer, Focus, breaks and the large menu-bar time. No per-character transitions.
struct ThemeFixedTimerDigits: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var theme
    let text: String
    let pointSize: CGFloat
    var body: some View {
        if pointSize >= theme.typography.minimumDecorativeTimerSize, let name = theme.typography.timerFontName,
           let font = NSFont(name: name, size: pointSize) {
            let metrics = TimerGlyphMetrics(font: font)
            Canvas { context, size in
                let scale = metrics.scale(in: size, text: text)
                for (character, point) in metrics.centers(for: text, available: size) {
                    context.draw(Text(String(character)).font(.custom(name, fixedSize: pointSize * scale)).foregroundStyle(theme.palette.textPrimary), at: point)
                }
            }
            .alignmentGuide(.firstTextBaseline) { dimensions in dimensions.height / 2 + font.capHeight / 2 }
            .shadow(color: theme.typography.timerGlow.opacity(theme.typography.timerGlowOpacity), radius: theme.typography.timerGlowRadius)
            .accessibilityElement(children: .ignore).accessibilityLabel(L10n.tr("Tempo")).accessibilityValue(text)
            .transaction { $0.animation = nil }
        }
    }
}

/// The artwork stays in SwiftUI; only its opacity is sampled by the compositor.
/// No display-link callback or per-frame ObservableObject publication is needed.
struct CompositedCandleGlow: NSViewRepresentable {
    let mark: ThemeLogoMark
    let decoration: ThemeDecoration
    let moving: Bool
    func makeNSView(context: Context) -> Host { Host() }
    func updateNSView(_ view: Host, context: Context) { view.configure(mark: mark, decoration: decoration, moving: moving) }
    static func dismantleNSView(_ view: Host, coordinator: ()) { view.stopObserving() }
    final class Host: NSView {
        private let artwork = NSHostingView(rootView: AnyView(EmptyView()))
        private var glowAppearance: Appearance?
        private var animationKey: String?
        private var moving = false
        private var decoration: ThemeDecoration?
        private var observers: [NSObjectProtocol] = []
        struct Appearance: Equatable { let start: Color; let end: Color; let opacity: Double }
        override init(frame: NSRect) {
            super.init(frame: frame)
            wantsLayer = true
            artwork.wantsLayer = true
            addSubview(artwork)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
        override func layout() { super.layout(); artwork.frame = bounds }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        func configure(mark: ThemeLogoMark, decoration: ThemeDecoration, moving: Bool) {
            let next = Appearance(start: mark.glowStart, end: mark.glowEnd, opacity: mark.glowOpacity)
            if next != glowAppearance {
                glowAppearance = next
                artwork.rootView = AnyView(JackOLanternShape(faceOnly: true)
                    .fill(LinearGradient(colors: [mark.glowStart, mark.glowEnd], startPoint: .top, endPoint: .bottom))
                    .opacity(mark.glowOpacity))
            }
            self.decoration = decoration; self.moving = moving
            updateAnimation()
        }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow(); stopObserving()
            guard let window else { return }
            let center = NotificationCenter.default
            for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification, NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
                observers.append(center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in self?.updateAnimation() })
            }
            for name in [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification] {
                observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.updateAnimation() })
            }
            updateAnimation()
        }
        func updateAnimation() {
            guard let decoration, let layer = artwork.layer else { return }
            let active = moving && window?.isVisible == true && window?.isMiniaturized == false && window?.occlusionState.contains(.visible) == true && NSApp.isActive
            let key = active ? "\(decoration.candlePeriod)|\(decoration.candleMinimum)|\(decoration.ringFrameInterval)" : nil
            guard key != animationKey else { return }
            layer.removeAnimation(forKey: "candleOpacity"); layer.opacity = 1; animationKey = key
            guard active else { return }
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = CandleOpacitySamples.values(decoration: decoration)
            animation.duration = decoration.candlePeriod
            animation.repeatCount = .infinity
            animation.calculationMode = .linear
            // Match the existing logo's global phase, including after an occlusion.
            animation.beginTime = layer.convertTime(CACurrentMediaTime(), from: nil) - Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: decoration.candlePeriod)
            layer.add(animation, forKey: "candleOpacity")
        }
        func stopObserving() {
            for observer in observers { NotificationCenter.default.removeObserver(observer) }
            observers.removeAll(); artwork.layer?.removeAnimation(forKey: "candleOpacity"); animationKey = nil
        }
        deinit { for observer in observers { NotificationCenter.default.removeObserver(observer) } }
    }
}
enum CandleOpacitySamples {
    static func values(decoration: ThemeDecoration) -> [Double] {
        let count = max(1, Int(ceil(decoration.candlePeriod / decoration.ringFrameInterval)))
        return (0...count).map { ThemeAnimationPolicy.candleOpacity(elapsed: Double($0) / Double(count) * decoration.candlePeriod, decoration: decoration, active: true) }
    }
}


/// Approved D artwork: two circular lenses at ±35°, plus a separate light disc.
/// Coordinates are shared with the delivered SVG master, on a 128-unit grid.
struct KomorebiPagesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let offset = sqrt(56.0 * 56 - 44.0 * 44)
        let angle = atan2(44.0, offset)
        var lens = Path()
        lens.move(to: CGPoint(x: 0, y: -44))
        lens.addArc(center: CGPoint(x: -offset, y: 0), radius: 56,
                    startAngle: .radians(-angle), endAngle: .radians(angle), clockwise: false)
        lens.addArc(center: CGPoint(x: offset, y: 0), radius: 56,
                    startAngle: .radians(.pi - angle), endAngle: .radians(.pi + angle), clockwise: false)
        lens.closeSubpath()
        var pages = Path()
        for (x, degrees) in [(35.0, -35.0), (93.0, 35.0)] {
            let radians = degrees * .pi / 180
            pages.addPath(lens, transform: CGAffineTransform(a: cos(radians) * 0.76, b: sin(radians) * 0.76,
                c: -sin(radians) * 0.76, d: cos(radians) * 0.76, tx: x, ty: 73))
        }
        return pages.applying(KomorebiBrandGeometry.fit(in: rect))
    }
}
struct KomorebiLightDisc: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: 50, y: 14, width: 28, height: 28))
            .applying(KomorebiBrandGeometry.fit(in: rect))
    }
}
enum KomorebiBrandGeometry {
    static func fit(in rect: CGRect) -> CGAffineTransform {
        // Tight optical viewport removes master padding without changing the artwork.
        let scale = min(rect.width / 104, rect.height / 92)
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
            tx: rect.midX - 64 * scale, ty: rect.midY - 58 * scale)
    }
}
