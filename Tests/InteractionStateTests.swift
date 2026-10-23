import XCTest
import SwiftUI
import AppKit
import Combine
@testable import KomorebiStudy

@MainActor final class InteractionStateTests: XCTestCase {
    func testOnlyKeyboardNavigationEnablesFocusOutline() {
        for focused in [false, true] {
            for enabled in [false, true] {
                for visible in [false, true] {
                    for input in [StudyInputKind.none, .pointer, .keyboard] {
                        XCTAssertEqual(StudyFocusPolicy.showsRing(focused: focused, input: input, enabled: enabled, visible: visible), focused && enabled && visible && input == .keyboard)
                    }
                }
            }
        }
        XCTAssertEqual(DesignSystem.Interaction.focusInset, 2)
        XCTAssertEqual(DesignSystem.Interaction.focusWidth, 2)
    }
    func testNavigationKeysDoNotTurnTextOrCommandsIntoFocusNavigation() {
        for key: UInt16 in [48, 123, 124, 125, 126] {
            XCTAssertTrue(StudyFocusPolicy.isNavigationKey(key, modifiers: []))
            XCTAssertTrue(StudyFocusPolicy.isNavigationKey(key, modifiers: .shift))
            for modifier in [NSEvent.ModifierFlags.command, .control, .option] {
                XCTAssertFalse(StudyFocusPolicy.isNavigationKey(key, modifiers: modifier))
            }
        }
        for key: UInt16 in [0, 1, 35, 36, 49, 53] { XCTAssertFalse(StudyFocusPolicy.isNavigationKey(key, modifiers: [])) }
    }
    func testScopeResetAndPointerRemoveKeyboardFocusWithoutChangingData() {
        let session = StudyInteractionSession()
        XCTAssertEqual(session.input, .none)
        var changes = 0
        let token = session.objectWillChange.sink { changes += 1 }
        session.setInput(.keyboard); session.setInput(.keyboard)
        XCTAssertEqual(changes, 1)
        session.setInput(.pointer)
        XCTAssertFalse(StudyFocusPolicy.showsRing(focused: true, input: session.input, enabled: true, visible: true))
        session.setInput(.keyboard); session.resetScope()
        XCTAssertEqual(session.input, .none)
        withExtendedLifetime(token) {}
    }
    func testOneHoverOwnerIsTheInnermostVisibleTarget() {
        let full = CGRect(x: 0, y: 0, width: 400, height: 160)
        let button = CGRect(x: 100, y: 50, width: 120, height: 44)
        let candidates = [StudyHoverCandidate(id: "card", frame: full, visibleFrame: full, radius: 14, depth: 2, enabled: true),
                          StudyHoverCandidate(id: "button", frame: button, visibleFrame: button, radius: 8, depth: 3, enabled: true)]
        XCTAssertEqual(StudyHoverPolicy.winner(at: CGPoint(x: 150, y: 70), candidates: candidates), "button")
        XCTAssertEqual(StudyHoverPolicy.winner(at: CGPoint(x: 30, y: 70), candidates: candidates), "card")
        XCTAssertNil(StudyHoverPolicy.winner(at: CGPoint(x: 500, y: 70), candidates: candidates))
    }
    func testDisabledClippedAndRoundedCornersDoNotKeepHover() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 44)
        func candidate(enabled: Bool, visible: CGRect) -> StudyHoverCandidate<Int> {
            .init(id: 1, frame: rect, visibleFrame: visible, radius: 14, depth: 0, enabled: enabled)
        }
        XCTAssertNil(StudyHoverPolicy.winner(at: .zero, candidates: [candidate(enabled: true, visible: rect)]))
        XCTAssertNil(StudyHoverPolicy.winner(at: CGPoint(x: 30,y: 20), candidates: [candidate(enabled: false, visible: rect)]))
        XCTAssertNil(StudyHoverPolicy.winner(at: CGPoint(x: 30,y: 20), candidates: [candidate(enabled: true, visible: CGRect(x: 60,y: 0,width: 40,height: 44))]))
        XCTAssertNil(StudyHoverPolicy.winner(at: CGPoint(x: 30,y: 20), candidates: [] as [StudyHoverCandidate<Int>]))
    }
    func testCircularSwatchUsesCircleInsteadOfRectangularHitArea() {
        let rect = CGRect(x: 0,y: 0,width: 36,height: 44)
        let candidate = StudyHoverCandidate(id: 1, frame: rect, visibleFrame: rect, radius: 22, shape: .circle, depth: 1, enabled: true)
        XCTAssertNil(StudyHoverPolicy.winner(at: CGPoint(x: 1,y: 1), candidates: [candidate]))
        XCTAssertEqual(StudyHoverPolicy.winner(at: CGPoint(x: 18,y: 22), candidates: [candidate]), 1)
        let enlarged = StudySurfaceShape(kind: .circle).inset(by: -2).path(in: rect)
        XCTAssertEqual(enlarged.boundingRect.width, 40, accuracy: 0.01)
    }
    func testListRowsNeverLiftOrUseSpotlightAndLightNeverHasSpotlight() {
        for mode in ThemeMode.allCases {
            XCTAssertFalse(StudyHoverAppearance.spotlight(mode: mode, listRow: true, selected: false))
            XCTAssertFalse(StudyHoverAppearance.spotlight(mode: mode, listRow: false, selected: true))
            for reduce in [false,true] {
                XCTAssertFalse(StudyHoverAppearance.lifts(active: true, listRow: true, decorative: false, reduceMotion: reduce, motion: "Full"))
            }
        }
        XCTAssertFalse(StudyHoverAppearance.spotlight(mode: .light, listRow: false, selected: false))
        XCTAssertTrue(StudyHoverAppearance.spotlight(mode: .dark, listRow: false, selected: false))
        XCTAssertFalse(StudyHoverAppearance.lifts(active: true,listRow: false,decorative: false,reduceMotion: true,motion: "Full"))
    }
    func testFocusRingIsAbsentForMouseAndInitialFocusInRender() throws {
        let theme = ThemeRegistry.defaultPackage.resolve(mode: .light)
        let session = StudyInteractionSession()
        func bitmap(_ input: StudyInputKind, focused: Bool) throws -> Data {
            session.setInput(input)
            let content = Text("Controllo").padding(12).frame(width: 150,height: 44)
                .background(theme.palette.surface, in: RoundedRectangle(cornerRadius: 8))
                .modifier(KeyboardFocusBorder(explicitFocus: focused))
                .padding(8).background(theme.palette.background)
                .environment(\.studyTheme, theme).environment(\.studyInteraction, session)
            let renderer = ImageRenderer(content: content); renderer.scale = 1
            return try XCTUnwrap(try XCTUnwrap(renderer.nsImage).tiffRepresentation)
        }
        let neutral = try bitmap(.none, focused: false)
        XCTAssertEqual(try bitmap(.none,focused: true), neutral)
        XCTAssertEqual(try bitmap(.pointer,focused: true), neutral)
        XCTAssertNotEqual(try bitmap(.keyboard,focused: true), neutral)
    }
}

