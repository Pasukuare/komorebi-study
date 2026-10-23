import XCTest
import AppKit
import SwiftUI
@testable import KomorebiStudy

@MainActor final class AppearanceTests: XCTestCase {
    func testSubjectCatalogHas36DistinctAvailableSymbols() {
        XCTAssertEqual(SubjectIcons.all.count, 36)
        XCTAssertEqual(Set(SubjectIcons.all.map(\.id)).count, 36)
        for icon in SubjectIcons.all {
            XCTAssertNotNil(NSImage(systemSymbolName: icon.id, accessibilityDescription: nil), icon.id)
        }
    }
    func testEightSubjectColorsPreserveLegacyIdentifiers() {
        XCTAssertEqual(SubjectPalette.choices.count, 8)
        XCTAssertEqual(Set(SubjectPalette.choices.map(\.id)).count, 8)
        for oldID in ["Salvia", "Cielo", "Tramonto", "Lavanda", "Terra"] {
            XCTAssertEqual(SubjectPalette.choice(oldID).id, SubjectColorID.canonical(oldID))
        }
    }
}


extension AppearanceTests {
    func testCalendarTextContrastInBothAppearances() {
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
                func luminance(_ color: Color) -> Double {
                    let rgb = NSColor(color).usingColorSpace(.sRGB)!
                    let channels = [Double(rgb.redComponent), Double(rgb.greenComponent), Double(rgb.blueComponent)].map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
                    return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
                }
                let text = luminance(DesignSystem.Palette.textPrimary)
                for surface in [DesignSystem.Palette.surface, DesignSystem.Palette.elevatedSurface] {
                    let background = luminance(surface)
                    XCTAssertGreaterThanOrEqual((max(text, background) + 0.05) / (min(text, background) + 0.05), 4.5, name.rawValue)
                }
            }
        }
    }
}

extension AppearanceTests {
    func testClassicSemanticColorsExactlyMatchBothBaselineVariants() {
        let expected: [(String, [Double], [Double])] = [
            ("classici.salvia", [0.30,0.37,0.32], [0.70,0.76,0.71]),
            ("classici.azzurro-polvere", [0.36,0.46,0.55], [0.67,0.75,0.82]),
            ("classici.lavanda", [0.48,0.42,0.56], [0.76,0.71,0.82]),
            ("classici.rosa-antico", [0.57,0.36,0.40], [0.83,0.66,0.69]),
            ("classici.terracotta", [0.57,0.37,0.29], [0.84,0.66,0.55]),
            ("classici.ocra", [0.55,0.43,0.31], [0.79,0.71,0.60]),
            ("classici.verde-muschio", [0.39,0.44,0.29], [0.73,0.77,0.59]),
            ("classici.grigio-caldo", [0.44,0.42,0.38], [0.76,0.73,0.66])
        ]
        for (index, name) in [NSAppearance.Name.aqua, .darkAqua].enumerated() {
            NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
                for (id, light, dark) in expected {
                    let color = NSColor(SubjectPalette.choice(id).ink).usingColorSpace(.sRGB)!
                    let actual = [Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent)]
                    for (a, b) in zip(actual, index == 0 ? light : dark) { XCTAssertEqual(a, b, accuracy: 0.000001, id) }
                }
                let fallback = NSColor(SubjectPalette.choice("autunno.zucca").ink).usingColorSpace(.sRGB)!
                let neutral = NSColor(SubjectPalette.choice(SubjectColorID.neutralID).ink).usingColorSpace(.sRGB)!
                XCTAssertEqual(fallback.redComponent, neutral.redComponent)
                XCTAssertEqual(fallback.greenComponent, neutral.greenComponent)
                XCTAssertEqual(fallback.blueComponent, neutral.blueComponent)
            }
        }
    }
}

extension AppearanceTests {
    func testCalendarDayWithoutInnerPlateKeepsAAOnAllPigmentsAndHover() {
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                for color in theme.subjectColors {
                    let background = ThemeContrast.composite(color.ink, on: theme.palette.background, opacity: DesignSystem.CalendarAppearance.pigmentOpacity)
                    XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(theme.palette.textPrimary, background), 4.5, "\(package.id) \(mode) \(color.id)")
                    let hoverBackground = ThemeContrast.composite(theme.palette.spotlight, on: background, opacity: DesignSystem.Interaction.spotlightOpacity)
                    let hoverText = ThemeContrast.composite(theme.palette.spotlight, on: theme.palette.textPrimary, opacity: DesignSystem.Interaction.spotlightOpacity)
                    XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(hoverText, hoverBackground), 4.5)
                }
            }
        }
    }
}

