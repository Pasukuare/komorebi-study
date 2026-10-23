# Komorebi Study — passaggio di progetto

Aggiornato: **24 ottobre 2026**, dopo la consegna **Release build 19** (countdown esame nella Home).
Destinatario: sviluppatore o agente incaricato di correggere bug, verificare le prestazioni e continuare lo sviluppo.

La build 19 mostra il countdown in giorni all’esame più vicino sopra la serie nella Home, rimuovendo la foglia accanto alla serie. Nessuna modifica ai dati degli esami. Vedere `Docs/Countdown-esame-build19.md`.

La build 18 aggiunge quattro frasi personali facoltative (Home, Timer, Obiettivo di oggi, barra dei menu), con salvataggio accorpato e nessuna frase predefinita. Vedere `Docs/Frasi-personali-build18.md`.

La build 17 distingue le palette stagionali, preserva la tonalità in scuro e aggiunge descrizioni nel selettore. Classici e identificativi salvati invariati. Vedere `Docs/Palette-stagionali-build17.md`.

La build 16 aggiunge lo stato completata e il voto facoltativo, con attributi opzionali, backup compatibili e test di migrazione sintetica. Vedere `Docs/Materie-completate-build16.md`.

La build 15 apre un editor dedicato con Salva/Annulla dal comando Modifica di ogni materia; creazione e modifica condividono i controlli ma non la bozza. Vedere `Docs/Editor-materie-build15.md` per verifiche e limiti.

## 1. Da leggere prima di iniziare

L'app è funzionante e compilabile, ma **la verifica nativa dell'interfaccia e delle prestazioni non è conclusa**. La build 14 aggiunge ottimizzazioni di hover, scroll, conteggi in blocco, avvio, Focus e audio. Le correzioni precedenti del grafico e del popover sono conservate; non è ancora confermato nell’interfaccia reale che lag e bande siano scomparsi. Vedere `Docs/Ottimizzazione-build14-20261024.md`.

La build 13 aggiunge Italiano/Inglese e rimuove le frasi motivazionali; vedere `Docs/Lingue-e-testi-20261024.md`. I bug di interfaccia/prestazioni segnalati sulla build 11 e corretti nella 12 restano da verificare anche nella 13.

La build 13 è stata registrata in Git nello snapshot `59c337e`; l’ottimizzazione della build 14 è nel commit successivo, riconoscibile dal titolo `Ottimizzazione: riduci lavoro di hover, conteggi e Focus`. Consultare `git log` o `GIT-COMMIT.txt` della consegna. Conservare sempre una copia prima di operazioni distruttive; Dist e Checkpoints non sono versionati.

Il documento fotografa lo stato attuale: non è una richiesta di implementare tutte le idee dei vecchi prompt. Concordare con il proprietario nuovi interventi che cambiano comportamento o aspetto.

### Vincoli del proprietario

- Conservare dati, conteggi, comportamento del timer e navigazione, salvo richiesta esplicita.
- Modificare solo ciò che è necessario al problema in esame. Niente redesign generale durante un bugfix.
- Riutilizzare token e componenti custom. Niente nuovi colori, font o decorazioni sparsi nelle viste; niente nuove librerie senza necessità concordata.
- Stile calmo, organico e luminoso; palette calde, Komorebi e Halloween/Pergamena supportati.
- Rispetto di tastiera, VoiceOver, Riduci movimento, tema di sistema e finestre strette.
- Per le prove usare dati separati. Non modificare o cancellare l'archivio personale.
- Consegnare build separate. **Non sostituire l'app in Applicazioni senza istruzione esplicita.**
- Distinguere sempre implementato, testato automaticamente, provato nell'interfaccia e misurato. Una build riuscita non dimostra fluidità o consumo ridotto.
- Alla consegna elencare file modificati, verifiche, problemi aperti e limiti. Per compiti numerati richiesti dall'utente: annunci di inizio/fine e commit per compito; dichiarare la fine solo dopo le verifiche concordate.

## 2. Dove si trova il progetto e cosa consegnare

Percorso sul Mac originale:

```text
/Users/ale/Documents/ChatGPT/Komorebi
```

