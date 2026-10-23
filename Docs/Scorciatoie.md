# Compito 3 — Inventario e checklist delle scorciatoie

Data: 23 ottobre 2026. Prove native su bundle `com.komorebi.study.preview.cards.compact` (baseline) e `com.komorebi.study.preview.shortcuts.compact` (correzione). Entrambi usano archivio in memoria e preferenze temporanee. L'app in Applicazioni e il suo timer non sono stati azionati. La suite automatica verifica regressioni di dati/timer/temi, non sostituisce le prove tastiera.

## Inventario completo dei gestori definiti dall'app

| Comando / tasti | Definizione | Esito delle prove |
|---|---|---|
| Vista: mostra/nascondi sidebar, ⌃⌘S | `KomorebiApp.swift`, CommandGroup sidebar | Funziona nella finestra, nel campo Nome, con menu Vista e con dropdown aperti. Disabilitato in Focus come previsto. |
| Studio: avvia, ⌘Invio | `KomorebiApp.swift`, CommandMenu Studio | Funziona nei quattro contesti della matrice sotto. Disabilitato quando una sessione è già attiva. |
| Studio: avvia/pausa/riprendi, ⇧⌘P | `KomorebiApp.swift`, CommandMenu Studio → store.toggle | Pausa e ripresa verificate nella finestra, nel menu aperto, nel dropdown e in Focus. `toggle` avvia anche da fermo: comportamento esistente conservato, coerente con il testo in Impostazioni. |
| Studio: termina, ⌘. | `KomorebiApp.swift`, CommandMenu Studio | Funziona nei quattro contesti, apre il riepilogo; disabilitato senza sessione. |
| Focus: Esc | `RootView.swift`, pulsante con keyboardShortcut, onKeyPress e onExitCommand della stessa vista | Uscita verificata. Più ingressi dichiarativi preesistenti per la stessa azione idempotente; non aggiunti gestori paralleli. |
| Focus: Tab | `RootView.swift`, onKeyPress | Provato: controlli visibili. Il passaggio effettivo del focus ai singoli pulsanti non è stato confermato dall'albero AX; non dichiarato superato. |
| Riepilogo: Invio / defaultAction | `RootView.swift`, Continua | Chiude il riepilogo anche con focus nel campo Nota, verificato ripetutamente. |
| Sidebar: Spazio sul toggle | `Style.swift`, SidebarGhostToggle | Verificato: un solo cambio di stato. Nessuna azione sullo Spazio scritto nel campo Nome. |
| Sidebar: ↑/↓ nel contenitore | `RootView.swift`, onMoveCommand | Inventariato; percorso specifico non collaudato in questa sessione. |
| Dropdown: ↓ o Invio per aprire; ↑/↓, Invio/Spazio per scegliere; Esc per annullare | `Controls.swift`, StudyDropdown | Apertura con mouse e navigazione ↓/Invio/Esc provate su Ambiente e Materia. Selezione Pioggia e ritorno del focus al campo verificati. Apertura con ↓ e scelta con Spazio inventariate, non provate singolarmente. |
| Icone: Invio/Spazio per aprire e confermare, frecce nella griglia, Esc per annullare | `SubjectAppearance.swift`, SubjectIconPicker | **Difetto riprodotto e corretto**. Shift-Tab dal Nome raggiunge l'icona; Invio apre, ↓/Invio seleziona Tavolozza, →/Spazio seleziona Musica, ←/Esc annulla, Tab ritorna al Nome. |
| Colori: ←/→, Invio/Spazio | `SubjectAppearance.swift`, SubjectColorPicker | Salvia → Azzurro polvere con freccia e Spazio verificato. Invio usa la stessa assegnazione; non provato separatamente. |
| Tab palette: Invio/Spazio | `SubjectAppearance.swift`, ColorGroupTab | Tab dal Nome raggiunge Classici; Invio cambia tab, verificato. Spazio non provato separatamente. |
| Tema: Invio/Spazio sulla card | `SettingsView.swift`, ThemePreviewCard | Inventariato; selezione della card da tastiera non collaudata in questa sessione. |
| Stepper: ↑/↓ e Invio per confermare | `Controls.swift`, StudyNumberField | Minuti 25 → 26 → 25 verificati; chip e tempo si aggiornano. Invio nel campo Nome non avvia sessioni. Submit numerico inventariato, non provato separatamente. |
| Segmented: ←/→ | `Style.swift`, PastelSegmentedControl | Inventariato; percorso specifico non collaudato in questa sessione. |
| Volume: frecce, incremento/decremento di 0,05 | `Style.swift`, StudyVolumeSlider | Inventariato; percorso specifico non collaudato in questa sessione. |
| Calendario: Esc per nascondere dettaglio della cella | `CalendarView.swift`, CalendarDayCell | Inventariato; percorso specifico non collaudato in questa sessione. |
| Monitor locale: frecce, Invio, Spazio, Esc, Enter tastierino | `Controls.swift`, PopoverKeyboardCapture; callback in dropdown e icone | Un solo tipo di monitor condiviso; installato quando la NSView entra in finestra e rimosso al distacco. Ignora ⌘/⌃/⌥. Non esistono monitor globali. Enter del tastierino non provato. |

