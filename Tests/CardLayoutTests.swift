import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class CardLayoutTests: XCTestCase {
    func testCardsStretchToTallestIntrinsicHeightWithLongTextInEveryTheme() throws {
        try ThemeFonts.register()
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                for width in [CGFloat(620), 1040] {
                    let row = EqualHeightCardRow(spacing: DesignSystem.Spacing.lg) {
                        Card(stretches: true) { Text("Breve").font(theme.typography.body) }
                        Card(stretches: true) { Text(String(repeating: "Un nome lungo per una materia e il suo percorso di studio. ", count: 4)).font(theme.typography.body) }
                    }.frame(width: width).environment(\.studyTheme, theme)
                    let renderer = ImageRenderer(content: row); renderer.scale = 1
                    let image = try XCTUnwrap(renderer.nsImage)
                    let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                    func verticalBounds(at x: Int) -> [Int] {
                        (0..<bitmap.pixelsHigh).filter { (bitmap.colorAt(x: x, y: $0)?.alphaComponent ?? 0) > 0.9 }
                    }
                    let left = verticalBounds(at: Int(width / 4))
                    let right = verticalBounds(at: Int(width * 3 / 4))
                    XCTAssertEqual(left.first, right.first)
                    XCTAssertEqual(left.last, right.last)
                    XCTAssertGreaterThan(bitmap.pixelsHigh, 100)
                    if let folder = ProcessInfo.processInfo.environment["KOMOREBI_CARD_RENDER"] {
                        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("row-\(package.id)-\(mode.rawValue)-\(Int(width)).png"))
                    }
                }
            }
        }
    }
}