Ultima app consegnata: versione dichiarata **1.8**, build **14**, Apple Silicon, Release, firma locale ad hoc, non notarizzata.

| Elemento | Percorso relativo al progetto |
|---|---|
| DMG più recente | `Dist/Komorebi-Study-Ottimizzata-20261024.dmg` |
| Consegna build 14, benchmark e sorgenti | `Dist/Komorebi-Ottimizzata-20261024/` |
| DMG lingue, build 13 | `Dist/Komorebi-Study-Lingue-20261024.dmg` |
| Consegna lingue e testi | `Dist/Komorebi-Lingue-20261024/` |
| DMG precedente, fix Statistiche | `Dist/Komorebi-Study-Fix-Statistiche-20261024.dmg` |
| Checksum DMG | stesso nome con suffisso `.sha256` |
| App separata | `Dist/Komorebi-Correzione-Statistiche-20261024/Komorebi Study.app` |
| Log, rapporto, sorgenti e patch recenti | `Dist/Komorebi-Correzione-Statistiche-20261024/` |
| Dettaglio ultimo bugfix | `Docs/Correzioni-statistiche-popover-20261024.md` |
| Antecedente immediato | `Dist/Komorebi-Study-Aggiornata-20261024.dmg`, build 11 |
| Vecchia Prova D, già Release | `Dist/Komorebi-D-Chiara-20261023/Komorebi-Prova-D.app` |
| Confronto hover prima/dopo | `Dist/Komorebi-Interazioni-Compito-1-20261023/` |
| Copie antecedenti all'ultimo bugfix | `Checkpoints/bug-statistiche-popover-20261024/` |

`Dist/`, `Checkpoints/` e i prodotti di build sono ignorati da Git: un clone da solo non li contiene. I percorsi di questa tabella sono quelli del Mac originale; se non presenti nel materiale ricevuto, richiederli al proprietario. Il pacchetto di passaggio creato insieme a questo documento include sorgenti correnti, progetto Xcode, risorse e documentazione; non include l'archivio personale né le vecchie trace di Instruments.

## 3. Stack e struttura

macOS **15+**, Swift/SwiftUI, SwiftData, Swift Charts, AppKit, UserNotifications, AVFoundation. Manifest Swift tools 6.0, modalità linguaggio Swift 5. Nessuna dipendenza esterna nel Package.swift. Test eseguiti tramite Swift Package Manager; progetto Xcode per la confezione dell'app.

| File/cartella | Responsabilità |
|---|---|
| `Sources/KomorebiApp.swift` | entry point, comandi menu, MenuBarExtra, MenuPanel, fixture preview; ora anche `MenuPanelWindowSurface` |
| `Sources/Models/Models.swift` | modelli SwiftData, impostazioni, ActiveTimer, formattazione e percorso review |
| `Sources/Services/StudyStore.swift` | stato principale MainActor, persistenza, transizioni timer, tick, aggregazioni, notifiche, migrazioni |
| `Sources/Services/BackupService.swift` | import/export e backup |
| `Sources/Services/AmbientAudio.swift` | ambienti audio sintetici |
| `Sources/Components/Style.swift` | design system, componenti comuni, hover/focus, rendering lifecycle, ring, clock islands e decorazioni |
| `Sources/Components/Themes.swift` | pacchetti Komorebi/Halloween, token, risoluzione chiaro/scuro, font e marchi |
| `Sources/Components/Controls.swift` | dropdown e controlli custom, gestione tastiera dei popover |
| `Sources/Components/SubjectAppearance.swift` | icone, palette e selettori delle materie |
| `Sources/Views/RootView.swift` | contenitore, sidebar/header, sezioni e Timer/Focus |
| altre `Sources/Views/` | Calendario, Statistiche, Cronologia, Materie, Impostazioni |
| `Sources/ThemeResources/Fonts/` | font incorporati e licenze OFL |
| `Resources/` | Info.plist e AppIcon.icns |
| `DesignProposals/Identity-D-Final/` | master, SVG e risorse dell'identità scelta |
| `Tests/` | suite dati/timer, migrazioni, temi, layout e policy d'interazione/rendering |
| `Scripts/` | build, test, icona e audit dei contrasti |

