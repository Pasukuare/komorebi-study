# Home: countdown al prossimo esame — build 19

In alto a destra nella Home, sopra «Serie: X giorni», compare il nome dell’esame più vicino e il conto in giorni: «Esame oggi», «Esame domani», «Esame tra N giorni». Rimossa la piccola foglia accanto alla serie indicata nello screenshot; marchio e logo della sidebar restano invariati. La serie mantiene il precedente comportamento (visibile se maggiore di zero).

La scelta usa gli esami già salvati nel Calendario, ordinati per data, con spareggio deterministico tramite UUID. Gli esami di giorni precedenti sono esclusi. Come nella card Prossimi esami, un esame resta corrente per tutta la sua giornata, anche se ha un orario già passato: la richiesta viene interpretata come countdown in giorni, non come timer orario. Se non esistono esami correnti/futuri non viene aggiunto alcun messaggio.

Il calcolo usa inizio giornata e componenti del calendario locale, non divisioni per 86400 secondi, evitando errori al cambio dell’ora. L’aggiornamento a mezzanotte usa il meccanismo di cambio giornata già esistente nello store. Nessun nuovo timer, animazione, navigazione o scrittura sui dati. Non vengono cambiati la card Prossimi esami, il Calendario o i filtri esistenti.

Nome dell’esame su due righe, tooltip con nome completo e data, testo accessibile combinato; token tipografici e colori dei temi esistenti. Frasi di countdown localizzate in italiano/inglese; nomi degli esami invariati.

## Verifiche

Suite SwiftPM Release: 144 test, nessun errore, uno saltato (fixture opzionale di migrazione). Audit localizzazione superato: 445 voci inglesi, 321 chiavi letterali/plurali; test dedicati di selezione esame più vicino con lista non ordinata, assenza esami, soli esami passati, esame odierno/domani, cambi ora legale/solare, spareggio stabile e localizzazione. Rendering fuori schermo del riepilogo con nome lungo, serie presente/assente, italiano/inglese e Komorebi/Halloween chiaro/scuro. Build Xcode Release, firma locale e integrità DMG.

Nessun archivio personale utilizzato. Non eseguiti click nativi, screenshot reali o attesa reale del cambio di giornata: la mezzanotte è verificata mediante date di prova. Sul Mac controllare la Home con un esame oggi/domani/futuro, modificare o eliminare il prossimo esame dal Calendario e confermare il nuovo countdown, quindi restringere la finestra e provare entrambi i temi/lingue.

## File modificati

- Sources/Views/RootView.swift
- Sources/ThemeResources/Translations.json
- Tests/ExamCountdownTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Countdown-esame-build19.md
- Docs/PASSAGGIO-PROGETTO.md

Build separata 1.8 (19), firma ad hoc senza notarizzazione. App in Applicazioni non sostituita.