I gestori onMoveCommand/onKeyPress sono locali al controllo o al suo sottoalbero, non scorciatoie globali a tasto singolo. I normali Button continuano a ricevere l'attivazione standard macOS dove il sistema abilita la navigazione tastiera.

Vista contiene anche le voci di sistema “Mostra la barra dei pannelli”, “Mostra tutti i pannelli”, “Attiva modalità a tutto schermo”: sono generate da SwiftUI/AppKit, non definite con keyboardShortcut nell'app. Le equivalenze tastiera di queste voci non sono esposte dallo strumento AX utilizzato; non sono state indovinate né rimappate. ⌘N è stato provato: apre una seconda finestra della stessa istanza di test. ⌘Q chiude la sola istanza di prova. Le altre scorciatoie standard File/Modifica/Finestra non sono state collaudate sistematicamente.

## Matrice dei quattro comandi applicativi

| Contesto | ⌃⌘S | ⌘Invio | ⇧⌘P | ⌘. |
|---|---|---|---|---|
| Finestra principale | Mostra/nasconde | Avvia | Pausa e riprende | Riepilogo |
| Campo Nome in Materie | Mantiene testo e focus | Avvia | Pausa | Riepilogo |
| Menu Vista/Studio aperto | Voce cambia Mostra/Nascondi | Avvia diventa disabilitato | Riprende, poi stato confermato in Timer | Termina diventa disabilitato; riepilogo dopo chiusura menu |
| Popover custom aperto | Sidebar cambia senza perdere scelta | Avvia | Sessione sospesa | Riepilogo |

Sono stati provati i popover custom della finestra. **Il popover MenuBarExtra della barra dei menu non è stato collaudato**, per il limite dello strumento già documentato nel compito 2. Non si attribuisce la stessa verifica al suo diverso host nativo.

## Difetto corretto e causa

Prima: aprire Icona della materia su Libro aperto, premere ↓, quindi Invio. Il valore resta Libro aperto; nel popover le voci risultano disabilitate nell'albero AX. Anche Shift-Tab dal campo Nome salta il pulsante icona.

Causa nel componente: `focusedIcon` era un FocusState legato a ogni pulsante della griglia e veniva usato anche come cursore di selezione dal monitor AppKit, quando il focus restava sul controllo esterno. Il pulsante che apre il popover, invece, non dichiarava la capacità di ricevere focus da tastiera. Il solo trasferimento del binding al callback non risolveva la riproduzione.

Correzione: il cursore della griglia è State ordinario, distinto dal focus nativo. Rimossi i collegamenti che forzavano il focus sui pulsanti della griglia; il pulsante di apertura ora è focusable, ha un focus visibile e riceve Invio/Spazio senza modificatori tramite un'unica azione condivisa. Dopo la chiusura il focus torna al pulsante. Nessun nuovo monitor e nessuna nuova scorciatoia globale. Colori, geometrie e dati non cambiano.