**Attenzione:** README.md è precedente a diversi cambiamenti. Alcuni testi su versione, sleep, palette e scorciatoie possono essere obsoleti; verificare il codice e la documentazione recente prima di considerarli specifiche.

## 4. Dati e ambiente di prova

L'app ordinaria (`com.komorebi.study`) apre:

```text
~/Library/Application Support/Komorebi Study/Study.store
```

SwiftData può usare anche file collegati al database. Non spostare o copiare solo un singolo file mentre l'app sta scrivendo. Impostazioni e stato attivo sono anche in UserDefaults: il solo database non rappresenta tutto lo stato. Per backup o migrazioni usare i percorsi previsti nell'app e copie coerenti, mai sperimentare sull'originale.

I bundle con identificatore che inizia per `com.komorebi.study.preview` ricevono store **in memoria**, preferenze isolate con suite UUID e fixture da `configurePreview`. Non è sufficiente rinominare la .app: va cambiato il bundle identifier e rifatta la firma. Non cambiare l'identificatore del bundle originale.

Le preview saltano alcune integrazioni di sistema. Il clock viene alimentato da una task della finestra, mentre l'app ordinaria usa un Timer: non assumere che una preview riproduca esattamente comportamento in background, chiusura di tutte le finestre, notifiche, Dock e recupero dopo riavvio. Le preferenze preview sono isolate e non rappresentano la persistenza reale tra avvii. Per questi test progettare un archivio persistente e UserDefaults separati verificando anche il clock e le integrazioni.

Esiste anche `StudyReviewArchive` per bundle `com.komorebi.study.review...`: percorso separato `Komorebi Study Review/Study.store`. Questo da solo non garantisce l'isolamento di tutte le preferenze o l'equivalenza del ticker; leggere l'inizializzazione prima di usarlo.

## 5. Build, test e confezione

Da terminale, nella root del progetto:

```bash
swift test
swift build -c release -debug-info-format none
```

Nel precedente ambiente limitato sono stati usati:

```bash
CLANG_MODULE_CACHE_PATH=/tmp/komorebi-clang-cache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/komorebi-swift-cache \
swift test --disable-sandbox --cache-path /tmp/komorebi-spm-cache

CLANG_MODULE_CACHE_PATH=/tmp/komorebi-clang-cache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/komorebi-swift-cache \
swift build -c release -debug-info-format none --disable-sandbox \
  --cache-path /tmp/komorebi-spm-cache
```

Questi flag sono un adattamento all'ambiente, non un requisito funzionale. Il percorso del binario dipende dal sistema di build: rilevarlo con `swift build -c release --show-bin-path`; sul Mac originale l'ultimo prodotto era `.build/out/Products/Release/KomorebiStudy`.

Per la confezione completa esiste:

```bash
bash Scripts/build-release.sh "$PWD/Dist/Consegna-Nuova"
```

Lo script usa xcodebuild Release, crea una .app firmata ad hoc e un DMG con link ad Applications. **Le ultime build documentate sono state compilate con SwiftPM e confezionate copiando il binario nel bundle separato; nella build 13 è stato verificato anche xcodebuild Release con la nuova risorsa delle traduzioni, ma non lo script completo di confezione.** Verificare che il progetto Xcode includa tutti i file e le risorse quando si aggiungono sorgenti: non presumere la scoperta automatica dei nuovi file.

Il bundle deve contenere Info.plist, eseguibile, AppIcon.icns e font con licenze. ThemeFonts cerca `Resources/Fonts/`, con fallback al bundle risorse SwiftPM. Dopo aver modificato eseguibile, plist o risorse, rifirmare e verificare:

```bash
codesign --force --deep --sign - "percorso/Komorebi Study.app"
codesign --verify --deep --strict "percorso/Komorebi Study.app"
hdiutil verify "percorso/consegna.dmg"
shasum -a 256 "percorso/consegna.dmg"
```

