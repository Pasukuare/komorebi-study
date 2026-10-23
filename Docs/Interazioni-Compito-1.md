# Compito 1 — Anelli, hover e focus: candidato e punto di controllo

23 ottobre 2026. **Implementazione candidata, verificata automaticamente; compito non dichiarato terminato.** Mancano le prove native richieste e il commit. Compito 2 non avviato: nessuna nuova misura o ottimizzazione prestazionale viene dichiarata.

## Diagnosi: fatti dal codice e punti ancora da riprodurre

| Elemento / sintomo | Stato coinvolto | File prima della modifica | Causa accertata nel codice | Limite della diagnosi |
|---|---|---|---|---|
| Prima riga Cronologia: evidenziazione parziale e sporgenza | Hover sul contenuto; possibile focus nativo | HistoryView.swift; Style.swift / InteractiveHover | Hover applicato separatamente al bottone con SessionRow e ai due bottoni azione. Il rialzo di 1pt era attivo anche sul contenuto della riga. Il padding orizzontale apparteneva al solo contenuto e la separazione era affidata agli inset nativi della List. | Nel codice della riga non c’era un’ombra larga esplicita. Non è stato riprodotto il suo alone nativo: attribuzione a focus di sistema e misura dei circa 20px restano da verificare. |
| Impostazioni: Segui la stagione con contorno vicino al testo e giallo | Focus non distinto dall’input; spotlight sovrapposto fra Card e toggle | Controls.swift / StudyToggleStyle; Style.swift / Card, InteractiveHover, KeyboardFocusBorder | Il toggle non aveva padding orizzontale interno; Card e controllo potevano entrambi mostrare spotlight. La tinta dello spotlight proveniva dal token luce e restava attiva anche in modalità chiara. Il focus esplicito non distingueva mouse, tastiera e focus iniziale del sistema. | Il contorno esatto sul solo testo non è stato riprodotto in una finestra nativa; il file non contiene un anello aggiunto esplicitamente alla sola label. Non viene presentata un’ipotesi sul focus nativo come misura certa. |
| Toggle sidebar con anello staccato | Focus custom, non spotlight del pulsante | Style.swift / SidebarGhostToggle, KeyboardFocusBorder | Il ghost escludeva già lo spotlight. Il bordo custom dipendeva soltanto da FocusState, qualunque fosse l’origine; inset 3pt. L’assenza di distinzione fra focus iniziale, click e Tab è verificabile nel codice. | Non provato che macOS assegni sempre a questo pulsante il focus iniziale; nessun screenshot nativo in questa sessione. |
| Primo elemento/card delle altre sezioni, mouse altrove | Possibile focus iniziale nativo/custom; hover di Card e figli | RootView.swift; Style.swift; SubjectsView.swift; SettingsView.swift | Le sezioni restano vive nel loro ZStack; non esisteva una policy condivisa sull’origine del focus. Le Card non sono di per sé focusabili, ma hanno hover decorativo e possono evidenziarsi insieme ai controlli figli. Il vecchio onDisappear di InteractiveHover ripuliva il cursore, non il Bool hovering. | Il vecchio codice ripuliva già hovering al cambio di komorebiSectionVisible: non si dichiara provato un errore in quel singolo ramo. Focus iniziale realmente assegnato da macOS e persistenza durante scroll richiedono la prova pratica. |
| Dropdown e selettori | Selezione confusa con cursore di navigazione; bordi selezione/focus | Controls.swift; SubjectAppearance.swift; SettingsView.swift | La riga del dropdown era colorata dal cursore rowFocused, inizializzato alla voce selezionata e aggiornato con onHover senza ripulire la decorazione all’uscita. Le icone usavano lo stesso bordo per selezione e cursore. Alcuni selettori conservavano un bordo di selezione sotto quello di focus. | Corretto il modello visivo nel codice; percorso degli eventi e ritorno del focus non collaudati nativamente. |

Non è stato osservato dal vivo quale primo elemento riceva il focus in ciascuna schermata. Il codice dell’app non richiedeva esplicitamente il focus del primo controllo all’apertura delle cinque sezioni; parte dell’assegnazione può essere del sistema. L’assegnazione iniziale alla superficie della modalità Focus, usata per Esc, è conservata: non è un anello su un controllo e non si modifica quel percorso di navigazione.

## Correzioni candidate

