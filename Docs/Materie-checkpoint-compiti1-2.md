# Materie — punto di controllo dopo i compiti 1–2

Il prompt corrente contiene sette compiti: questa consegna riguarda solo i primi due. Compiti 3–7 sospesi fino a CONTINUA. Nessuna migrazione o apertura dell’archivio personale; nessuna sostituzione in Applicazioni.

## Compito 1 — pulsanti disabilitati

Causa: ResponsiveButtonStyle cambiava il testo/opacità senza sostituire il fondo d’accento; StudyActionStyle conservava bordo, ombra e attenuazione globale; il ghost non aveva una superficie disabilitata dedicata.

Tutti e tre gli stili condivisi (azione principale, responsive primario/secondario/distruttivo, ghost sidebar) ora usano superficie neutra e testo/icona terziari da token, senza doppia attenuazione, accento, shadow o scala da pressed. Le sonde pointer e gli anelli di focus sono già esclusi quando isEnabled è false. La nota «Inserisci un nome per aggiungere la materia» è visibile sotto il pulsante in assenza del nome, localizzata in inglese.

L’audit ha rilevato anche contrasti bassi negli stati attivi: distruttivo pressed in chiaro (minimo iniziale 4.12:1), distruttivo hover su superficie elevata in scuro (4.05:1), action hover scuro al centro dello spotlight (4.485:1). Corrette solo le tinte dei pulsanti coinvolti, con token separato buttonDestructiveInk e correzione del riempimento hover. Gli altri testi distruttivi e gli stati normali estranei ai pulsanti non cambiano. Il test di baseline ora esclude la vecchia uguaglianza del solo actionHover, sostituita dall’audit numerico esplicito di tutti gli stati.

I token sono risolti alla costruzione delle varianti tema, non nei body dei pulsanti né durante hover. Nessun timer o animazione continua aggiunti.

Verifica: CSV di 360 campioni, quattro combinazioni tema/modalità, cinque stili, default/hover/pressed/focus/disabled e anello di focus, su tre superfici. Soglie: testo attivo 4.5:1, disabilitato 3:1, anello 3:1. Lo script `Scripts/audit-button-states.py` verifica valori e copertura del CSV prodotto da XCTest dai token Swift effettivi.

## Immagini e limiti

Prima/Dopo sono render ImageRenderer fuori schermo di Materie, editor e tavola dei pulsanti, con archivio in memoria: non screenshot dell’app in uso né prova nativa di hover/focus/tastiera. Nessun accesso CUA nativo disponibile in questa sessione. I controlli basati su AppKit possono avere resa diversa da questi render. Le prove reali, da eseguire sul Mac con dati di test, saranno riportate nel riepilogo del checkpoint.

## Compito 2 — editor della materia

- Conservato SubjectFormFields unico per creazione/modifica. SubjectPaletteTabs è condiviso e usa due alternative orizzontali: etichette complete, oppure icone con etichetta solo sulla tab selezionata. Nessun fallback verticale.
- Il selettore in modifica inizializza subito la tab dal colore assegnato, prima di onAppear; in creazione restano le regole stagionali del tema.
- Larghezza 520 pt; altezza complessiva limitata a circa l’80% dell’area contenuto della finestra madre, con header/footer misurati. Un observer di resize/presentazione aggiorna il limite, senza timer o aggiornamenti per movimento del mouse.
- Titolo e pulsanti erano già fuori dallo ScrollView nella baseline: conservata questa separazione. Scorre soltanto il corpo, ridotto alla sua altezza naturale se entra. Riservati 24 pt sul lato destro per la barra overlay. La misura del corpo cambia solo con layout/contenuto.
- Anchor iniziale in cima e ripristino esplicito in cima alla prima presentazione. Nessun focus assegnato ai campi; alla prima associazione alla sheet vengono azzerati initialFirstResponder/firstResponder. Le presentazioni/resize successive non cancellano il focus acquisito dall’utente.
- Esc/Invio mantengono le azioni cancel/default esistenti; il salvataggio resta condizionato dalla validità del form. Non sono state modificate regole del voto o dati: quelle appartengono ai compiti 3–4.
- Durante l’integrazione del form sono stati uniformati ai token disabilitati anche i piccoli pulsanti −/+ dello stepper; il contenitore non impone più il cursore mano sulle porzioni disabilitate e non attenua globalmente il testo.

## Risultati del checkpoint