Usare una destinazione nuova, senza sovrascrivere consegne precedenti. Non pubblicare come notarizzata una firma ad hoc. Aggiornare build/versione e conservare log, checksum e sorgenti esatti della consegna.

### Ultimo esito automatico disponibile

**129 test, uno saltato, zero errori**, in Debug e Release per la build 14. Log: `Dist/Komorebi-Ottimizzata-20261024/tests.log` e `tests-release.log`. Il test saltato richiede `KOMOREBI_MIGRATION_FIXTURE`, fixture opzionale di migrazione; non è stato usato l'archivio personale per abilitarlo. Firma della build e integrità del DMG verificate. Questo documento non comporta nuove modifiche al codice o un nuovo collaudo.

## 6. Modifiche recenti da preservare

### Clock e rendering

StudyClock pubblica i secondi separatamente da StudyStore. Il cambio di giornata/fuso invalida il riepilogo generale, i tick ordinari no. LiveStudyTime osserva i secondi solo nei sottoalberi del tempo. Non ripristinare un `@Published now` sul modello principale senza misurare le invalidazioni.

Le sezioni restano montate per conservare stato e scroll. `komorebiSectionVisible` e RenderingState governano visibilità, occlusione, minimizzazione, attività e basso consumo. Le animazioni nascoste devono sospendersi senza interrompere il timer. Marchio Halloween con animazione Core Animation; altre decorazioni includono ancora TimelineView/Canvas. Non sono state introdotte cache generali o riscritture del modello SwiftData.

### Interazioni

Sessione di interazione per host, monitor eventi che non consuma i tasti, registro di target e un solo proprietario dell'hover. Focus visivo solo in modalità tastiera; selezione distinta; righe senza rialzo/spotlight; spotlight disattivato in chiaro. Gli overlay non devono intercettare click. I callback hover ora vengono notificati solo quando cambia ingresso/uscita, e la posizione è salvata solo se lo spotlight è effettivamente usato.

Non aggiungere scorciatoie parallele per aggirare problemi del focus. Inventario in `Docs/Scorciatoie.md`; le vecchie prove native non certificano automaticamente la build attuale.

### Identità e temi

Scelto il concept **D con icona chiara**: due foglie/pagine e disco di luce. Il wordmark resta; Halloween mantiene la zucca scelta **B minacciosa**. Le viste leggono proprietà del pacchetto tema, non condizioni sul nome del tema. Token indipendenti per modalità Chiaro/Scuro/Sistema e tema; colori delle materie con ID semantici; font locali con licenze. Cifre decorative Halloween a celle fisse dove previsto.

### Ottimizzazione e commenti (build 14)

- Hover: eventi accorpati al refresh con display link sospeso a riposo, un osservatore per scroll container, geometrie locali riusate, scelta del target in un solo passaggio.
- Conteggi: StudyActivityCache confronta ID/Data esatti; SavedStudyTiming mantiene le regole originali come valori. Calendario, barre e serie leggono i modelli una volta per gruppo di calcoli. Non memorizzare totali senza una strategia affidabile di invalidazione.
- Sezioni: creazione alla prima visita, poi identità conservata. Cronologia filtra una sola volta per body.
- Focus: FocusControlsActivity pubblica solo mostra/nascondi e usa un solo task con scadenza monotona; tre binding di focus distinti.
- Audio: AmbientWaveform genera WAV deterministici fuori dal MainActor, controlla la cancellazione e non trattiene un array duplicato di campioni. La richiesta più recente ha la precedenza; i WAV sono identici alla baseline.
- Badge Dock aggiornato solo se cambia, ticker con tolleranza. Date, checkpoint, pause e completamenti non sono riscritti.

Commenti nel codice spiegano cache, geometria, lifecycle, snapshot e compatibilità legacy. Benchmark riproducibile: `Scripts/benchmark-release.py`, tre prove Release alternate e checksum uguali. I tempi misurano percorsi di codice, non FPS/CPU/watt dell’app. Dati e limiti nel rapporto build 14. Fetch, salvataggi SwiftData e import restano sul MainActor; le decorazioni non sono state sostituite senza prove.

### Lingue e testi (build 13)

