// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "KomorebiStudy", platforms: [.macOS(.v15)], products: [.executable(name: "KomorebiStudy", targets: ["KomorebiStudy"])], targets: [.executableTarget(name: "KomorebiStudy", path: "Sources"), .testTarget(name: "KomorebiStudyTests", dependencies: ["KomorebiStudy"], path: "Tests")], swiftLanguageModes: [.v5])
