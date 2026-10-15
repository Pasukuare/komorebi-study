import SwiftUI
struct SubjectsView: View {
    @EnvironmentObject var store: StudyStore
    @State private var name = ""
    @State private var icon = "book.closed"
    @State private var color = "Salvia"
    @State private var goal = 5.0
    @State private var editing: Subject?
    @State private var deleting: Subject?
    func subjectMetric(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(durationText(value)).font(.system(size: 23, weight: .medium, design: .rounded)).monospacedDigit() }.frame(maxWidth: .infinity, alignment: .leading)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Materie").font(.system(size: 30, design: .serif))
                Card {
                    Text(editing == nil ? "Una nuova materia" : "Modifica materia").font(.headline)
                    HStack { TextField("Nome della materia o progetto", text: $name).textFieldStyle(.roundedBorder); Picker("Icona", selection: $icon) { ForEach(["book.closed", "leaf", "laptopcomputer", "pencil", "function", "globe", "brain"], id: \.self) { Image(systemName: $0).tag($0) } }.frame(width: 140) }
                    HStack { Picker("Colore", selection: $color) { ForEach(["Salvia", "Cielo", "Tramonto", "Lavanda", "Terra"], id: \.self) { Text($0) } }; TextField("Ore / settimana", value: $goal, format: .number).frame(width: 70); Text("ore / settimana") }
                    HStack {
                        if editing != nil { Button("Annulla") { editing = nil; name = "" } }
                        Button(editing == nil ? "Aggiungi materia" : "Salva modifiche") {
                            let validGoal = goal.isFinite && goal >= 0 ? min(168, goal) : 5.0
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let editing { editing.name = trimmedName; editing.icon = icon; editing.color = color; editing.weeklyGoal = validGoal }
                            else { store.context.insert(Subject(name: trimmedName, icon: icon, color: color, weeklyGoal: validGoal)) }
                            if store.save() { name = ""; editing = nil }
                        }.buttonStyle(.borderedProminent).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                ForEach(store.subjects) { s in
                    Card {
                        HStack { Label(s.name, systemImage: s.icon).font(.title3).foregroundStyle(Color.subject(s.color)); Spacer(); Button("Modifica") { editing = s; name = s.name; icon = s.icon; color = s.color; goal = s.weeklyGoal }; Button("Elimina", role: .destructive) { deleting = s }.disabled(store.active?.subjectID == s.id) }
                        HStack(spacing: 24) {
                            subjectMetric("Settimana", value: store.total(in: store.week, subject: s.id))
                            let monthInterval = Calendar.current.dateInterval(of: .month, for: store.now) ?? DateInterval(start: store.now, end: store.now)
                            subjectMetric("Mese", value: store.total(in: monthInterval, subject: s.id))
                            subjectMetric("Sempre", value: store.sessions.filter { $0.subjectID == s.id }.reduce(0) { $0 + $1.duration })
                        }
                        Text("\(store.sessions.filter { $0.subjectID == s.id }.count) sessioni salvate").font(.caption).foregroundStyle(.secondary)
                        GoalBar(title: "Obiettivo settimanale", value: store.total(in: store.week, subject: s.id), goal: s.weeklyGoal * 3600)
                    }
                }
            }.padding(30)
        }.alert("Eliminare la materia?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) { Button("Annulla", role: .cancel) {}; Button("Elimina", role: .destructive) { if let deleting { if store.settings.lastSubject == deleting.id { store.settings.lastSubject = nil }; store.context.delete(deleting); store.save() }; deleting = nil } } message: { Text("Le sessioni passate e il loro nome verranno conservati.") }
    }
}
