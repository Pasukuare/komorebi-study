import SwiftUI

extension Color {
    static let sage = Color(red: 0.34, green: 0.46, blue: 0.35)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
    static func subject(_ name: String) -> Color {
        switch name { case "Cielo": return .blue; case "Tramonto": return .orange; case "Lavanda": return .purple; case "Terra": return .brown; default: return .sage }
    }
}
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }.padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.primary.opacity(0.06)))
    }
}
struct Metric: View {
    var title: String; var value: String; var icon: String
    var body: some View { Card { Label(title, systemImage: icon).foregroundStyle(.secondary); Text(value).font(.system(size: 27, weight: .medium, design: .rounded)).monospacedDigit() } }
}
struct GoalBar: View {
    var title: String; var value: Double; var goal: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text(title); Spacer(); Text("\(durationText(value)) / \(durationText(goal))").foregroundStyle(.secondary) }
            ProgressView(value: min(value, max(1, goal)), total: max(1, goal)).tint(.sage)
        }
    }
}
struct Landscape: View {
    var theme: String
    var animations = "Reduced"
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) var scheme
    var body: some View {
        GeometryReader { g in
            let night = theme == "Night" || scheme == .dark
            let sky: Color = night ? Color(red: 0.12, green: 0.18, blue: 0.25) : theme == "Sunset" ? Color(red: 0.91, green: 0.74, blue: 0.62) : theme == "Forest" ? Color(red: 0.55, green: 0.70, blue: 0.58) : theme == "Rain" ? Color(red: 0.66, green: 0.76, blue: 0.78) : Color(red: 0.78, green: 0.86, blue: 0.78)
            ZStack {
                LinearGradient(colors: [sky, night ? .black.opacity(0.3) : .cream], startPoint: .top, endPoint: .bottom)
                Rectangle().fill(Color.orange.opacity(theme == "Morning" && Calendar.current.component(.hour, from: Date()) >= 15 ? 0.06 : 0)).allowsHitTesting(false)
                Circle().fill(night ? Color.cream.opacity(0.5) : .white.opacity(0.55)).frame(width: 80, height: 80).position(x: g.size.width * 0.8, y: g.size.height * 0.22)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: g.size.height * 0.72))
                    p.addCurve(to: CGPoint(x: g.size.width, y: g.size.height * 0.65), control1: CGPoint(x: g.size.width * 0.3, y: g.size.height * 0.25), control2: CGPoint(x: g.size.width * 0.7, y: g.size.height))
                    p.addLine(to: CGPoint(x: g.size.width, y: g.size.height)); p.addLine(to: CGPoint(x: 0, y: g.size.height)); p.closeSubpath()
                }.fill(Color.sage.opacity(0.18))
                Path { p in
                    p.move(to: CGPoint(x: 0, y: g.size.height * 0.85))
                    p.addQuadCurve(to: CGPoint(x: g.size.width, y: g.size.height * 0.8), control: CGPoint(x: g.size.width * 0.6, y: g.size.height * 0.45))
                    p.addLine(to: CGPoint(x: g.size.width, y: g.size.height)); p.addLine(to: CGPoint(x: 0, y: g.size.height)); p.closeSubpath()
                }.fill(Color.sage.opacity(0.18))
            }
        }.overlay {
            if animations == "Full" && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 12)) { time in
                    Canvas { context, size in
                        let t = time.date.timeIntervalSinceReferenceDate
                        let w = max(1, size.width)
                        let h = max(1, size.height)
                        for n in 0..<12 {
                            let rawX = (Double(n) * 81 + sin(t / 12 + Double(n)) * 15).truncatingRemainder(dividingBy: w)
                            let x = rawX < 0 ? rawX + w : rawX
                            let y = (Double(n) * 47 + t * 3).truncatingRemainder(dividingBy: h)
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)), with: .color(.white.opacity(0.22)))
                        }
                    }
                }
            }
        }.accessibilityHidden(true)
    }
}
