# Ottimizzazione e controllo bug — build 14

24 ottobre 2026. Baseline: build 13, registrata in Git come `59c337e`. Aspetto, dati e logica del timer conservati. Interventi e test conclusi nell'ambito del codice; **fluidità, CPU, watt, hitch e memoria prolungata dell'interfaccia reale non sono certificati**.

## Cosa è stato corretto e perché

| Percorso | Problema nel codice | Intervento |
|---|---|---|
| Hover/spotlight | Tutti i target, anche inattivi, erano trasformati in array/candidati a ogni evento; gli outline venivano ricostruiti ripetutamente | Filtro dei target attivi prima dei calcoli, scelta in un solo passaggio, geometria locale riusata finché bounds/forma/raggio non cambiano |
| Puntatore | Ogni evento del mouse poteva aggiornare lo stato del gradiente, anche più volte per frame | Un CADisplayLink AppKit legato alla finestra accorpa gli eventi. Il link viene sospeso dopo il frame richiesto, senza polling continuo a riposo; reset e chiusura cancellano le richieste |
| Scroll | Ogni controllo/righetta installava un proprio osservatore della stessa NSClipView | Un osservatore per contenitore; test con 100 registrazioni dello stesso contenitore ne verifica uno solo e la rimozione allo stop |
| Conteggi | JSON degli intervalli decodificato per ogni sessione e ogni intervallo richiesto | StudyActivityCache confronta ID e Data esatti; cache NSCache con limiti di conteggio/costo ed eliminazione automatica; nessun totale salvato o modello SwiftData trattenuto nella cache |
| Calendario/Statistiche | Le stesse proprietà SwiftData venivano lette nuovamente per ogni cella/barra | Snapshot di valori temporali una volta per sessione, conteggi in blocco; esami raggruppati una volta; indice materie invece di ricerche ripetute |
| Serie | Ogni giornata della serie ripeteva le letture del modello | Snapshot temporali riusati nello stesso calcolo, stesse soglie e stesso limite storico |
| Cronologia | Lo stesso filtro era eseguito per conteggio, vuoto e List; inizio giornata ricalcolato dentro il predicato | Una sola lista filtrata per body, limiti temporali fuori dal ciclo; List resta pigra |
| Avvio/sezioni | Tutte le schermate, grafici e probe nativi erano create anche prima della prima visita | Prima creazione differita; dopo la visita la sezione resta montata con la stessa identità per conservare scroll, filtri e bozze |
| Focus | Ogni movimento aggiornava una Date in State e cancellava/ricreava il task di timeout | FocusControlsActivity mantiene una sola scadenza monotona e pubblica solo mostra/nascondi; stop su invisibilità/uscita. FocusState distinto per ognuno dei tre pulsanti |
| Audio | Sintesi PCM di 12 secondi sul thread UI; secondo array temporaneo dei campioni | Generazione su task separato, cancellazione delle richieste superate, controllo ID prima dell'installazione del player; buffer WAV preallocato, senza array duplicato |
| Timer/Dock | Badge assegnato anche se invariato e ticker senza tolleranza | Assegnazione solo se il testo cambia, tolleranza di 0,1 s per accorpare i wake-up. Tempo e completamento continuano a derivare dalle date; checkpoint e comportamento del timer invariati |

## Numeri verificati: microbenchmark Release

Mac originale: **Mac16,8, Apple M4 Pro, 12 core, 24 GB, macOS 27.0.1**. NSScreen riporta massimo **120 Hz**; frequenza effettiva durante le prove non misurata. Basso consumo risultava spento al controllo. Carico di altre applicazioni e condivisione schermo non sono controllati: queste prove non sono un benchmark energetico.

Tre processi XCTest Release per versione, alternati prima/dopo; mediana. Fixture sintetica di 1.000 sessioni con pause registrate; 400 target hover, geometria preparata una volta. Nessun archivio personale. Prima = sorgenti build 13 con adattatore di test che ripete i vecchi calcoli individuali; dopo = gli stessi input e nuove API in blocco. Checksum dei risultati uguali in tutte le ripetizioni, inclusi totali mensili e barre.

| Lavoro di codice | Prima, mediana | Dopo, mediana | Riduzione del tempo |
|---|---:|---:|---:|
| Hit test hover: 20.000 punti, 400 target | 554.121 ms | 188.110 ms | 66.1% |
| 200 totali ripetuti, 1.000 sessioni | 529.164 ms | 205.896 ms | 61.1% |
| 31 giornate, chiamate individuali | 83.103 ms | 31.835 ms | 61.7% |
| Mese del Calendario: 31 giorni in blocco | 83.576 ms | 2.192 ms | 97.4% |
| Statistiche: 31 barre in blocco | 82.889 ms | 1.613 ms | 98.1% |

**Questi millisecondi non sono il tempo di apertura della schermata, gli FPS o la CPU dell'app.** Il test dell'hover misura la policy di hit test, non tutta la catena AppKit/SwiftUI/GPU. I risultati confermano il minor costo dei calcoli indicati; non dimostrano che il consumo rilevato dall'utente sia già sceso o che non esistano più scatti.

Dati e log delle singole prove: cartella `Benchmark/` della consegna. Riproduzione da una copia della baseline:

