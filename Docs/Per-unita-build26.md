# Modalità Per unità — build 26

## Compito 1 — censimento, prima delle modifiche

| Punto | File e simbolo | Dati / comportamento attuale |
| --- | --- | --- |
| «Lezione 3 terminata» | Sources/Views/RootView.swift, CompletionView; Sources/Views/CalendarView.swift, SessionRow | Testo libero `StudySession.note`, scritto nel riepilogo dopo una sessione o in Cronologia. Nessun modello lezione, indice o stato. Collegamento alla materia tramite subjectID; subjectName è lo snapshot storico. Non estrarre unità dalle note esistenti. |
| Modalità | Sources/Models/Models.swift, TimerMode; Sources/Services/StudyStore.swift, preparedTarget/start/toggle/finish | Pomodoro countdown + pause brevi/lunghe; Cronometro avanti senza limite; Personalizzato countdown + pausa opzionale. ActiveTimer conserva intervalli misurati, pause e recupero in UserDefaults. |
| Salvataggio | Sources/Services/StudyStore.swift, finish/save/refresh; Sources/Models/Models.swift, StudySession | SwiftData: UUID, inizio/fine, durata netta, pause, materia, modalità, nota, activityData. Riutilizzare questi intervalli per calendario e proiezione, senza conteggiare le pause come studio. |
| Materie | Sources/Models/Models.swift, Subject; Sources/Views/SubjectsView.swift, SubjectsView/SubjectEditor | SwiftData. Le modifiche passano da context/save, che aggiorna cataloghi e riepiloghi condivisi. Nessuna pagina di dettaglio separata: unità nella card della materia, senza nuova navigazione. |
| Home e Focus | Sources/Views/RootView.swift, OverviewView/TimerSetup/SessionControls/TimerFace | Overview riusa SessionRow per Ultime sessioni; Timer e Focus condividono store e controlli. |
| Cronologia | Sources/Views/HistoryView.swift, HistoryView/HistorySessionRow/SessionEditor | Legge store.sessions; filtro modalità da TimerMode, modifica metadati e durata. |
| Calendario | Sources/Views/CalendarView.swift, CalendarView/SessionRow | Legge sessioni tramite store; stesso componente SessionRow, conteggio giornaliero da intervalli. |
| Statistiche e Proiezione | Sources/Views/StatisticsView.swift, StatisticsView/ProjectionCard | Swift Charts e aggregazioni store; integrare dati unità dalla cache, mantenendo conteggi temporali esistenti. |
| Backup | Sources/Services/BackupService.swift, Backup/SessionRecord/export/restore | JSON versione 1 con campi opzionali retrocompatibili e CSV. Aggiungere unità senza perdere backup precedenti. |

Nessun codice modificato nel Compito 1. Nessuna nota personale trasformata in unità.
