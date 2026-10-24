import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class SubjectPolishTests: XCTestCase {
    func testRenderSubjectScreensForReview() throws {
        guard let folder = ProcessInfo.processInfo.environment["KOMOREBI_SUBJECT_REVIEW"] else { return }
        try ThemeFonts.register()
        let defaults = UserDefaults(suiteName: "SubjectReview.\(UUID())")!
        let store = try StudyStore(inMemory: true, defaults: defaults)
        let subject = Subject(name: "Materia con un nome lungo per la prova della finestra", color: "inverno.brina")
        subject.isCompleted = true; subject.grade = "28"
        store.context.insert(subject); XCTAssertTrue(store.save())
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                func capture<V: View>(_ view: V, name: String) throws {
                    let renderer = ImageRenderer(content: view.environmentObject(store).environment(\.studyTheme, theme)
                        .environment(\.colorScheme, mode == .dark ? .dark : .light)
                        .buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()))
                    renderer.scale = 2
                    let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(renderer.nsImage?.tiffRepresentation)))
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name)-\(package.id)-\(mode.rawValue).png"))
                }
                try capture(SubjectEditor(subject: subject), name: "editor")
                try capture(SubjectsView().frame(width: 920, height: 650), name: "materie")
                try capture(VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach([true, false], id: \.self) { enabled in
                        HStack {
                            Button("Primario") {}.buttonStyle(StudyActionStyle())
                            Button("Secondario") {}.buttonStyle(ResponsiveButtonStyle())
                            Button("Elimina", role: .destructive) {}.buttonStyle(ResponsiveButtonStyle())
                            SidebarGhostToggle(isOpen: true, action: {})
                        }.disabled(!enabled)
                    }
                }.padding(DesignSystem.Spacing.xl).background(theme.palette.background), name: "pulsanti")
            }
        }
    }
}

extension SubjectPolishTests {
    func testButtonContrastAuditFromResolvedThemes() throws {
        var rows = ["tema,modalita,stile,stato,sfondo,contrasto,soglia"]
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode), p = theme.palette
                for (surfaceName, surface) in [("background", p.background), ("surface", p.surface), ("elevated", p.elevatedSurface)] {
                    func record(_ style: String, _ state: String, _ fg: Color, _ bg: Color, _ minimum: Double) {
                        let value = ThemeContrast.ratio(fg, bg)
                        rows.append("\(package.id),\(mode.rawValue),\(style),\(state),\(surfaceName),\(value),\(minimum)")
                        XCTAssertGreaterThanOrEqual(value, minimum, "\(package.id) \(mode) \(style) \(state) \(surfaceName)")
                    }
                    for state in ["default", "hover", "pressed", "focus", "disabled"] {
                        for style in ["action", "primary", "secondary", "destructive", "ghost"] {
                            if state == "disabled" {
                                record(style, state, p.onDisabledAction, p.disabledAction, 3)
                                XCTAssertEqual(p.disabledAction, p.surface)
                                XCTAssertEqual(p.onDisabledAction, p.textTertiary)
                                continue
                            }
                            let pressed = state == "pressed"
                            var fg: Color, bg: Color
                            switch style {
                            case "action":
                                fg = p.onAction
                                bg = pressed ? p.actionPressed ?? p.action : state == "hover" ? p.actionHover : p.action
                            case "primary":
                                fg = p.onAccentSurface
                                bg = ThemeContrast.composite(p.accentSurface, on: surface, opacity: pressed ? theme.appearance.opacity0_76 : 1)
                            case "secondary":
                                fg = p.accent
                                bg = ThemeContrast.composite(p.accent, on: surface, opacity: pressed ? theme.appearance.opacity0_13 : theme.appearance.opacity0_055)
                            case "destructive":
                                fg = p.buttonDestructiveInk
                                bg = ThemeContrast.composite(fg, on: surface, opacity: pressed ? theme.appearance.opacity0_16 : theme.appearance.opacity0_07)
                            default:
                                fg = state == "hover" ? p.textPrimary : p.textSecondary
                                bg = ThemeContrast.composite(p.accent, on: surface, opacity: pressed ? DesignSystem.SidebarToggle.pressedOpacity : state == "hover" ? DesignSystem.SidebarToggle.hoverOpacity : 0)
                            }
                            if state == "hover" && style != "ghost" && mode == .dark {
                                fg = ThemeContrast.composite(p.spotlight, on: fg, opacity: DesignSystem.Interaction.spotlightOpacity)
                                bg = ThemeContrast.composite(p.spotlight, on: bg, opacity: DesignSystem.Interaction.spotlightOpacity)
                            }
                            record(style, state, fg, bg, 4.5)
                            if state == "focus" { record(style, "focus-ring", p.accent, surface, 3) }
                        }
                    }
                }
            }
        }
        if let output = ProcessInfo.processInfo.environment["KOMOREBI_BUTTON_AUDIT"] {
            try (rows.joined(separator: "\n")+"\n").write(toFile: output, atomically: true, encoding: .utf8)
        }
    }
}
