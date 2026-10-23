import Foundation
import AppKit
import UniformTypeIdentifiers
import SQLite3

struct SessionRecord: Codable {
    var id: UUID; var start: Date; var end: Date; var duration: Double; var subjectID: UUID?; var subject: String; var mode: String; var pause: Double; var note: String; var activityData: Data? = nil
    init(_ s: StudySession) { id = s.id; start = s.startDate; end = s.endDate; duration = s.duration; subjectID = s.subjectID; subject = s.subjectName; mode = s.timerMode; pause = s.pauseDuration; note = s.note; activityData = s.activityData }
    var model: StudySession { let session = StudySession(id: id, start: start, end: end, duration: duration, subjectID: subjectID, subjectName: subject, mode: mode, pause: pause, note: note); session.activityData = activityData; return session }
}
struct SubjectRecord: Codable {
    var id: UUID; var name: String; var icon: String; var color: String; var weeklyGoal: Double
    init(_ s: Subject) { id = s.id; name = s.name; icon = s.icon; color = SubjectColorID.canonical(s.color); weeklyGoal = s.weeklyGoal }
    var model: Subject {
        let subject = Subject(name: name, icon: icon, color: color, weeklyGoal: weeklyGoal)
        subject.id = id
        return subject
    }
}
struct Backup: Codable { var version = 1; var settings: UserSettings; var subjects: [SubjectRecord]; var sessions: [SessionRecord]; var exams: [ExamRecord]? = nil }
@MainActor extension StudyStore {
    func export(csv: Bool) {
        let panel = NSSavePanel(); panel.title = csv ? L10n.tr("Esporta CSV") : L10n.tr("Backup JSON"); panel.prompt = L10n.tr("Salva"); panel.nameFieldStringValue = csv ? "Komorebi-sessioni.csv" : "Komorebi-backup.json"; panel.allowedContentTypes = [csv ? .commaSeparatedText : .json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data: Data
            if csv {
                func quote(_ s: String) -> String {
                    let safe = ["=", "+", "-", "@", "\t", "\r"].contains(where: { s.hasPrefix($0) }) ? "'" + s : s
                    return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                }
                let header = "id,start,end,duration_seconds,subject,mode,pause_seconds,note"
                let rows = sessions.map { s in [s.id.uuidString, s.startDate.ISO8601Format(), s.endDate.ISO8601Format(), String(s.duration), s.subjectName, s.timerMode, String(s.pauseDuration), s.note].map(quote).joined(separator: ",") }
                data = ([header] + rows).joined(separator: "\r\n").data(using: .utf8)!
            } else {
                let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
                data = try encoder.encode(Backup(settings: settings, subjects: subjects.map(SubjectRecord.init), sessions: sessions.map(SessionRecord.init), exams: exams.map(ExamRecord.init)))
            }
            try data.write(to: url, options: .atomic)
        } catch { self.error = L10n.errorMessage(error) }
    }
    func restore() {
        guard active == nil else { error = L10n.tr("Termina la sessione prima di importare un backup."); return }
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(Backup.self, from: Data(contentsOf: url))
            guard backup.version == 1, (backup.exams ?? []).allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }), backup.sessions.allSatisfy({ $0.duration.isFinite && $0.pause.isFinite && $0.duration >= 0 && $0.pause >= 0 && $0.end >= $0.start && $0.duration + $0.pause <= $0.end.timeIntervalSince($0.start) + 2 }), backup.subjects.allSatisfy({ !$0.name.isEmpty && $0.weeklyGoal.isFinite && $0.weeklyGoal >= 0 }), backup.settings.dailyGoal > 0, backup.settings.weeklyGoal > 0 else { throw CocoaError(.fileReadCorruptFile) }
            let alert = NSAlert(); alert.messageText = L10n.tr("Importa backup locale"); alert.informativeText = L10n.tr("Verranno aggiunte le sessioni e le materie mancanti. I dati esistenti saranno conservati. Le impostazioni verranno aggiornate."); alert.addButton(withTitle: L10n.tr("Importa")); alert.addButton(withTitle: L10n.tr("Annulla"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            var subjectIDs = Set(subjects.map(\.id)); var sessionIDs = Set(sessions.map(\.id))
            for s in backup.subjects where subjectIDs.insert(s.id).inserted {
                context.insert(s.model)
            }
            for s in backup.sessions where sessionIDs.insert(s.id).inserted { context.insert(s.model) }
            var examIDs = Set(exams.map(\.id))
            for exam in backup.exams ?? [] where examIDs.insert(exam.id).inserted { context.insert(exam.model) }
            do { try context.save() } catch { context.rollback(); throw error }
            settings = backup.settings; settings.onboarded = true; refresh()
        } catch { self.error = L10n.tr("Backup non importato: %@" , String(describing: L10n.errorMessage(error))) }
    }
}

/// Uses macOS SQLite, including its WAL-aware backup API; no third-party dependency.
enum ColorIDMigrationBackup {
    @discardableResult static func create(archiveURL: URL, preferences: [String: Any]) throws -> URL {
        let stamp = Date().ISO8601Format().replacingOccurrences(of: ":", with: "-")
        let folder = archiveURL.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent("ColorIDs-\(stamp)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var source: OpaquePointer?
        var destination: OpaquePointer?
        guard sqlite3_open_v2(archiveURL.path, &source, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if let source { sqlite3_close(source) }
            throw CocoaError(.fileReadUnknown)
        }
        defer { sqlite3_close(source) }
        let copy = folder.appendingPathComponent("Study.store")
        guard sqlite3_open(copy.path, &destination) == SQLITE_OK else {
            if let destination { sqlite3_close(destination) }
            throw CocoaError(.fileWriteUnknown)
        }
        defer { sqlite3_close(destination) }
        guard let backup = sqlite3_backup_init(destination, "main", source, "main") else { throw CocoaError(.fileWriteUnknown) }
        var result = sqlite3_backup_step(backup, -1)
        for _ in 0..<20 where result == SQLITE_BUSY || result == SQLITE_LOCKED {
            Thread.sleep(forTimeInterval: 0.025)
            result = sqlite3_backup_step(backup, -1)
        }
        let finished = sqlite3_backup_finish(backup)
        guard result == SQLITE_DONE, finished == SQLITE_OK else { throw CocoaError(.fileWriteUnknown) }
        let data = try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
        try data.write(to: folder.appendingPathComponent("preferences.plist"), options: .atomic)
        return folder
    }
}