```bash
git worktree add ../Komorebi-build13 59c337e
python3 Scripts/benchmark-release.py \
  --baseline-source ../Komorebi-build13 \
  --output Dist/Benchmark-ripetizione --runs 3
```

Lo script lavora su una copia temporanea della baseline, compila Release e conserva i log. Il flag opzionale `--disable-sandbox` serve soltanto negli ambienti che lo richiedono. Non apre l'app e non misura l'interfaccia.

## Controllo bug e regressioni eseguito

- Suite completa: **129 test, uno saltato, zero errori**, in Debug e Release. Il test saltato richiede la fixture opzionale di migrazione; non viene sostituita con dati personali.
- Cache: riuso della stessa Data senza decodifica ripetuta; modifica del payload con stesso UUID; errori JSON memorizzati senza cambiare il fallback; modifiche temporali e legacy.
- Batch: pause escluse, attraversamento della mezzanotte, soggetti distinti, proporzioni/ID colore, rinomina senza dati obsoleti, modifica durata dopo cache calda, intervalli senza sessioni e serie giornaliera. La suite precedente continua a coprire DST, ripresa, completamento, migrazioni e persistenza.
- Hover: forma visibile e priorità del figlio interno conservate dai test precedenti; una richiesta accodata per una raffica di eventi, cancellazione sul reset, ripristino mouseMoved e rilascio della sessione senza ciclo di ritenzione. Gli eventi di test sono passati direttamente al metodo, non sono click nell'app reale.
- Focus: 1.000 movimenti mentre i controlli sono visibili non pubblicano aggiornamenti; estensione della scadenza, mostra/nascondi, cancellazione e rilascio del controller. La navigazione dei pulsanti con Tab nell'host reale resta da provare.
- Audio: hash SHA-256 dei tre WAV identico ai campioni prodotti dal codice precedente, **byte per byte**; generazione cancellata correttamente. Nessuna riproduzione dagli altoparlanti è stata usata come test.
- Audit localizzazione: **425 traduzioni inglesi**, 301 chiavi letterali/plurali controllate; segnaposto coerenti. Test lingua, temi, render, focus policy e layout continuano a passare.
- xcodebuild Release riuscito; nessun nuovo warning di compilazione dei sorgenti. Rimane l'avviso dell'ambiente per il supporto iOS Simulator fuori versione, estraneo al target macOS. I render automatici possono emettere gli avvisi FocusState già documentati: non sono prove native del focus.

## Pulizia e spiegazioni nel codice

La pulizia riguarda i percorsi modificati, senza riformattare l'intero progetto: eliminati array intermedi, osservatori duplicati, doppia gestione dei campioni PCM e task per singolo movimento. Funzioni separate per snapshot dei conteggi, cache, sintesi WAV e attività Focus. Commenti spiegano invalidazione della cache, coordinate locali durante lo scroll, lifecycle/cancellazione, limiti del conteggio legacy e motivo della creazione differita delle sezioni.

## Verifiche ancora necessarie / limiti

| Scenario reale | CPU/FPS/hitch/watt dopo build 14 |
|---|---|
| Hover su Statistiche, card e chip; scroll/click Cronologia | Non misurati nell'interfaccia |
| Timer visibile e coperto, decorazioni on/off | Non misurati nell'interfaccia |
| Focus, cambio sezione/tema, apertura/chiusura sidebar | Non misurati nell'interfaccia |
| Popover della barra menu: apertura e bande trasparenti | Correzione precedente conservata; conferma visiva ancora mancante |
| Recupero reale dopo riavvio, sleep, notifiche, menu/Dock | Modello testato; integrazioni reali da ricollaudare in ambiente separato |
| Memoria dopo 10/30 minuti e cambi ripetuti | Non misurata; non dichiarata stabile |

Non c'erano strumenti di controllo dell'interfaccia disponibili per questo passaggio. Nessun target universale di zero lag o consumo assoluto viene dichiarato raggiunto. Il lavoro legittimo di menu/Dock può continuare a 1 Hz quando il timer è attivo anche se la finestra è coperta. La cache NSCache ha limiti di costo/conteggio, non è una misura o un tetto rigido della memoria del processo.

Restano fetch/salvataggi SwiftData e import sul MainActor e decorazioni TimelineView/Canvas a frequenza limitata: non sono stati riscritti alla cieca né sono stati passati modelli gestiti tra thread. Valutare ulteriori interventi con Instruments su archivi grandi e sessioni lunghe, partendo dai casi riferiti dall'utente. La sidebar nativa traslucida e l'aspetto delle decorazioni non sono stati rimossi.

## Consegna e cronologia

Build **1.8 / 14**, Release Apple Silicon, firma locale ad hoc, non notarizzata. DMG separato: `Dist/Komorebi-Study-Ottimizzata-20261024.dmg`. App in Applicazioni non sostituita, archivio personale non usato per le prove.

La build 13 è stata registrata come snapshot Git `59c337e` per preservare i precedenti lavori non committati. Questi interventi sono in un commit successivo separato, con titolo `Ottimizzazione: riduci lavoro di hover, conteggi e Focus`. Nessuna riscrittura della cronologia. Identificativi esatti nella consegna (`GIT-COMMIT.txt`). Sorgenti, documentazione di passaggio aggiornata, patch incrementale, manifest file modificati, log e benchmark sono allegati.
