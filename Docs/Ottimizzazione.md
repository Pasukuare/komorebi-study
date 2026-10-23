# Compito 4 — Ottimizzazione, consegna del 23 ottobre 2026

## Ambito concordato

L’ultima istruzione dell’utente autorizza a completare il lavoro mediante codice e `swift test`, saltando misure manuali dell’interfaccia e CUA. Questa consegna conclude l’implementazione e la verifica automatica in tale ambito. Non certifica prestazioni percepite, equivalenza visiva pixel per pixel, scorciatoie nel vero host macOS, consumo energetico o stabilità per trenta minuti.

## Interventi, in ordine di impatto atteso

1. **Marchio Halloween composito**, già nel commit `e17445c`: medesima geometria, gradiente e curva luminosa; animazione dell’opacità affidata a Core Animation. Il confronto Release precedentemente raccolto nella sola Home Halloween scura è passato da 52,40% a 10,65% CPU, circa 24 secondi per campione; non è una misura dell’intera nuova build.
2. **Clock isolato**: StudyClock pubblica i secondi; StudyStore pubblica il cambio di giornata/fuso e le normali modifiche dello stato. Configurazione, sidebar e sezioni nascoste non osservano più un `@Published now` generale. LiveStudyTime aggiorna soltanto i piccoli sottoalberi del tempo/progresso visibili. Alla riapertura o ripresa riallinea il valore; non smonta le sezioni e non cambia scroll, bozze, filtri o identità.
3. **Lavoro nascosto**: cifre e animazioni implicite del ring non animano quando la sezione/finestra è invisibile. Paesaggi, respiro e candela sono sospesi per finestra coperta/minimizzata/app inattiva. Un probe per host ascolta notifiche AppKit: nessun nuovo timer di polling.
4. **Basso consumo**: decorazioni ambientali e respiro in pausa, con feedback discreto. Opzioni Decorazioni, Animazioni e Riduci movimento conservate; nessun cambio di preferenze salvate. Fuori dal Basso consumo non vengono cambiate palette, font, misure o decorazioni. Il popover menu resta aggiornato anche quando l’app principale è inattiva; la label del menu ha il proprio piccolo aggiornamento temporale.
5. **Ciclo di vita**: invalidazione del ticker e rimozione dell’osservatore sleep quando lo store viene rilasciato. I probe e il compositore rimuovono i loro osservatori; callback deboli e aggiornamenti del probe accorpati sul main queue.

Conteggi, pause, completamenti, salvataggi e algoritmo del timer restano quelli esistenti. In Statistiche il solo confronto con il periodo precedente conserva l’aggiornamento temporale anche a timer fermo, senza aggiornare ogni secondo grafici e liste. Non sono state introdotte cache delle aggregazioni o spostamenti di SwiftData tra thread: dopo la separazione del clock non esistono nuove misure che ne giustifichino il rischio. Hover/spotlight restano State locali del modificatore riusato; non sono state confermate invalidazioni di tutte le card da correggere. Ombre e blur non sono sostituiti alla cieca. Sidebar nativa translucida invariata.

## Verifiche eseguite

- Build Release riuscita: `swift build -c release -debug-info-format none --disable-sandbox --cache-path /tmp/komorebi-spm-cache`.
- Suite completa riuscita: `swift test --disable-sandbox --cache-path /tmp/komorebi-spm-cache`: **92 test, uno saltato, zero errori**. Il fixture opzionale di archivio reale non è fornito; archivio personale mai usato. Alcuni log CoreData segnalano impossibilità di registrare notifiche nell’ambiente limitato: i test in memoria passano, ma non certificano le integrazioni di sistema.
- Nuovi test: sessanta avanzamenti di un secondo producono sessanta eventi del clock e **zero eventi generali dello store**; un cambio di giornata produce un evento dello store. Verificati cambio fuso e giornata DST di 23 ore; progresso giornaliero oltre mezzanotte; pausa/ripresa; completamento naturale mediante tick; rilascio di store/clock; tutte le combinazioni della policy visibilità/occlusione/minimizzazione/attività/Basso consumo.
- Render automatici ImageRenderer del Timer nei due temi, chiaro/scuro, opzioni Decorazioni on/off, due larghezze; verificata disponibilità dell’immagine e dimensione. Gli altri test coprono metriche e cifre, dati, temi e layout. **Questi render non dimostrano identità visiva né fluidità delle animazioni**. La policy Riduci movimento è coperta dai test già presenti; non è stata cambiata l’impostazione di sistema per una prova manuale.
- `git diff --check` riuscito. Bundle separati firmati ad hoc e verificati, non notarizzati. Nessun avvio della build ordinaria o sostituzione in Applicazioni.

