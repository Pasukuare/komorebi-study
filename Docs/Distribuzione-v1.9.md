# Distribuzione v1.9 — build 26

## Dock e icona

L’icona ICNS dei sorgenti, della build 26 e della copia installata build 25 coincidono (SHA-256 `3e5927714ac07c929cdcaa3b530be258274dda52987552b1e8893abd0dd210db`). Il nuovo simbolo è già contenuto nei bundle, non occorre ridisegnarlo. Eseguita chiusura regolare della copia installata, registrazione mirata LaunchServices, riavvio Dock e riapertura della medesima app. Nessuna cancellazione generica delle cache, nessuna installazione della nuova build in Applicazioni. L’aspetto effettivo del Dock non è stato verificato con CUA.

## Primo avvio

Il vecchio helper saltava l’installazione se esisteva già Komorebi in Applicazioni: poteva quindi aprire una build vecchia. Ignorava gli errori di xattr e prometteva successo anche in caso di errore. Il nuovo helper:

- usa la copia accanto allo script nel DMG;
- verifica bundle ID e firma locale prima della copia;
- rifiuta app aperta, collegamento simbolico al posto dell’app e destinazione non scrivibile;
- chiede conferma prima di sostituire una versione precedente;
- prepara e verifica la copia prima della sostituzione, con ripristino della precedente se lo spostamento finale fallisce;
- rimuove soltanto com.apple.quarantine dalla nuova copia, senza sudo, modifiche globali alla sicurezza o cancellazione di altri attributi;
- registra il bundle e invia a macOS la richiesta di apertura solo dopo l’installazione.

Il LEGGIMI distingue firma locale da notarizzazione: anche lo script .command può ricevere un blocco di macOS. Non viene promessa apertura senza avvisi su ogni Mac. Non eseguire helper ricevuti da fonti non verificate.

## Verifiche

- Codice app invariato rispetto alla build Per unità verificata: 188 test Release, uno saltato, zero errori; log incluso.
- bash -n su helper e script di build: superato.
- Preflight in sola lettura sul bundle Release: superato.
- Preflight con bundle ID diverso: rifiutato correttamente.
- Build Xcode Release 1.9 (26), firma locale e checksum DMG: verificati.
- DMG montato in sola lettura: app, collegamento Applications, helper eseguibile e LEGGIMI presenti. Hash dell’icona e contenuto dello script confrontati con i sorgenti: identici.
- Nessun test d’installazione sulla copia personale, nessuna prova di Gatekeeper su un Mac pulito e nessuna notarizzazione. Sono limiti espliciti della verifica.

## GitHub e consegna

Nuova release v1.9, mantenendo v1.8 e la cronologia precedente. Include modalità Per unità e tutte le modifiche precedenti già nei sorgenti. Destinazione prevista: https://github.com/Pasukuare/komorebi-study/releases/tag/v1.9 . File pubblicati e commit di riferimento verificati dopo l’upload. Sorgenti esportati dal commit della release, DMG e SHA-256 allegati. Distribuzione locale: Dist/Komorebi-v1.9-build26.

File di questa modifica: Scripts/Primo Avvio (Sblocca).command, Scripts/LEGGIMI-Primo-Avvio.txt, Scripts/build-release.sh, Komorebi Study.xcodeproj/project.pbxproj, README.md, Docs/Distribuzione-v1.9.md, Docs/PASSAGGIO-PROGETTO.md.