extension AppearanceTests {
    func testCalendarTooltipStaysInsideViewportAtEveryEdge() {
        for bounds in [CGSize(width: 696, height: 550), CGSize(width: 1100, height: 700)] {
            for x in [CGFloat(0), bounds.width / 2, bounds.width - 80] {
                for y in [CGFloat(0), bounds.height / 2, bounds.height - 76] {
                    for height in [CGFloat(120), 360] {
                        let size = CGSize(width: 220, height: height)
                        let point = CalendarTooltipPlacement.origin(cell: CGRect(x: x, y: y, width: 80, height: 76), tooltip: size, bounds: bounds, inset: 16, gap: 8)
                        XCTAssertGreaterThanOrEqual(point.x, 16)
                        XCTAssertGreaterThanOrEqual(point.y, 16)
                        XCTAssertLessThanOrEqual(point.x + size.width, bounds.width - 16)
                        XCTAssertLessThanOrEqual(point.y + size.height, bounds.height - 16)
                    }
                }
            }
        }
    }
    func testLogoBelongsToPackageAndHasReadableTint() {
        XCTAssertEqual(ThemeRegistry.defaultPackage.logoMark.artwork, .systemSymbol("leaf.fill"))
        XCTAssertEqual(HalloweenTheme.package.logoMark.artwork, .jackOLantern)
        for mode in ThemeMode.allCases {
            let theme = HalloweenTheme.package.resolve(mode: mode)
            XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(theme.logoMark.tint(in: theme.palette), theme.palette.sidebar), 3)
        }
        for size in [CGFloat(20), 28, 32, 48] {
            let path = JackOLanternShape().path(in: CGRect(x: 0, y: 0, width: size, height: size))
            XCTAssertFalse(path.isEmpty)
            XCTAssertLessThanOrEqual(path.boundingRect.maxX, size)
            XCTAssertLessThanOrEqual(path.boundingRect.maxY, size)
            // The eye is cut out; the stem and outer lobe remain filled.
            XCTAssertFalse(path.contains(CGPoint(x: size * 9 / 32, y: size * 15 / 32), eoFill: true))
            XCTAssertTrue(path.contains(CGPoint(x: size * 3 / 32, y: size * 20 / 32), eoFill: true))
        }
    }
}

extension AppearanceTests {
    func testRenderLogoAtRequestedSizes() throws {
        let sizes: [CGFloat] = [20, 28, 32, 48]
        for mode in ThemeMode.allCases {
            let theme = HalloweenTheme.package.resolve(mode: mode)
            let content = HStack(alignment: .center, spacing: 24) {
                ForEach(sizes, id: \.self) { size in
                    VStack(spacing: 16) {
                        ThemeLogoView().environment(\.studyTheme, theme).environment(\.komorebiMotion, "Off")
                            .scaleEffect(size / theme.logoMark.width)
                            .frame(width: 80, height: 64)
                        Text("\(Int(size)) pt").foregroundStyle(theme.palette.textPrimary)
                    }
                }
            }.padding(24).background(theme.palette.sidebar)
            let renderer = ImageRenderer(content: content); renderer.scale = 2
            let image = try XCTUnwrap(renderer.nsImage)
            if let folder = ProcessInfo.processInfo.environment["KOMOREBI_LOGO_RENDER"] {
                let data = try XCTUnwrap(image.tiffRepresentation)
                let bitmap = try XCTUnwrap(NSBitmapImageRep(data: data))
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("logo-B-\(mode.rawValue).png"))
            }
        }
    }
}

extension AppearanceTests {
    func testApprovedBrandKeepsPreviousWordmarkHeight() throws {
        for mode in ThemeMode.allCases {
            var previous = HalloweenTheme.package
            previous.logoMark = .leaf
            let before = previous.resolve(mode: mode)
            let after = HalloweenTheme.package.resolve(mode: mode)
            func size(_ theme: ResolvedTheme) throws -> CGSize {
                let renderer = ImageRenderer(content: ThemeBrand().font(theme.typography.wordmark).environment(\.studyTheme, theme).environment(\.komorebiMotion, "Off"))
                return try XCTUnwrap(renderer.nsImage).size
            }
            XCTAssertEqual(try size(before).height, try size(after).height, accuracy: 1)
        }
    }
}
