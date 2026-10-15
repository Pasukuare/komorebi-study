import Foundation
import AppKit
import UniformTypeIdentifiers

struct SessionRecord: Codable {
    var id: UUID; var start: Date; var end: Date; var duration: Double; var subjectID: UUID?; var subject: String; var mode: String; var pause: Double; var note: String
    init(_ s: StudySession) { id = s.id; start = s.startDate; end = s.endDate; duration = s.duration; subjectID = s.subjectID; subject = s.subjectName; mode = s.timerMode; pause = s.pauseDuration; note = s.note }
    var model: StudySession { StudySession(id: id, start: start, end: end, duration: duration, subjectID: subjectID, subjectName: subject, mode: mode, pause: pause, note: note) }
}
struct SubjectRecord: Codable {
    var id: UUID; var name: String; var icon: String; var color: String; var weeklyGoal: Double
    init(_ s: Subject) { id = s.id; name = s.name; icon = s.icon; color = s.color; weeklyGoal = s.weeklyGoal }
}
struct Backup: Codable { var version = 1; var settings: UserSettings; var subjects: [SubjectRecord]; var sessions: [SessionRecord]; var exams: [ExamRecord]? = nil }
@MainActor extension StudyStore {
    func export(csv: Bool) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = csv ? "Komorebi-sessioni.csv" : "Komorebi-backup.json"; panel.allowedContentTypes = [csv ? .commaSeparatedText : .json]
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
        } catch { self.error = error.localizedDescription }
    }
    func restore() {
        guard active == nil else { error = "Termina la sessione prima di importare un backup."; return }
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(Backup.self, from: Data(contentsOf: url))
            guard backup.version == 1, (backup.exams ?? []).allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }), backup.sessions.allSatisfy({ $0.duration.isFinite && $0.pause.isFinite && $0.duration >= 0 && $0.pause >= 0 && $0.end >= $0.start && $0.duration + $0.pause <= $0.end.timeIntervalSince($0.start) + 2 }), backup.subjects.allSatisfy({ !$0.name.isEmpty && $0.weeklyGoal.isFinite && $0.weeklyGoal >= 0 }), backup.settings.dailyGoal > 0, backup.settings.weeklyGoal > 0 else { throw CocoaError(.fileReadCorruptFile) }
            let alert = NSAlert(); alert.messageText = "Importa backup locale"; alert.informativeText = "Verranno aggiunte le sessioni e le materie mancanti. I dati esistenti saranno conservati. Le impostazioni verranno aggiornate."; alert.addButton(withTitle: "Importa"); alert.addButton(withTitle: "Annulla")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            var subjectIDs = Set(subjects.map(\.id)); var sessionIDs = Set(sessions.map(\.id))
            for s in backup.subjects where subjectIDs.insert(s.id).inserted {
                let model = Subject(name: s.name, icon: s.icon, color: s.color, weeklyGoal: s.weeklyGoal); model.id = s.id; context.insert(model)
            }
            for s in backup.sessions where sessionIDs.insert(s.id).inserted { context.insert(s.model) }
            var examIDs = Set(exams.map(\.id))
            for exam in backup.exams ?? [] where examIDs.insert(exam.id).inserted { context.insert(exam.model) }
            do { try context.save() } catch { context.rollback(); throw error }
            settings = backup.settings; settings.onboarded = true; refresh()
        } catch { self.error = "Backup non importato: \(error.localizedDescription)" }
    }
}
