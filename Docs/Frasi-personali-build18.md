# Frasi personali — build 18

Impostazioni → Frasi personali consente di scrivere quattro messaggi indipendenti:

- Home: sotto il titolo Riepilogo.
- Timer: sotto il titolo della schermata, fuori dai controlli funzionali.
- Obiettivo di oggi: sotto il dato sul tempo rimanente/raggiungimento.
- Barra dei menu: nel pannello senza timer attivo, nello spazio del vecchio saluto.

I campi sono facoltativi. Se vuoti o composti soltanto da spazi, non viene mostrata alcuna frase aggiuntiva. Restano titoli, stati del timer, dati numerici e indicazioni operative. Non sono reintrodotte frasi motivazionali predefinite, rotazioni casuali, notifiche o animazioni.

Le frasi sono testo utente: niente traduzione automatica né interpretazione Markdown. Sono condivise fra tutti i temi e le lingue. Si possono modificare e cancellare singolarmente. La visualizzazione è limitata a tre righe per non spostare fuori finestra i controlli; tooltip ed etichetta accessibile contengono il testo completo.

## Persistenza

Il dizionario opzionale `UserSettings.personalPhrases` usa le chiavi stabili home/timer/dailyGoal/menu. Gli archivi di preferenze precedenti continuano a decodificarsi senza questa proprietà. Backup JSON e importazione la includono attraverso UserSettings; nessuna modifica allo schema SwiftData, alle materie, ai voti o alle sessioni.

Gli editor mantengono una bozza e accorpano la scrittura dopo 450 ms di inattività. La bozza viene salvata anche uscendo dalle Impostazioni, alla disattivazione, allo smontaggio e alla notifica di terminazione. Non si rischedulano così le notifiche del timer per ogni carattere. Il feedback Salvato esistente segue l’effettivo aggiornamento delle preferenze.

## Verifiche

Suite SwiftPM Release: 140 test, nessun errore, uno saltato (fixture opzionale di migrazione). Audit localizzazione superato: 442 voci inglesi, 318 chiavi letterali/plurali. Test dedicati per vecchie preferenze senza dizionario, frasi vuote, persistenza su UserDefaults isolati, backup, testo identico cambiando lingua, sessione attiva invariata e rendering di frasi lunghe nei quattro spazi in Komorebi/Halloween chiaro/scuro.

Build Xcode Release, firma locale e integrità DMG verificate. Nessun archivio personale aperto durante le prove; Applicazioni non sostituita. Firma ad hoc senza notarizzazione.

Non sono stati provati click, VoiceOver e salvataggio delle ultime battute tramite chiusura reale dell’app. Prova residua sul Mac con dati di test: scrivere nei quattro campi, cambiare sezione subito, controllare le frasi nei rispettivi spazi, riaprire l’app, cancellare un campo, provare testi lunghi e cambio lingua/tema. Verificare anche la chiusura immediata dopo l’ultimo carattere.

## File modificati

- Sources/Models/Models.swift
- Sources/Views/SettingsView.swift
- Sources/Views/RootView.swift
- Sources/KomorebiApp.swift
- Sources/ThemeResources/Translations.json
- Tests/PersonalPhraseTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Frasi-personali-build18.md
- Docs/PASSAGGIO-PROGETTO.md
