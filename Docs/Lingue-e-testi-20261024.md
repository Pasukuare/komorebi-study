# Lingue e testi — 24 ottobre 2026

## Comportamento

- Rimossi i testi motivazionali: sottotitoli di Home/Timer, formule incoraggianti nelle card, frasi dei vuoti, onboarding e variazioni narrative Halloween. Restano azioni, istruzioni operative, informazioni sul tempo e sulla privacy. La serie resta un dato numerico con etichetta neutra.
- Impostazioni → Lingua → Italiano / English. Italiano resta il valore per gli archivi precedenti. La scelta è salvata come proprietà opzionale di UserSettings per compatibilità con le preferenze già esistenti; non richiede migrazioni SwiftData.
- Interfaccia, controlli, tooltip, etichette VoiceOver, menu dell'app, conferme, errori applicativi, notifiche e testi dei selettori usano un catalogo centrale. Anche date, giorni della settimana e grafici seguono il locale scelto. I nomi delle materie e le note non vengono tradotti.
- La lingua delle viste cambia subito senza ricreare l'albero delle sezioni o riavviare il timer. I menu AppKit vengono aggiornati mantenendo azioni e scorciatoie. La preferenza AppleLanguages dell'app e CFBundleLocalizations dichiarano Italiano/Inglese; alcuni pannelli nativi macOS richiedono la riapertura dell'app, come indicato nelle Impostazioni.
- Rimossa l'opzione Testi a tema, che serviva alle frasi narrative ora eliminate. I valori precedenti non vengono cancellati: non riattivano messaggi motivazionali. Decorazioni, marchi, colori e temi restano disponibili.

## Architettura

`AppLanguage` e `L10n` sono in Models.swift. Il catalogo `Sources/ThemeResources/Translations.json` è caricato una sola volta. AppLocalization pubblica solo cambi di lingua espliciti: i componenti che costruiscono stringhe tradotte si aggiornano anche se tema e binding restano uguali, senza smontare le viste. Un test NSHostingView verifica il cambio live e la conservazione di State. L'italiano è la chiave di origine, l'inglese la traduzione; i parametri delle frasi sono separati dalla chiave. Le etichette dinamiche dei pacchetti tema, palette e icone vengono risolte al momento della visualizzazione, senza tradurre gli ID stabili.

Non tradurre i rawValue persistiti di TimerMode, gli ID dei colori, i nomi interni degli ambienti, le chiavi JSON o i nomi delle materie. Per TimerMode usare displayName nell'interfaccia. Per dati scritti dall'utente usare il testo originale, senza passarlo a L10n.

Le descrizioni degli errori di sistema in inglese usano messaggi applicativi con dominio/codice diagnostico; il dettaglio tecnico di macOS non viene presentato come una traduzione inglese se segue la lingua del sistema. Le strutture di backup e CSV mantengono i valori dati già esistenti.

## Verifiche eseguite

- `swift test`: **118 test, uno saltato, zero errori**. Il test opzionale di migrazione non dispone di fixture.
- Nuovi test: lettura preferenze senza language, fallback di valori sconosciuti; salvataggio lingua; ActiveTimer serializzato invariato; note, nome materia, colore e modalità registrata invariati; copertura di pagine, modalità e metadati dei selettori; plurali e locale; errori; menu con azioni/shortcut conservati; frasi neutre anche con vecchie opzioni Halloween; render inglesi delle otto viste principali/menu nei due temi e nelle due modalità.
- `python3 Scripts/audit-localization.py`: 425 voci inglesi; 301 chiavi letterali/plurali controllate; segnaposto coerenti. Le chiavi dinamiche dei metadati sono coperte dalla suite.
- Build **Xcode Release riuscita**, comprendente font, nuova icona e Translations.json. L'avviso del supporto iOS Simulator non aggiornato non ha impedito la compilazione macOS.

I render ImageRenderer non costituiscono un collaudo di click, tastiera o assenza di overflow in una finestra reale. I log possono contenere avvisi FocusState dovuti al rendering fuori da un host interattivo. Non sono state eseguite nuove misure di watt, CPU o fluidità. Le verifiche visive dei bug precedenti di Statistiche/popover restano aperte.

## Prova manuale residua

Usare una copia preview con archivio separato: cambiare Italiano → English → Italiano mantenendo una sessione in corso o in pausa e un filtro aperto. Verificare tutte le sezioni, Focus, riepilogo, menu bar, alert e VoiceOver; controllare il layout alle larghezze supportate e i testi più lunghi. Chiudere e riaprire un ambiente persistente separato per confermare la lingua e i pannelli nativi. La preview in memoria non è una prova di persistenza tra avvii.

## Consegna

Build 13, Release, firma locale ad hoc, non notarizzata. DMG separato: `Dist/Komorebi-Study-Lingue-20261024.dmg`. Nessuna sostituzione in Applicazioni. File modificati e sorgenti correnti sono allegati alla cartella di consegna; il documento di passaggio è aggiornato alla nuova build.
