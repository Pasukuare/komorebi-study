# Nomi degli esami coerenti con la materia — build 22

Gli screenshot mostrano due valori distinti: titolo dell’esame «Teoria Dei Sistemi», nome della materia collegata «Teoria dei Sistemi». Il precedente intervento rendeva letterali i testi ma non risolveva questa differenza: continuava a mostrare correttamente il titolo originale dell’esame, diverso dal nome della materia.

## Regola condivisa

StudyExam.displayTitle(linkedSubjectName:) usa il nome esatto della materia collegata quando il titolo dell’esame è identico salvo maiuscole/minuscole. Store.examDisplayTitle risolve il collegamento tramite lookup già in cache. ExamRow (Prossimi esami e Calendario) e il countdown Home usano la stessa funzione.

- Materia «Teoria dei Sistemi», esame «Teoria Dei Sistemi» → mostra «Teoria dei Sistemi».
- Titolo «Parziale di Teoria Dei Sistemi» → resta tale.
- Esame senza materia o con collegamento mancante → conserva il titolo originale.
- Differenze di accenti, parole o punteggiatura non vengono normalizzate.

È solo visualizzazione: nessuna migrazione, nessun cambio al titolo salvato, nessuna rinomina delle materie/sessioni. L’editor dell’esame conserva il titolo originale memorizzato, per consentire di modificarlo esplicitamente. Calendario, date, countdown, logica del timer e navigazione restano invariati. Nessuna animazione o scansione delle materie aggiunta al movimento del mouse.

## Verifica

Suite SwiftPM Release: 161 test, nessun errore, uno saltato (fixture opzionale); test del caso esatto degli screenshot, aggiornamento della grafia della materia, countdown, conservazione del titolo salvato, titoli personalizzati, esami non collegati e accenti distinti. Build Xcode Release separata, firma ad hoc e DMG verificati. Nessuna prova manuale/native click eseguita e nessun archivio personale utilizzato. App in Applicazioni non sostituita; nessuna notarizzazione Apple.

## File modificati

- Sources/Models/Models.swift
- Sources/Services/StudyStore.swift
- Sources/Views/RootView.swift
- Sources/Views/CalendarView.swift
- Tests/ExamCountdownTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Nomi-esami-build22.md
- Docs/PASSAGGIO-PROGETTO.md