In Impostazioni è disponibile Italiano/English, con `UserSettings.language` opzionale. `L10n` usa il catalogo `Sources/ThemeResources/Translations.json`, incluso in SwiftPM e Xcode. Le viste cambiano lingua senza essere smontate; i valori persistiti, le materie e le note mantengono gli ID/testi originali. Non applicare la traduzione ai dati scritti dall’utente. Alcuni pannelli nativi macOS adottano la lingua al riavvio; la lingua delle viste cambia subito. Testi motivazionali e toggle Testi a tema rimossi. Per nuove stringhe aggiornare il catalogo e usare `python3 Scripts/audit-localization.py` e `LocalizationTests`.

### Bugfix precedente: Statistiche e popover (build 12)

`StatisticsStudyChart` possiede selezione e animazione di ingresso. Il parent passa i bucket calcolati. Le date del cursore vengono risolte a un ID giorno/mese e pubblicate solo quando cambia. Il grafico non ha più uno spotlight aggiuntivo sul proprio rettangolo; il trattamento della card resta.

MenuPanel estende il fondo oltre le safe area; `MenuPanelWindowSurface` imposta fondo finestra e layer del contenuto opachi dal token. È applicato solo al pannello menu, non alla sidebar principale. Test con NSWindow di prova superati; **il vero contenitore MenuBarExtra non è ancora stato verificato visivamente dopo la correzione**.

## 7. Bug e verifiche aperte, per priorità

| Priorità | Problema / stato | Prossima verifica |
|---|---|---|
| Alta | Statistiche: lag molto forte al movimento del cursore. Causa nel codice individuata e patch nella build 12; risultato percepito non confermato | Riprodurre in Release con stessi dati/viewport, confrontare build 11 e 12, Time Profiler/SwiftUI/Animation Hitches |
| Alta | Bande trasparenti sopra e sotto il popover menu. Ricomparse nella build 11; patch nella 12 non ancora confermata nel vero host | Aprire MenuBarExtra con finestra principale nascosta, chiaro/scuro e cambio tema; contenuto corto/lungo e altezza schermo ridotta |
| Alta | CPU elevata durante scroll/click in Cronologia | Separare scroll, hover e click su fixture a 8 righe e su archivio grande; misurare Release |
| Alta | Timer e consumi con finestra coperta; memoria aumenta rispetto alla Cronologia ferma | Separare visibile/coperta e Decorazioni on/off; verificare clock, rendering e memoria stabilizzata, poi soak 30 minuti |
| Media | Regressioni native focus/hover/tastiera non concluse dopo le ultime patch | Matrice schermate × temi × modalità, riposo/hover/Tab, scroll/cambio sezione, scorciatoie e popover |
| Media | Recupero sessione e integrazioni di sistema non coperti dalla preview in memoria | Ambiente persistente separato, riavvio, finestra chiusa, sleep, menu, notifiche e Dock |
| Da valutare | Altri difetti estetici minori o vecchie proposte | Riprodurre e classificare prima di ampliarvi il lavoro |

Non risultano nuovi crash o perdite di dati accertati in queste ultime consegne; ciò non equivale a un audit completo di assenza di crash.

## 8. Misure disponibili: non confondere le baseline

Dati riferiti dall'utente per **Prova D, già Release**, Halloween, Mac dichiarato a 12 core (8P+4E), 24 GB; modello esatto e refresh effettivo non certificati:

| Scenario riferito | CPU | Thread | Memoria |
|---|---:|---:|---:|
| Cronologia ferma | 0,1% | 8 | 184 MB |
| Scroll/click in Cronologia, 8 righe | 64,5% | 13 | 310 MB |
| Timer attivo | circa 2,8–3%, picchi 10% | 7 | 290 MB |

Nel campione timer non sono specificati visibilità della finestra e stato Decorazioni. Non interpretare quei valori come quattro scenari già misurati o come medie di un intervallo noto. Non dividere arbitrariamente la CPU per il numero di core; documentare la convenzione dello strumento.

