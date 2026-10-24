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

## Compito 4 — sessione Per unità

Modalità aggiunta al selettore condiviso in Timer/menu e al segmented della Home. Materie dalla sorgente attive esistente; scelta predefinita prima unità non finita in ordine, senza avvio automatico. Nessuna unità: stato vuoto, avvio disabilitato con motivo e collegamento a Materie. Non è stata aggiunta una nuova pagina.

Cronometro in avanti senza target. Titolo e stima copiati nell’attivo per non interrompere o cambiare il timer quando l’unità viene modificata/eliminata. Indicatore entro/oltre la stima in testo secondario, aggiornato nella sola vista temporale. Pausa/riprendi condivisi. Finita salva e marca finita; Non ancora finita salva e mantiene in corso. Entrambi disponibili anche nei controlli Focus e menu. Finita propone un countdown di pausa fermo, da avviare o saltare esplicitamente; la prossima unità è visibile e modificabile. Dopo la pausa il successivo avvio rimane manuale. Impostazioni aggiunge frazione/minimo/massimo editabili tramite stepper custom.

Verifiche: suite Release 182 test, uno saltato, zero errori prima delle ultime verifiche; 9 test mirati finali superati, inclusi avvio senza unità, esclusione materia completata, modifica unità e completamento materia a timer attivo, salvataggio della sessione, regole impostazioni e round-trip dell’attivo. Rendering nativo fuori schermo anche di Home e configurazione Timer nelle quattro modalità; nessuna prova manuale del countdown, Focus o menu di sistema.

## Compito 5 — integrazione e consegna

SessionRow, condiviso tra Home, Cronologia e Calendario, mostra titolo/stato delle nuove unità e conserva eventuali note separate. Le sessioni legacy senza unità seguono esattamente il ramo precedente: «Lezione 3 terminata» rimane la nota originale, non viene convertita né duplicata. La ricerca Cronologia include il titolo dell’unità. La materia di una nuova sessione collegata a un’unità non è riassegnabile dal vecchio editor sessioni: si preserva il legame e il motivo è visibile; durata, date e note restano modificabili.

Statistiche aggiunge avanzamento per materia e media sulle unità finite con tempo registrato. I conteggi sono complessivi, indipendenti dal periodo del grafico; la didascalia lo esplicita. Le materie completate rimangono consultabili. Proiezione aggiunge conteggio e ore residue solo quando tutte le unità non finite della materia hanno una stima automatica supportata da tre esempi; la sola stima manuale non finge evidenza statistica. Si sottrae il tempo già salvato sulle unità in corso, con minimo zero. Unità e stime sono per materia, non assegnate arbitrariamente a uno specifico esame.

La ripresa unisce gli intervalli misurati anche quando una tratta recuperata viene salvata nuovamente: nessun doppio conteggio e il lavoro successivo rimane incluso. Il collegamento Aggiungi unità dello stato vuoto apre direttamente il modulo, evitando una navigazione verso una sezione chiusa.

### Verifiche

| Controllo | Esito |
| --- | --- |
| Suite automatica Release finale | 188 test eseguiti, uno saltato, zero errori |
| Generazione lezioni 1–20 | 20 unità |
| Generazione pagine 1–100 a blocchi da 15 | 7 unità; ultimo blocco 91–100 |
| Pause 40/10/150 minuti | 8/5/20 minuti, rispettivamente |
| Stime con due esempi | Nessuna proposta automatica |
| Tre esempi della stessa materia/tipo | Mediana corretta, separata tra lezioni e pagine e tra materie |
| Stima pagine | Mediana minuti/pagina moltiplicata per le pagine della nuova unità |
| Ripresa / salvataggio cumulativo | Una sola sessione; tempi sommati, intervalli e note conservati |
| Recupero della stessa tratta | Secondo salvataggio non duplica il tempo; eventuale lavoro aggiuntivo incluso |
| Pause e ripresa su giorni diversi | Attribuzione ai giorni verificata; interruzioni escluse |
| Eliminazione unità con sessioni | Sessioni, tempo e titolo storico conservati |
| Avvio senza unità, tutte finite, riapertura | Stato vuoto e canStart aggiornati; prima non finita riproposta senza avvio |
| Materia completata / modifica unità mentre attiva | Esclusa dai nuovi avvii; attivo continua e salva |
| Cache | 1.000 letture di conteggi/stime senza ricostruzioni; tick esclusi |
| Migrazione dal vecchio schema | Backup pre-schema verificato, nessuna alterazione delle sessioni legacy, secondo avvio idempotente |
| Persistenza e backup | Round-trip unità/sessione attiva; backup JSON esteso con campi opzionali |
| Temi e rendering | Catture native fuori schermo Komorebi/Halloween, chiaro/scuro, animazioni Off |
| Localizzazione | Audit superato: 569 voci inglesi e 441 chiavi letterali/plurali |
| Build separata | Xcode Release 26; firma locale e checksum DMG verificati |