extension InteractionStateTests {
    func testRenderComponentStatesInBothThemesAndModes() throws {
        try ThemeFonts.register()
        let suite = "InteractionRenders.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        let date = Date(timeIntervalSince1970: 1_792_764_000)
        let record = StudySession(start: date, end: date.addingTimeInterval(3600), duration: 3600, subjectID: store.subjects.first?.id, subjectName: "Programmazione", mode: TimerMode.pomodoro.rawValue, pause: 0, note: "Esercizi e ripasso")
        let input = StudyInteractionSession()
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                for state in ["riposo", "hover", "tastiera"] {
                    input.setInput(state == "tastiera" ? .keyboard : state == "hover" ? .pointer : .none)
                    for screen in ["Home", "Timer", "Materie", "Cronologia", "Impostazioni"] {
                        let radius = screen == "Cronologia" ? DesignSystem.Radius.card : screen == "Timer" ? DesignSystem.Radius.panel : screen == "Home" ? DesignSystem.Radius.action : DesignSystem.Radius.control
                        let fixture = fixture(screen, record: record, theme: theme)
                            .overlay { StudyHoverDecoration(active: state == "hover", location: CGPoint(x: 80,y: 20), radius: radius, listRow: screen == "Cronologia" || screen == "Impostazioni") }
                            .modifier(KeyboardFocusBorder(radius: radius, explicitFocus: true))
                        let content = VStack(alignment: .leading, spacing: 16) {
                            Text("\(screen) · \(state) · stato forzato, non UI nativa").font(theme.typography.caption)
                            fixture
                        }.padding(24).frame(width: 640, alignment: .leading)
                            .background(theme.palette.background).foregroundStyle(theme.palette.textPrimary)
                            .environmentObject(store).environment(\.studyTheme, theme)
                            .environment(\.studyInteraction, input).environment(\.komorebiMotion, "Off")
                            .toggleStyle(StudyToggleStyle()).textFieldStyle(StudyTextFieldStyle())
                        let renderer = ImageRenderer(content: content); renderer.scale = 1
                        let image = try XCTUnwrap(renderer.nsImage)
                        XCTAssertEqual(image.size.width, 640)
                        if let folder = ProcessInfo.processInfo.environment["KOMOREBI_INTERACTION_RENDER"] {
                            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                            try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(screen)-\(package.id)-\(mode.rawValue)-\(state).png"))
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder private func fixture(_ screen: String, record: StudySession, theme: ResolvedTheme) -> some View {
        switch screen {
        case "Home": Button("Inizia a studiare") {}.buttonStyle(StudyActionStyle()).fixedSize()
        case "Timer": StudyNumberField(title: "Minuti",value: .constant(50),range: 1...600).frame(width: 180)
        case "Materie": SubjectIconPicker(selection: .constant("book.closed"),color: theme.subjectColor(SubjectColorID.defaultID)).fixedSize()
        case "Cronologia": HistorySessionRow(session: record,edit: {},delete: {}).frame(width: 560)
        default:
            Toggle(isOn: .constant(true)) {
                VStack(alignment: .leading,spacing: 4) {
                    Text("Segui la stagione")
                    Text("Un accento diverso, con il ritmo dell’anno.").font(.caption)
                }
            }.frame(width: 560)
        }
    }
}

extension InteractionStateTests {
    func testSelectionDoesNotDrawASecondOutlineAndDisabledKeepsItsSelection() throws {
        let input = StudyInteractionSession()
        func ink(_ kind: StudyInputKind, enabled: Bool) throws -> Double {
            input.setInput(kind)
            let content = StudySelectionBorder(selected: true, color: .green, explicitFocus: true)
                .frame(width: 60,height: 44).padding(6).disabled(!enabled).environment(\.studyInteraction, input)
            let image = try XCTUnwrap(ImageRenderer(content: content).nsImage)
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
            return (0..<bitmap.pixelsWide).reduce(0.0) { sum,x in sum + (0..<bitmap.pixelsHigh).reduce(0.0) { $0 + (bitmap.colorAt(x: x,y: $1)?.alphaComponent ?? 0) } }
        }
        XCTAssertEqual(try ink(.keyboard,enabled: true), 0, accuracy: 0.01)
        XCTAssertGreaterThan(try ink(.pointer,enabled: true), 0)
        XCTAssertGreaterThan(try ink(.keyboard,enabled: false), 0)
    }
}