Dopo la build 11 l'utente ha riferito consumi da circa 6 W a 18–21 W durante l'hover sulle Statistiche, e da 5–6 W a 10–11 W nell'uso generale. Sono letture di sistema/sensore riferite dall'utente, non una misura isolata della potenza del processo. Non c'è ancora un confronto watt prima/dopo build 12.

Esiste un vecchio confronto controllato della sola Home Halloween, precedente a Prova D: 52,40% -> 10,65% CPU dopo il compositing della candela, circa 24 s per campione. È un risultato storico limitato, non prova delle prestazioni attuali dell'intera app. Le vecchie tabelle Fase A precedono anche l'isolamento del clock: non usarle come baseline build 12.

### Protocollo minimo richiesto per riprendere

1. Build Release identificata con build number, hash o UUID Mach-O; dati di test separati. Rilevare modello Mac, alimentazione, display e refresh; distinguere massimo ProMotion e frequenza effettiva.
2. Senza debugger; evitare cattura/condivisione schermo durante le misure quando possibile. Annotare altre app, luminosità, tema, decorazioni, timer e dimensioni finestra.
3. Profilare prima i problemi segnalati: Statistiche hover; Cronologia ferma/scroll/click; timer visibile/coperto con decorazioni on/off. Non fare un audit generico al posto di questi casi.
4. Raccogliere durata, CPU media/picco, wake-up, footprint/RSS con metrica dichiarata, invalidazioni SwiftUI, hitch e frame time, eventuale energia. Instruments può aggiungere carico: distinguere misure con/senza profiler.
5. Prima/dopo nello stesso ambiente. Un aumento iniziale di memoria può essere cache, font o superfici: verificare stabilizzazione e cicli ripetuti prima di dichiarare una perdita.
6. Target del proprietario: scroll CPU ben sotto 15%, timer coperto vicino a zero di lavoro visivo, nessun hitch percepibile. Altri target precedenti (<1% timer senza decorazioni, <3% Halloween con decorazioni; hitch ratio <5 ms/s) sono obiettivi da calibrare, **non risultati ottenuti**.
7. Mostrare cause misurate e piano per impatto/rischio prima di una nuova ottimizzazione ampia. Preservare la baseline visiva o concordare alternative.

## 9. Git, copie e materiali

La cronologia precedente a questo passaggio terminava in `e17445c`. Lo snapshot `59c337e` registra i lavori già consegnati della build 13; il commit successivo registra separatamente l’ottimizzazione build 14. Non è stata riscritta la cronologia. Gli identificativi esatti sono anche in `GIT-COMMIT.txt` della consegna.

Il vecchio blocco di scrittura di `.git/index.lock` appartiene all’ambiente precedente: è stato possibile creare i nuovi commit. Non leggere le note storiche sui permessi come stato attuale. Prima di iniziare controllare comunque `git status`, perché eventuali modifiche successive del proprietario devono essere preservate.

I documenti datati riportano numeri di test e limiti della propria consegna: in caso di divergenza usare sorgenti correnti, log più recenti e questo documento. Le patch in Dist possono essere incrementali rispetto a copie precedenti, non applicabili direttamente all'ultimo HEAD: leggere il rapporto prima di applicarle.

Non distribuire trace grezze o esportazioni complete del profiler senza revisione: possono contenere variabili d'ambiente, percorsi e informazioni personali. Il pacchetto di passaggio esclude archivi utente, cache di compilazione, prodotti temporanei e screenshot del desktop.

## 10. Primo giro consigliato a chi subentra

- Conservare snapshot e stato Git; aprire questo documento e il rapporto del bugfix build 12.
- Eseguire `swift test` e Release sul proprio ambiente, verificare i font e il bundle.
- Creare/verificare una build isolata con fixture; non aprire l'app ordinaria per i test.
- Confermare con il proprietario l'esito di Statistiche e bande nella build 12. Se persistono, acquisire riproduzione precisa e profiler sul percorso reale.
- Ripetere tastiera, area cliccabile, transizioni di visibilità, stato timer e riavvio nell'ambiente separato.
- Consegnare modifiche mirate, log/misure reali, commit riconoscibili e DMG separato. Annotare sempre ciò che resta da verificare.
