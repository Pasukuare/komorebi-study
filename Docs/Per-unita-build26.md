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

## Compito 2 — dati e regole

StudyUnit è una nuova entità SwiftData, collegata via UUID alla materia senza cancellazioni a cascata. Sessioni e ActiveTimer aggiungono solo campi opzionali (unitID, titolo storico e stato finale; stima snapshot nell’attivo). Backup JSON include unità opzionali e conserva collegamenti e snapshot; i backup precedenti rimangono leggibili. Backup SQLite WAL-aware `Backups/StudyUnits-<data>-<UUID>` prima dell’apertura del vecchio schema. Una migrazione sintetica dal vero schema privo delle colonne unità verifica integrità delle note e durate e idempotenza. Nessun archivio personale migrato durante le prove.

Generazione numerica e per pagine pura, con massimo 10.000 elementi per operazione per evitare allocazioni accidentali. Ultimo blocco pagine accorciato al resto. Mediana per materia/tipo solo con almeno tre unità finite con tempo positivo; per pagine mediana dei minuti/pagina. Stima esplicita facoltativa prevale sulla proposta automatica. Mediane calcolate una volta per gruppo, riepiloghi in cache aggiornati da save/refresh, non dai tick o dal cursore.

Default delle pause **proposti dall’utente**: frazione 1/5, minimo 5 minuti, massimo 20. La pausa usa il tempo dell’ultima tratta effettivamente studiata, così una ripresa non propone di nuovo pause per tempi già salvati. L’unità ha una sola sessione cumulativa, con intervalli delle tratte separati; i giorni senza studio non diventano tempo studiato. Finita a tempo zero modifica lo stato senza inventare una sessione. Eliminare l’unità conserva UUID e titolo nella sessione. Modificare o eliminare l’unità non interrompe il timer attivo: usa lo snapshot acquisito all’avvio.

Verifica Compito 2: suite Release 179 test, uno saltato, zero errori; poi 5 test mirati unità/migrazione superati. I fixture di migrazione dei vecchi test isolano il proprio cambiamento includendo la nuova tabella vuota. Nuovi test: 20 lezioni, 7 blocchi pagine (ultimo 91–100), pause 8/5/20 minuti, mediana con soglia 3, salvataggio cumulativo/ripresa/eliminazione, preferenze legacy e migrazione SQLite protetta. Nessuna prova manuale dell’interfaccia.

## Compito 3 — gestione nella materia

Sezione apribile nella card, chiusa inizialmente per preservare ingombri delle card esistenti. Le materie completate conservano la consultazione delle proprie unità. Elenco con titolo, tipo/stato, tempo cumulativo e stima, comandi modifica/sposta su/sposta giù/elimina con conferma. Nuova unità e modifica condividono StudyUnitDraft e lo stesso editor: Annulla non applica modifiche; Invio salva solo con titolo/pagine/stima validi. Creazione multipla con tipo, prefisso, estremi e blocco pagine, anteprima primo/ultimo titolo e conteggio. Nessuna animazione persistente o effetto dipendente dal mouse aggiunto.

7 test mirati superati: inclusi validazione modulo, riordino e rendering nativo fuori schermo di elenco, editor e creazione multipla nelle quattro combinazioni Komorebi/Halloween e chiaro/scuro. Catture in Anteprime della consegna. Audit traduzioni superato: 551 voci inglesi. Non sono prove di click, Tab o VoiceOver reali.