Il test saltato richiede un archivio reale opzionale, non utilizzato per proteggere i dati personali. Le prove della migrazione sintetica sono state eseguite. Avvisi già presenti: anchor personalizzato del vecchio grafico Statistiche e FocusState nei renderer fuori schermo; non sono una verifica del focus reale.

### Immagini e limiti

Anteprime contiene elenco, editor, creazione multipla, Home, Timer, pausa, Cronologia, Statistiche, Proiezione e stato tutte finite nei quattro abbinamenti tema/modalità. Sono immagini renderizzate automaticamente con archivi temporanei/in memoria, non schermate ottenute con click reali. Prima contiene le catture storiche build 24 come riferimento prima della modalità unità; i dati sintetici e le altezze di cattura differiscono, quindi il confronto non è una regressione pixel per pixel.

Non eseguiti: click e riordino con mouse reali, Tab/Invio/Esc fisici, VoiceOver, ingresso/uscita Focus reali, menu di sistema, misure CPU/energia/FPS, test prolungato di memoria, finestra minima reale. Nessun valore prestazionale promesso. Per il collaudo manuale usare una copia isolata dell’archivio o dati di test: creare lezioni e pagine, interrompere/riprendere, finire, avviare/saltare pausa e cambiare unità; provare anche senza unità e con tutte finite, i quattro temi e Riduci movimento. L’app normale della consegna usa l’archivio personale solo quando viene avviata dall’utente; non è stata lanciata durante il lavoro.

### File modificati

- Sources/Models/Models.swift: entità, campi opzionali, generatori, pausa, mediana e unione intervalli.
- Sources/Services/StudyStore.swift: modalità, sessione cumulativa, cache e riepiloghi.
- Sources/Services/BackupService.swift: backup JSON e backup SQLite pre-schema.
- Sources/Views/SubjectsView.swift: elenco, editor condiviso, creazione multipla, riordino.
- Sources/Views/RootView.swift: Home, Timer, Focus e selettori/controlli condivisi.
- Sources/Views/SettingsView.swift: regole pausa.
- Sources/Views/CalendarView.swift: SessionRow condiviso.
- Sources/Views/HistoryView.swift: ricerca unità e protezione del legame alla materia.
- Sources/Views/StatisticsView.swift: avanzamento unità e riga Proiezione.
- Sources/ThemeResources/Translations.json: italiano/inglese.
- Tests/StudyUnitTests.swift: nuovi test unitari, integrazione, migrazione e rendering.
- Tests/CompletedSubjectsTests.swift, Tests/MigrationTests.swift: fixture delle migrazioni precedenti aggiornati con tabella unità vuota.
- Komorebi Study.xcodeproj/project.pbxproj: build 26.
- Docs/Per-unita-build26.md, Docs/PASSAGGIO-PROGETTO.md: censimento e passaggio progetto.

Un commit per compito: 1 `8574332`, 2 `bc7e9a3`, 3 `1d47b57`, 4 `2dc6b4e`; hash del Compito 5 nel file COMMIT.txt della consegna. Nessuna riscrittura della cronologia. Applicazioni non modificata; nessuna migrazione personale eseguita nelle prove.