- Compito 1: 146 test Release, uno saltato per fixture facoltativa di migrazione, nessun errore. Audit: 360/360 campioni superati. Commit df9e2a6.
- Compito 2 e regressioni: 148 test Release, uno saltato, nessun errore. Cinque tab × due lingue × due temi × due modalità verificati a una riga (44 pt) alla larghezza utile minima. Test dell’altezza a 650/790/1000 pt e con chrome di due altezze. Test editor con nome lungo, completata/voto e quattro combinazioni tema/modalità.
- Contrasti minimi finali: disabled 4.974:1 (soglia 3); default 5.116:1; hover 4.504:1; pressed 4.507:1; focus 5.116:1; anello focus 6.527:1 (soglia 3). Sono contrasti dei token e del punto più intenso dello spotlight, non una misura del monitor fisico.
- Audit localizzazione: 446 voci inglesi, 322 chiavi letterali/plurali, superato.
- Build Xcode Release 1.8 (20), firma ad hoc e checksum DMG verificati. Nessuna notarizzazione Apple.

## Confronti acquisiti

Le immagini finali Prima/Dopo sono catture native offscreen con NSHostingView, NSWindow non mostrata e cacheDisplay, non screenshot di una finestra usata interattivamente. Prima ricostruita dai sorgenti del commit 9467553 (build 19) in una cartella temporanea, con la stessa fixture e lo stesso acquisitore del Dopo. I primi render ImageRenderer intermedi non sono usati nel confronto finale perché non mostravano il corpo dello ScrollView.

Dodici coppie: Materie, editor e tavola pulsanti, ciascuno in Komorebi/Halloween chiaro/scuro. Nessun click o tasto sintetico inviato all’app personale. I log possono riportare gli avvisi FocusState noti dei test ImageRenderer: non costituiscono una verifica del focus reale.

### Prove ancora da eseguire sul Mac

Usare la build Prova in memoria separata (le modifiche si azzerano alla chiusura), oppure un archivio di test:

1. Aprire Materie a finestra minima; verificare pulsante Aggiungi vuoto, motivo, colore leggibile e cursore normale. Scrivere un nome e confrontare stato attivo.
2. Scorrere in fondo e premere Modifica: l’editor deve mostrare icona/nome e tab corrente in cima, senza anello iniziale.
3. Selezionare tutte e cinque le tab; confermare riga unica, tooltip/etichette accessibili, selezione e popover icone.
4. Scorrere il corpo: titolo e Annulla/Salva devono restare fermi e la barra non deve coprire stepper, toggle o voto.
5. Ridimensionare la finestra madre; provare nomi lunghi e voto. Tab deve mostrare un solo focus; Invio salva solo con nome valido; Esc annulla, prima chiudendo eventuali popover aperti.
6. Ripetere in Italiano/English e nelle quattro combinazioni tema/modalità; provare VoiceOver e Riduci movimento.

Queste prove native, accessibilità, posizione reale dello scroll durante presentazione e focus da tastiera non sono dichiarate superate. Nessuna misura CPU/GPU effettuata. Il codice evita polling/animazioni continui; questo non certifica un dato energetico sul Mac dell’utente.

## Decisioni prudenti

- Il testo contiene «quattro»/«tre compiti» ma ne enumera sette: si segue la numerazione 1–7, con stop esplicito dopo il 2.
- Opzioni media voti e nuovo popover Home non implementate.
- Nessuna migrazione, data o voto ricostruiti a questo checkpoint. Nessun backup personale creato perché nessun archivio personale è stato aperto/modificato; il backup datato verrà eseguito prima della migrazione del compito 3, dopo CONTINUA.
- Non anticipati i nuovi filtri delle materie completate, le sezioni Da completare/Completate o la capitalizzazione: restano nei compiti 3–7.

## File modificati

Compito 1: Sources/Components/Style.swift; Sources/Components/Themes.swift; Sources/Views/SubjectsView.swift; Sources/ThemeResources/Translations.json; Tests/SubjectPolishTests.swift; Tests/ThemeTests.swift; Scripts/audit-button-states.py; questo rapporto.

Compito 2: Sources/Components/Style.swift; Sources/Components/SubjectAppearance.swift; Sources/Components/Controls.swift; Sources/Views/SubjectsView.swift; Tests/SubjectEditorTests.swift; Tests/SubjectPolishTests.swift; Komorebi Study.xcodeproj/project.pbxproj; Docs/PASSAGGIO-PROGETTO.md; questo rapporto.
