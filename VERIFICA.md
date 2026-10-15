# Verifica della consegna

Eseguita l'8 settembre 2026 su Apple Silicon, macOS 26.6.2, con Xcode e Swift 6.3.3. Deployment target dell'app: macOS 15.0.

- Build Release del progetto Xcode: riuscita.
- 10 test XCTest: tutti superati, nessun errore.
- Firma ad hoc dell'app: verificata con controllo strict.
- Apertura reale dell'app: verificata dopo correzione di un crash iniziale nell'accesso prematuro al Dock.
- Onboarding, Home e layout: ispezionati sullo schermo.
- Cronometro: avvio, avanzamento e pausa verificati dall'interfaccia.
- Chiusura completa e riapertura: la sessione è stata recuperata con lo stesso tempo e ancora in pausa.
- Stop, persistenza della sessione e nota: verificati nell'interfaccia.
- Ricerca della nota, grafici e calendario: verificati con il record di prova.
- Ultima app Release riaperta correttamente.

I test coprono tick persi, superamento della scadenza, pause multiple, pausa idempotente, cronometro lungo, date antecedenti all'inizio, serializzazione del timer, completamento senza conteggio delle pause, durata limitata del Pomodoro scaduto, distribuzione a mezzanotte e backup con note multilinea.

Non verificati con prove fisiche dedicate: sleep prolungato del Mac, consegna di notifiche autorizzate, riproduzione audio ascoltata, macOS 15, audit completo VoiceOver e notarizzazione. L'assenza di errori di compilazione non sostituisce questi collaudi.
