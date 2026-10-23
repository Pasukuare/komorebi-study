# Modifica delle materie — build 15

Il comando Modifica apre un pannello dedicato sopra l’elenco, senza portare al modulo in cima. La posizione di scorrimento e la bozza di una nuova materia non vengono modificate. Il pannello riusa gli stessi controlli di creazione: nome, icona, palette stagionali, obiettivo e anteprima.

La bozza è separata dal modello. Annulla / Esc la scartano; Salva modifiche / Invio applicano i valori conservando identificativo e collegamenti alle sessioni. Nome vuoto disabilita il salvataggio. Le regole dell’obiettivo rimangono quelle precedenti. In caso di errore di salvataggio il pannello rimane aperto e ripristina i valori originali della sola materia.

## Verifiche

- Suite SwiftPM Release: 132 test, 1 saltato, nessun errore. Il test saltato richiede una fixture facoltativa di migrazione archivio.
- Test dedicati: isolamento della bozza, identità invariata, normalizzazione del nome, limiti dell’obiettivo, rendering con nome lungo in Komorebi/Halloween chiaro/scuro.
- Audit localizzazione: catalogo esistente riutilizzato, nessuna stringa nuova.
- Build Xcode Release e verifica firma locale / integrità DMG.
- Nessun archivio personale aperto o modificato durante le prove.

## Limiti e prova manuale riproducibile

Non sono stati eseguiti click nativi o screenshot prima/dopo. Con dati di prova: scorrere fino all’ultima materia; premere Modifica e verificare l’apertura del pannello; cambiare tutti i campi e annullare; riaprire e salvare; confermare valori aggiornati e posizione nell’elenco; provare Tab, Invio, Esc e i selettori; verificare che un’eventuale bozza nel modulo di creazione sia ancora presente. Ripetere in entrambi i temi/modalità e in italiano/inglese.

Build separata: `Dist/Komorebi-Editor-Materie-build15/Komorebi Study.app`. L’app in Applicazioni non è stata sostituita. Firma ad hoc, senza notarizzazione Apple.

## File modificati

- `Sources/Views/SubjectsView.swift`
- `Tests/SubjectEditorTests.swift`
- `Komorebi Study.xcodeproj/project.pbxproj` (build 15)
- `Docs/Editor-materie-build15.md`
- `Docs/PASSAGGIO-PROGETTO.md`
