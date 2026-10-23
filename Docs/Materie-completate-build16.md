# Materie completate e voto facoltativo — build 16

Nel pannello Modifica materia è disponibile l’interruttore custom «Materia completata». Quando è attivo compare il campo «Voto (facoltativo)». Il voto è testo libero, adatto a scale diverse, lode e idoneità; non viene imposta una scala numerica. Nella card della materia sono visibili lo stato e l’eventuale voto. La parte dei campi è scorrevole per contenere il pannello anche con il voto presente; i pulsanti rimangono visibili.

Salva e Annulla continuano a usare una bozza indipendente. Togliere lo stato completata rende la materia nuovamente in corso senza cancellare il voto: riattivando lo stato il voto può essere modificato o svuotato. Nessuna materia viene nascosta o rimossa dai selettori del timer, nessun conteggio cambia e le sessioni conservano i propri collegamenti.

## Persistenza e compatibilità

Il modello Subject aggiunge due attributi opzionali: completed e grade. L’assenza di completed equivale a false; gli archivi esistenti non richiedono valori inventati. Backup JSON e importazione includono i due attributi, mantenendo la lettura dei vecchi backup che non li contengono. Gli identificativi delle materie restano invariati.

## Verifiche

Suite Release: 135 test, 1 saltato (fixture opzionale di migrazione), nessun errore. Vedere tests-release.log nella consegna; test di bozza/annullamento, salvataggio e riapertura di un archivio temporaneo, round trip del backup, compatibilità con il vecchio JSON e migrazione da un modello Subject precedente congelato nel test. Rendering automatico del pannello con nome lungo, stato completato e voto in Komorebi/Halloween chiaro/scuro. Audit delle stringhe italiano/inglese. Build Xcode Release, firma locale e integrità DMG.

Nessun archivio personale utilizzato. Non sono state eseguite prove manuali di click, tastiera o VoiceOver: sul Mac verificare Modifica → Completata → voto → Annulla/Salva e successiva riapertura, nei due temi e nelle due lingue. La migrazione è testata su archivio sintetico, non sul database personale.

## File modificati

- Sources/Models/Models.swift
- Sources/Services/BackupService.swift
- Sources/Views/SubjectsView.swift
- Sources/ThemeResources/Translations.json
- Tests/SubjectEditorTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Materie-completate-build16.md
- Docs/PASSAGGIO-PROGETTO.md

Build separata 1.8 (16), firma ad hoc senza notarizzazione. App in Applicazioni non sostituita.
