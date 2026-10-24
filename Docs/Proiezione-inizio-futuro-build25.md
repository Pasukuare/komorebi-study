# Proiezione — inizio futuro (build 25)

## Causa e correzione
Il DatePicker limitava la data a oggi e ProjectionCalculator rifiutava qualsiasi inizio futuro. Rimossi entrambi i blocchi. Ora si può programmare l’inizio fino al giorno prima dell’esame; un esame oggi mantiene la possibilità di iniziare oggi. Nessuna migrazione, nessuna riscrittura dei dati precedenti.

Prima dell’inizio: zero ore fatte, zero ritmo misurato, stato Preparazione programmata e data esplicita. Il ritmo necessario è ore richieste / giorni locali dalla data scelta all’esame, escludendo il giorno dell’esame. Non si considera disponibile il tempo precedente all’inizio. Esempio: 52 ore, esame tra 27 giorni, inizio dopodomani → 25 giorni disponibili → 2,08 ore al giorno.

La proiezione a ritmo corrente rimane zero finché manca studio effettivo; non viene inventato un ritmo. Il grafico parte dalla data futura, senza indicatore Oggi fuori dal dominio. La cache esistente si aggiorna al cambio del giorno: raggiunta la data programmata il calcolo passa allo stato ordinario. Timer, archivio, navigazione e altri componenti invariati.

## Verifica
Test aggiunto su inizio domani, dopodomani, tra 10 giorni, il giorno prima dell’esame, data oltre l’esame e passaggio al giorno iniziale. Regressioni: caso 150/20/27 e tutte le altre prove della suite Release. Suite Release: 175 test, uno saltato (fixture reale opzionale), zero errori. Commit nella consegna. Audit localizzazione: 515 voci inglesi, 388 chiavi controllate. Build Xcode Release 25, firma locale e integrità DMG verificate. Nessuna prova manuale del DatePicker o di VoiceOver; controllare la scelta di una data futura sulla build separata.

## File modificati
- Sources/Models/Models.swift
- Sources/Views/StatisticsView.swift
- Sources/ThemeResources/Translations.json
- Tests/ProjectionTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Proiezione-inizio-futuro-build25.md
- Docs/PASSAGGIO-PROGETTO.md

App in Applicazioni non sostituita; prove con dati sintetici.