Dopo: ripetuta la stessa sequenza Libro aperto → ↓ → Invio, valore Tavolozza. Screenshot e tracce AX prima/dopo nella copia datata del compito. Verificati anche →/Spazio, ←/Esc, Shift-Tab/Invio e ritorno con Tab. I comandi Studio funzionano con il popover icona aperto senza venire assorbiti dai suoi Invio/Spazio.

Il problema generale “nessuna scorciatoia funziona” **non si riproduce nei sorgenti attuali**. Non è stata identificata una causa di quel comportamento su una diversa app installata, che non è stata azionata per proteggere l'archivio personale. Non sono stati modificati i comandi principali che funzionano.

Il monitor locale controlla la visibilità, non la corrispondenza event.window. È un punto da approfondire: con ⌘N e passaggio a una seconda finestra non è stata riprodotta una sottrazione dei tasti. Nessuna modifica preventiva a quel percorso.

## Checklist riproducibile

Usare esclusivamente la build di prova con bundle `com.komorebi.study.preview.shortcuts.compact`: archivio in memoria, eliminato alla chiusura. Non utilizzare l'app personale.

1. Home: ⌃⌘S due volte; sidebar si chiude e riapre una sola volta per comando. ⌘Invio avvia una sessione. ⇧⌘P sospende, una seconda pressione riprende. ⌘. apre Sessione salvata. Invio chiude il riepilogo.
2. Materie: mettere il focus in Nome, digitare con tasti reali `p`, Spazio, `s`, Spazio, Invio. Il testo deve restare `p s `; nessuna sessione e nessuna nuova materia. Ripetere i quattro comandi modificati della riga precedente mantenendo il focus nel campo e controllare lo stato in Home/Timer.
3. Menu: aprire Studio, ⌘Invio; Avvia deve risultare disabilitato. ⇧⌘P, chiudere il menu e controllare Sessione sospesa; ripetere per ripresa. Aprire Studio e premere ⌘.; Termina disabilitato e riepilogo. Aprire Vista e premere ⌃⌘S; la voce deve cambiare titolo.
4. Timer: aprire Ambiente; ↓, quindi Invio deve selezionare Pioggia. Riaprire, Esc annulla. Con un dropdown aperto ripetere i comandi della matrice; nessun doppio comando o perdita della scelta.
5. Materie: da Nome, Shift-Tab → Icona. Invio apre. Da Libro aperto, ↓, quindi Invio → Tavolozza. Riaprire, →, quindi Spazio → Musica. Riaprire, ←, Esc → resta Musica. Dopo chiusura, Tab → Nome. In automazione attendere lo stato UI dopo ogni freccia prima di confermare; sequenze sintetiche senza ciclo di rendering non sono una verifica affidabile.
6. Dal Nome, Tab → Classici, Invio → tab Classici. Focus su Salvia, →, Spazio → Azzurro polvere.
7. Timer fermo: focus sui minuti, ↑ → 26, ↓ → 25; numero grande e chip seguono il valore.
8. Focus: iniziare/sospendere sessione, entrare in Focus, ⇧⌘P deve riprendere. Esc deve tornare al Timer; ⌃⌘S in Focus non deve cambiare lo stato della sidebar. Verificare separatamente la traversabilità dei singoli controlli Focus con la navigazione tastiera di sistema attiva: prova non conclusa in questa sessione.
9. Completare manualmente i percorsi ancora non collaudati indicati nell'inventario: card tema, segmenti, slider, frecce sidebar, dettaglio Calendario, apertura dropdown con ↓ e conferma con Spazio, Invio numerico e tastierino.
10. Quando lo strumento rende accessibile MenuBarExtra: ripetere i comandi nel popover reale e dopo chiusura della finestra principale. Questa verifica resta pendente insieme al compito 2.

Comando di regressione: `swift test --disable-sandbox --filter` con il nome della suite pertinente oppure `swift test --disable-sandbox` per l'intera suite. La verifica manuale delle scorciatoie richiede l'app bundle: i test del modello non dimostrano il percorso degli eventi macOS.
