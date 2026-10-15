import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        Form {
            Section("Obiettivi") {
                GoalEditButton()
                number("Obiettivo giornaliero (ore)", value: $store.settings.dailyGoal, range: 0.25...24)
                number("Obiettivo settimanale (ore)", value: $store.settings.weeklyGoal, range: 0.25...168)
                Toggle("Per la serie, richiedi l’obiettivo giornaliero", isOn: $store.settings.streakUsesGoal)
                if !store.settings.streakUsesGoal { number("Minuti per completare un giorno", value: $store.settings.streakMinutes, range: 1...1440) }
            }
            Section("Pomodoro") {
                number("Studio (minuti)", value: $store.settings.pomodoroDuration, range: 1...600)
                number("Pausa breve (minuti)", value: $store.settings.shortBreakDuration, range: 1...120)
                number("Pausa lunga (minuti)", value: $store.settings.longBreakDuration, range: 1...180)
                Stepper("Pausa lunga ogni \(store.settings.longBreakEvery) sessioni", value: $store.settings.longBreakEvery, in: 1...12)
                Text("Le modifiche si applicano al prossimo timer. Le pause iniziano con Riprendi; lo studio successivo parte con Avvia.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Il tuo ambiente") {
                Picker("Tema", selection: $store.settings.theme) { ForEach(["Morning", "Forest", "Rain", "Sunset", "Night"], id: \.self) { Text($0) } }
                Picker("Aspetto", selection: $store.settings.appearance) { Text("Sistema").tag("System"); Text("Chiaro").tag("Light"); Text("Scuro").tag("Dark") }
                Picker("Animazioni", selection: $store.settings.animations) { ForEach(["Off", "Reduced", "Full"], id: \.self) { Text($0) } }
                AmbientControls(audio: store.audio)
                Text("Paesaggio originale disegnato con forme native. Nessuna risorsa esterna.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Notifiche") {
                Toggle("Notifiche native", isOn: Binding(get: { store.settings.notifications }, set: { on in if on { store.requestNotifications() } else { store.settings.notifications = false; store.scheduleNotification() } }))
                Toggle("Suono di fine timer", isOn: $store.settings.sounds).onChange(of: store.settings.sounds) { store.scheduleNotification() }
            }
            Section("Dati e privacy") {
                Text("Tutto rimane su questo Mac. Nessun account, pubblicità o servizio di analisi.")
                HStack { Button("Esporta CSV") { store.export(csv: true) }; Button("Backup JSON") { store.export(csv: false) }; Button("Importa backup") { store.restore() }.disabled(store.active != nil) }
                Text("L’importazione aggiunge i record mancanti senza cancellare quelli esistenti. Il backup include materie, sessioni e impostazioni; termina prima il timer attivo.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Tastiera") { Text("Spazio · avvia / pausa / riprendi\n⌘ Invio · avvia sessione\n⌘ . · termina e salva").lineSpacing(6) }
            Section("Komorebi Study · 1.1") { Text("Il tempo trascorso durante lo sleep conta come studio se il timer non è in pausa. Puoi correggere una sessione nella Cronologia. Le sessioni a cavallo della mezzanotte sono distribuite proporzionalmente tra i giorni.").font(.caption).foregroundStyle(.secondary) }
        }.formStyle(.grouped).padding(12)
    }
    func number(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack { Text(title); Spacer(); TextField(title, value: value, format: .number).labelsHidden().frame(width: 75).onSubmit { value.wrappedValue = value.wrappedValue.isFinite ? min(range.upperBound, max(range.lowerBound, value.wrappedValue)) : range.lowerBound } }
    }
}

struct GoalEditButton: View {
    @State private var showing = false
    var body: some View {
        Button("Modifica obiettivi", systemImage: "pencil") { showing = true }
            .sheet(isPresented: $showing) { GoalEditor() }
    }
}
struct GoalEditor: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss
    @State private var daily = 3.0
    @State private var weekly = 15.0
    var valid: Bool { daily.isFinite && weekly.isFinite && (0.25...24).contains(daily) && (0.25...168).contains(weekly) }
    var body: some View {
        Form {
            Text("Obiettivi di studio").font(.title2)
            TextField("Ore al giorno", value: $daily, format: .number)
            TextField("Ore alla settimana", value: $weekly, format: .number)
            Text("Puoi usare valori decimali, per esempio 2,5 ore. I nuovi obiettivi si applicano ai progressi correnti.").font(.caption).foregroundStyle(.secondary)
            if !valid { Text("Giornaliero: da 0,25 a 24 ore. Settimanale: da 0,25 a 168 ore.").foregroundStyle(.red).font(.caption) }
            HStack { Button("Annulla") { dismiss() }; Spacer(); Button("Salva") { store.settings.dailyGoal = daily; store.settings.weeklyGoal = weekly; dismiss() }.buttonStyle(.borderedProminent).disabled(!valid) }
        }.padding(28).frame(width: 420).onAppear { daily = store.settings.dailyGoal; weekly = store.settings.weeklyGoal }
    }
}
