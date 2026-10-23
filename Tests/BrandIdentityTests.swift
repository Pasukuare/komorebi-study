import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class BrandIdentityTests: XCTestCase {
    private var root: URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent() }
    func testDIsOwnedByKomorebiWhileHalloweenKeepsPumpkin() {
        XCTAssertEqual(ThemeRegistry.defaultPackage.logoMark.artwork, .pagesAndLight)
        XCTAssertEqual(HalloweenTheme.package.logoMark.artwork, .jackOLantern)
        for mode in ThemeMode.allCases {
            let theme = ThemeRegistry.defaultPackage.resolve(mode: mode)
            XCTAssertEqual(theme.logoMark.tint(in: theme.palette), theme.palette.accent)
            XCTAssertEqual(theme.logoMark.discOpacity, 0.6)
            XCTAssertFalse(theme.logoMark.glowEnabled)
            XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(theme.logoMark.tint(in: theme.palette), theme.palette.sidebar), 3)
            for season in [ThemeSeason.spring, .summer, .autumn, .winter] {
                let variant = ThemeRegistry.seasonalVariant(package: ThemeRegistry.defaultPackage, mode: mode, season: season)
                XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(theme.logoMark.tint(in: variant.palette), variant.palette.sidebar), 3)
            }
        }
    }
    func testPagesHaveTransparentGapAndSymmetricLensesAtAllSizes() {
        for size in [CGFloat(16), 20, 24, 28, 32, 48, 128] {
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let path = KomorebiPagesShape().path(in: rect)
            let s = size / 128
            XCTAssertTrue(path.contains(CGPoint(x: 35*s, y: 73*s)))
            XCTAssertTrue(path.contains(CGPoint(x: 93*s, y: 73*s)))
            XCTAssertFalse(path.contains(CGPoint(x: 64*s, y: 73*s)))
            // CoreGraphics approximates circular arcs with cubics (<0.01 unit error).
            XCTAssertEqual(path.boundingRect.midX, size / 2, accuracy: 0.01)
            XCTAssertTrue(rect.contains(path.boundingRect))
            let disc = KomorebiLightDisc().path(in: rect)
            XCTAssertTrue(disc.contains(CGPoint(x: 64*s, y: 28*s)))
            XCTAssertLessThan(disc.boundingRect.maxY, path.boundingRect.minY)
        }
    }
    func testNewBrandPreservesWordmarkHeightAndRendersInBothModes() throws {
        for mode in ThemeMode.allCases {
            var old = ThemeRegistry.defaultPackage; old.logoMark = .leaf
            let current = ThemeRegistry.defaultPackage.resolve(mode: mode)
            func size(_ theme: ResolvedTheme) throws -> CGSize {
                let renderer = ImageRenderer(content: ThemeBrand().font(theme.typography.wordmark).environment(\.studyTheme, theme))
                return try XCTUnwrap(renderer.nsImage).size
            }
            XCTAssertEqual(try size(old.resolve(mode: mode)).height, try size(current).height, accuracy: 1)
            for width in [CGFloat(16), 20, 28, 32, 48] {
                let renderer = ImageRenderer(content: ThemeLogoView().environment(\.studyTheme, current)
                    .scaleEffect(width / current.logoMark.width).frame(width: 64, height: 64)
                    .background(current.palette.sidebar))
                XCTAssertNotNil(renderer.nsImage)
            }
        }
    }
    func testICNSContainsEveryStandardAndRetinaPNG() throws {
        let data = try Data(contentsOf: root.appendingPathComponent("Resources/AppIcon.icns"))
        func word(_ offset: Int) -> Int { data[offset..<(offset+4)].reduce(0) { $0 * 256 + Int($1) } }
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "icns")
        XCTAssertEqual(word(4), data.count)
        let expected = ["icp4":16,"ic11":32,"icp5":32,"ic12":64,"ic07":128,"ic13":256,"ic08":256,"ic14":512,"ic09":512,"ic10":1024]
        var offset = 8, found: [String:Int] = [:]
        while offset < data.count {
            let tag = String(data: data[offset..<(offset+4)], encoding: .ascii)!
            let count = word(offset+4)
            XCTAssertGreaterThan(count, 8)
            guard count > 8, offset + count <= data.count else { XCTFail("Invalid ICNS chunk"); return }
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: data[(offset+8)..<(offset+count)]))
            XCTAssertEqual(bitmap.pixelsWide, bitmap.pixelsHigh)
            found[tag] = bitmap.pixelsWide
            offset += count
        }
        XCTAssertEqual(found, expected)
        XCTAssertNotNil(NSImage(contentsOf: root.appendingPathComponent("Resources/AppIcon.icns")))
    }
}

extension BrandIdentityTests {
    func testRenderBeforeAfterBrandWithoutChangingWordmark() throws {
        for mode in ThemeMode.allCases {
            let theme = ThemeRegistry.defaultPackage.resolve(mode: mode)
            var previous = ThemeRegistry.defaultPackage; previous.logoMark = .leaf
            let before = previous.resolve(mode: mode)
            let content = HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Prima").font(theme.typography.caption)
                    ThemeBrand().font(theme.typography.wordmark).environment(\.studyTheme, before).fixedSize()
                }
                VStack(alignment: .leading, spacing: 20) {
                    Text("D · dopo").font(theme.typography.caption)
                    ThemeBrand().font(theme.typography.wordmark).environment(\.studyTheme, theme).fixedSize()
                }
            }.foregroundStyle(theme.palette.accent).padding(32).background(theme.palette.sidebar)
            let renderer = ImageRenderer(content: content); renderer.scale = 2
            let image = try XCTUnwrap(renderer.nsImage)
            if let directory = ProcessInfo.processInfo.environment["KOMOREBI_D_RENDER"] {
                let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: directory).appendingPathComponent("marchio-prima-dopo-\(mode.rawValue).png"))
            }
        }
    }
}