1. **Focus unico da tastiera.** Sessione d’interazione per host finestra, inizialmente neutra. Solo Tab/frecce senza ⌘/⌃/⌥ abilitano il contorno; click lo disabilita. I monitor osservano e restituiscono l’evento, senza eseguire azioni o introdurre scorciatoie. All’attacco iniziale si richiede un responder vuoto, tranne la superficie Focus preesistente. Al cambio sezione si ripuliscono gli stati visivi, preservando il responder della sidebar per non interrompere sequenze di frecce. L’effettiva assegnazione del focus da macOS resta da controllare.
2. **Forma coerente.** KeyboardFocusBorder disabilita l’effetto di sistema e usa il token d’accento, 2pt, offset 2pt. Un’unica geometria gestisce rettangoli arrotondati, cerchi e capsule. Il raggio dei bottoni secondari segue il loro sfondo già esistente; i pallini colore conservano la forma circolare.
3. **Cronologia.** Estratta HistorySessionRow: un hover piatto e un focus esterno per tutta la riga, inclusi Modifica/Elimina. Tre target tastiera distinti, nessun hover individuale rialzato. Leading dei separatori allineato al contenitore, senza cambiare azioni, dati, menu contestuali o conferma di eliminazione.
4. **Toggle e campi.** Padding interno del toggle, hover piatto senza spotlight/rialzo. Campi testo, numeri, slider e dropdown usano la stessa policy. Lo stepper ha un solo contorno esterno per meno/valore/più; commit e limiti numerici restano quelli esistenti.
5. **Un solo proprietario dell’hover.** Un registro per host sceglie il bersaglio più piccolo/profondo sotto il puntatore, rispettando forma arrotondata e clipping. Card e controllo figlio non si illuminano insieme. La posizione aggiorna solo il proprietario, non viene pubblicata nell’ambiente. Una tracking area per finestra; probe locali solo per geometria e visibilità. I probe non intercettano hit o accessibilità. Lo stato viene ripulito a uscita, scroll, disattivazione, cambio sezione, rimozione e cambio d’identità del contenuto; riprende con movimento reale del puntatore.
6. **Luce e selezione.** Spotlight disattivato in chiaro e sulle righe, senza cambiare palette o superfici di riposo. Rimosso lo strato aggiuntivo di glow sfocato dell’hover. In scuro lo spotlight resta sottile sul solo proprietario. Selezione e focus sono distinti: il bordo di selezione cede al contorno tastiera dello stesso controllo, mantenendo contenuto e stato selezionati. Un controllo disabilitato conserva la propria selezione.

Non cambiate logica del timer, conteggi, schema, persistenza o navigazione. Nessuna nuova impostazione o libreria. Le Shape del marchio D e la zucca Halloween restano invariate. Le altre modifiche già presenti prima di questa richiesta sono conservate nella copia iniziale.

## Verifiche eseguite

- Suite completa: **107 test, uno saltato, zero errori**. Salto del fixture opzionale dell’archivio reale, mai sostituito dall’archivio personale. Nei log restano i messaggi dell’ambiente limitato sulla registrazione di notifiche CoreData; i test usano store in memoria.
- Nuovi test su focus iniziale/mouse/tastiera/disabled/visibilità; tasti di navigazione e modificatori; reset del contesto; unico proprietario del puntatore; clipping e angoli; swatch circolare; assenza di spotlight in chiaro e sulle righe; assenza di rialzo nelle liste; rispetto di Riduci movimento nella policy; selezione senza doppio contorno.
- Test pixel: con focus esplicitamente vero ma origine neutra o mouse il render coincide con quello senza anello; con origine tastiera differisce. È una verifica del renderer/policy, non dell’assegnazione del focus da parte del sistema.
- Sessanta render di componenti: cinque campioni associati a Home, Timer, Materie, Cronologia, Impostazioni × due temi × chiaro/scuro × riposo/hover/tastiera. I dati e gli stati sono di test. Le immagini sono etichettate **stato forzato, non UI nativa**. Non sono schermate complete né screenshot prima/dopo. Un iniziale segnaposto giallo di ImageRenderer per NSViewRepresentable è stato reso trasparente nei probe senza artwork; non viene confuso con il sintomo dell’app reale.
- Build Release separata e verifica di firma ad hoc; log allegati. `git diff --check` riuscito.

## Verifiche NON eseguite: bloccano la conclusione richiesta

Lo strumento di controllo UI non è disponibile. La precedente istruzione di saltare CUA riguardava il lavoro precedente: questa nuova richiesta richiede prove native e non viene considerata automaticamente soddisfatta dai render.