## Scorciatoie e vetro: regressione entro l’ambito automatico

Audit del diff: i comandi Vista/Studio, i gestori di Focus, i controlli personalizzati e il monitor tastiera non sono stati rimappati né duplicati. Azioni del modello e lifecycle del timer sono verificate dalla suite; inventario e checklist in Scorciatoie.md. Nessuna prova nativa degli eventi è dichiarata ripetuta.

MenuPanel mantiene superfici opache del tema e `containerBackground` introdotto dal commit `58e53e1`. La label MenuBarExtra non aggiunge un proprio fondo. Il materiale nativo della sidebar resta. Blur di ring e luce restano effetti decorativi. Bordo/riflessi del contenitore macOS, evidenziazione di sistema, tema effettivo del popover e interazione al suo interno non sono verificabili dai soli test del modello. La precedente annotazione sul blocco del popover non viene presentata come risolta dalla compilazione.

## Tabella prima/dopo e limiti

Valori CPU della fase A, 100% = un core; condizioni e trace nel rapporto Fase A allegato. La colonna finale resta senza valori inventati, come autorizzato dall’utente.

| Scenario | CPU prima | Dopo questa build |
|---|---:|---|
| Home Komorebi ferma | 10,4% | Non misurato |
| Timer Komorebi fermo | 31,5% | Non misurato |
| Timer Komorebi attivo | 71,3% | Non misurato |
| Timer Halloween + Decorazioni | 55,8% | Non misurato |
| Calendario con timer attivo | 54,4% | Non misurato |
| Statistiche con timer attivo | 55,1% | Non misurato |
| Cronologia con timer attivo | 55,7% | Non misurato |
| 12 cambi sezione | 61,0% | Non misurato |
| 7 cambi tema | 56,1% | Non misurato |
| 6 cicli sidebar | 68,8% | Non misurato |
| Secondo piano, indicativo dopo ⌘H | 76,0% | Non misurato |
| Hover puro / apertura popover reale | Non misurato | Non misurato |

L’unico confronto prima/dopo di CPU effettivo rimane la Home Halloween del primo intervento: 52,40% → 10,65%, footprint finale 272,24 → 255,49 MiB. Nessuna estensione di quei risultati agli altri interventi/scenari. Nel test automatico del clock si verifica la soppressione degli eventi generali, non il numero reale di body ricalcolati da SwiftUI.

Non misurati nella build finale: FPS/hitch, energia, tempo apertura popover, memoria dopo dieci minuti per scenario e dopo trenta minuti. Target 60 fps, CPU sotto 5%, riposo vicino a zero e apertura sotto 100 ms **non certificati**. Le verifiche manuali sono state saltate su istruzione esplicita, non dichiarate superate. Per misurarli: stessa istanza di prova Release, medesimi fixture e viewport, cattura disattivata quando possibile, Instruments/Activity Monitor e checklist tastiera del compito 3.

## File, cronologia e consegna

File modificati: Sources/Services/StudyStore.swift; Sources/Components/Style.swift; Sources/Components/Themes.swift; Sources/Views/RootView.swift; Sources/Views/StatisticsView.swift; Sources/KomorebiApp.swift. Nuovi: Tests/RenderingIsolationTests.swift, Docs/Ottimizzazione.md.

Baseline della ripresa `e17445c`. Nuovo commit richiesto: `Compito 4: Isola il clock e sospendi il rendering non visibile`. **Non creato**: `git add` restituisce `Unable to create .git/index.lock: Operation not permitted`; la cartella .git è in sola lettura. Nessuna riscrittura della cronologia né aggiramento dei permessi. Consegnate copia datata completa e patch da applicare/committare quando Git è scrivibile.

La cartella Dist/Komorebi-Compito-4-20261023 contiene build Release ordinaria e Prova in memoria, sorgenti, patch, rapporto e log. Per collaudare usare solo Prova: la build ordinaria, se aperta, accede al normale archivio personale e non è stata avviata durante queste prove. Nessuna app installata o sostituita in Applicazioni.
