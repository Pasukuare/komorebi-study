# Esami: materia e tipo di prova — build 23

Il modulo Nuovo esame non richiede più un nome libero: si sceglie una materia attiva e, facoltativamente, il tipo di prova. Scelte: Non specificato, Scritto, Orale, Progetto, Scritto e orale, Prova pratica, Altro. Altro consente una descrizione personale. Data, orario e Note/aula restano come prima. Senza materie attive non si può creare l’esame; il collegamento Aggiungi una materia chiude prima il modulo per consentire di usare la schermata Materie.

I nuovi esami mostrano il nome attuale della materia, seguito dal tipo se specificato: «Teoria dei Sistemi · Scritto e orale». La stessa risoluzione è usata in Calendario, Prossimi esami e countdown. Rimossa la ripetizione del nome della materia sulla riga sottostante quando coincide già con il titolo mostrato.

## Compatibilità e dati

Aggiunti solo due attributi opzionali a StudyExam: examKind (ID stabile, non tradotto) ed examKindDetail. I nuovi esami salvano anche una copia del nome della materia in title come fallback, utile se la materia venisse eliminata. Il collegamento per ID resta la fonte del nome visualizzato nei nuovi esami, anche dopo una rinomina.

Nessun titolo o nota preesistente viene riscritto automaticamente. I vecchi esami continuano a usare le regole precedenti finché non viene scelto un tipo o cambiata esplicitamente la materia. Il titolo originale diverso dal nome della materia resta visibile in sola lettura come «Titolo precedente», e viene comunque conservato nel record anche quando si cambia materia/tipo. Gli esami storici senza materia restano modificabili senza obbligare ad assegnarne una. Backup JSON include i campi opzionali e legge i vecchi record senza questi campi.

Backup personale prima di modificare lo schema, tramite SQLite read-only backup API e controllo integrità: `~/Library/Application Support/Komorebi Study/Backups/Pre-tipi-esame-20261024-104134`. Durante le prove non è stata eseguita migrazione sull’archivio personale. La nuova build crea un’ulteriore copia datata nella sottocartella Backups dell’archivio (prefisso ExamKinds) prima che ModelContainer aggiunga le colonne mancanti. Il controllo è idempotente: nessuna nuova copia se la lettura delle colonne già esistenti riesce. In caso di errore di lettura il controllo resta prudente e richiede una copia aggiuntiva.

## Verifiche

- Suite Release: 164 test, nessun errore, uno saltato per fixture facoltativa.
- Test: tipo e descrizione nei backup; aggiornamento del nome dalla materia senza riscrivere title; nomi in italiano/inglese; vecchi JSON senza tipo; vecchio schema SQLite reale di prova, backup prima della migrazione, ID/titolo/nota/data/orario conservati.
- Rendering nativo fuori schermo del modulo nei due temi e nelle due modalità, con dati fittizi. Non sono prove di click, tastiera o VoiceOver.
- Audit localizzazione: 477 voci inglesi, 350 chiavi letterali/plurali, superato.
- Build Xcode Release, firma ad hoc e integrità DMG verificate. Nessuna installazione/sostituzione in Applicazioni. Non notarizzata.

Nessuna modifica a timer, navigazione generale, dati di studio, colori o grafici. Nessuna nuova libreria, animazione continua o elaborazione al movimento del mouse.

## File modificati

- Sources/Models/Models.swift
- Sources/Services/StudyStore.swift
- Sources/Services/BackupService.swift
- Sources/Views/CalendarView.swift
- Sources/Views/RootView.swift
- Sources/ThemeResources/Translations.json
- Tests/ExamCountdownTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Tipi-esame-build23.md
- Docs/PASSAGGIO-PROGETTO.md