Non eseguiti: screenshot reali prima/dopo delle cinque schermate nei quattro abbinamenti tema/modalità, mouse fuori finestra, hover, Tab; focus effettivo iniziale; anello nativo residuo; area reale della prima riga e separatori; hover fermo mentre scorre o cambia contenuto; ritorno del focus da popover; sequenze di frecce sidebar e scorciatoie nell’host reale. Non si dichiara verificata l’intera app soltanto perché compila.

Il filesystem mantiene `.git` in sola lettura; un nuovo commit non è stato creato. La cronologia non è riscritta. Copia datata prima/dopo e patch incrementale sono incluse. Il working tree iniziale conteneva già i lavori precedenti: la patch di questo compito è relativa alla copia iniziale, non al vecchio HEAD, per non mescolarli.

## Checklist nativa riproducibile per completare il controllo

Usare soltanto **Komorebi-Prima-Prova.app** e **Komorebi-Dopo-Prova.app**, entrambi con bundle preview e archivio in memoria. Non avviare l’app ordinaria né quella in Applicazioni per queste prove. Le preferenze di ogni avvio sono isolate; i fixture sono uguali. Font, asset e build di riferimento sono conservati nei bundle.

Per ciascuno di Komorebi chiaro, Komorebi scuro, Halloween Pergamena e Halloween scuro:

1. Stessa dimensione di finestra nei due bundle. In Home, Timer, Materie, Cronologia e Impostazioni spostare il mouse realmente fuori dalla finestra, quindi catturare il riposo: nessun primo controllo deve avere alone o focus. Ripetere dopo cambio sezione, riapertura e cambio tema.
2. Posare il mouse sul primo elemento e poi sui suoi figli: una sola superficie evidenziata. In Cronologia provare testo, durata, padding, modifica e cestino: evidenziazione della riga intera, niente rettangolo sollevato parziale; confrontare i bordi con i separatori. Verificare anche click e cursore sugli angoli secondo la forma visibile.
3. In Impostazioni verificare Segui la stagione: contorno con spazio attorno alla label e switch, nessun giallo in chiaro. Provare selettori icona/colore/tema: selezione persistente, nessun doppio bordo durante il focus.
4. Tab e Shift-Tab: un solo anello d’accento a 2pt con offset 2pt, forma dell’intero controllo. Dopo click del mouse l’anello sparisce. Frecce nelle sequenze sidebar, dropdown, palette e segmenti; ritorno dal popover con Esc/Invio; campo numerico con modifica diretta, meno/più e validazione.
5. Con hover attivo, scorrere la lista, cambiare sezione, modificare/eliminare un fixture, minimizzare e riaprire: nessuna evidenziazione sulla vecchia riga. Le decorazioni non devono bloccare i pulsanti. Riferire se l’hover riprende solo con movimento del puntatore, come previsto.
6. Provare anche Riduci movimento e controlli disabled. Ripetere ⌃⌘S, ⌘Invio, ⇧⌘P, ⌘., Focus/Esc e input testuale, senza sessioni reali. Sono prove di regressione richieste, non già eseguite in questo compito.

Per la sporgenza dichiarata di ~20px: screenshot dello stesso viewport e scala, confrontare il limite sinistro/destro dell’evidenziazione con quello dei separatori, distinguendo punti logici e pixel Retina. Per il focus iniziale serve osservare la prima pressione di Tab e gli anelli prima di ogni input; il solo screenshot statico non dimostra il responder interno.

## Consegna e file

Candidato ordinario separato: Komorebi-Interazioni-Candidato.app. Se aperto usa l’archivio normale; **non è stato avviato**. Per confrontare usare solo i due bundle Prova in memoria. Nessuna sostituzione in Applicazioni.

File di questo compito: Sources/Components/Style.swift, Sources/Components/Controls.swift, Sources/Components/SubjectAppearance.swift, Sources/Views/HistoryView.swift, Sources/Views/SubjectsView.swift, Sources/Views/SettingsView.swift, Sources/Views/RootView.swift, Sources/KomorebiApp.swift; nuovi Tests/InteractionStateTests.swift e Docs/Interazioni-Compito-1.md. Nessun file dati, modello o servizio timer modificato da questo compito.

**Punto di controllo 1:** codice e test automatici consegnati; conclusione sospesa per prove native e commit mancanti. Non scrivo “COMPITO 1 TERMINATO”. Nessuna fase del compito 2 avviata e nessuna promessa su CPU, energia, FPS o hitch.
