import SwiftUI
import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { UNUserNotificationCenter.current().delegate = self }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner, .sound]) }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeKey {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
        completionHandler()
    }
}
@main struct KomorebiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store: StudyStore
    init() {
        do { let instance = try StudyStore(); _store = StateObject(wrappedValue: instance) }
        catch {
            let alert = NSAlert(); alert.messageText = "Impossibile aprire l’archivio"; alert.informativeText = "I dati non sono stati cancellati. \(error.localizedDescription)"; alert.runModal()
            fatalError("Cannot open persistent store: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup("Komorebi Study", id: "main") {
            RootView().environmentObject(store).frame(minWidth: 920, minHeight: 650)
                .preferredColorScheme(store.settings.appearance == "System" ? nil : store.settings.appearance == "Dark" ? .dark : .light)
        }.defaultSize(width: 1140, height: 790)
        .commands {
            CommandMenu("Studio") {
                Button("Avvia sessione") { store.start() }.keyboardShortcut(.return, modifiers: .command).disabled(store.active != nil)
                Button("Pausa / Riprendi") { store.toggle() }.keyboardShortcut(.space, modifiers: [])
                Button("Termina sessione") { store.finish() }.keyboardShortcut(".", modifiers: .command).disabled(store.active == nil)
            }
        }
        MenuBarExtra {
            MenuPanel().environmentObject(store)
        } label: {
            Label(store.active.map { clockText($0.displayed(at: store.now)) } ?? "Komorebi", systemImage: "leaf")
        }.menuBarExtraStyle(.window)
    }
}
struct MenuPanel: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.openWindow) var openWindow
    var body: some View {
        VStack(spacing: 16) {
            Label("Komorebi Study", systemImage: "leaf").font(.headline)
            Text(store.active?.subjectName ?? "Un momento per concentrarti").foregroundStyle(.secondary)
            Text(store.active.map { clockText($0.displayed(at: store.now)) } ?? "Pronto").font(.largeTitle).monospacedDigit()
            HStack {
                Button(store.active == nil ? "Avvia" : store.active?.pausedAt == nil ? "Pausa" : "Riprendi") { store.toggle() }
                if store.active != nil { Button("Termina") { store.finish() } }
            }
            Button("Apri app") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeKey {
                    if window.isMiniaturized { window.deminiaturize(nil) }
                    window.makeKeyAndOrderFront(nil)
                }
            }
            Divider(); Button("Esci da Komorebi") { NSApp.terminate(nil) }
        }.padding(22).frame(width: 290)
    }
}
