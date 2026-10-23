import XCTest
@testable import KomorebiStudy

final class CompositorTests: XCTestCase {
    func testCompositorPreservesCandleCurveAndPeriod() {
        let decoration = HalloweenTheme.package.dark.decoration
        let samples = CandleOpacitySamples.values(decoration: decoration)
        XCTAssertEqual(samples.first, samples.last)
        for n in 0...2000 {
            let t = Double(n) / 2000 * decoration.candlePeriod
            let position = t / decoration.candlePeriod * Double(samples.count - 1)
            let i = min(samples.count - 2, Int(position))
            let fraction = position - Double(i)
            let interpolated = samples[i] * (1 - fraction) + samples[i + 1] * fraction
            XCTAssertEqual(interpolated, ThemeAnimationPolicy.candleOpacity(elapsed: t, decoration: decoration, active: true), accuracy: 0.0001)
            XCTAssertGreaterThanOrEqual(interpolated, decoration.candleMinimum)
            XCTAssertLessThanOrEqual(interpolated, 1)
        }
    }
}
