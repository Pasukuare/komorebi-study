# Compito 5 — Fase 1: proposte, in attesa della scelta

23 ottobre 2026. Nessun marchio o icona sostituiti nell’app o nel Dock. Il wordmark e la zucca Halloween non sono modificati. Il compito 5 non è terminato: la fase 2 richiede la scelta dell’utente.

Aprire tavola.html oppure tavola.svg. La tavola PNG è un render locale delle proposte, non uno screenshot dell’app. I simboli sono collocati a 128, 32 e 16 pixel nella tavola SVG; se il visualizzatore ridimensiona l’intera tavola, usare zoom 100% per giudicare le dimensioni reali. Per ogni concept sono inclusi il marchio normale e piccolo, il master icona SVG 1024 e le riduzioni SVG 128/32. Tutti sono vettoriali: nessuna bitmap incorporata; il PNG serve solo da anteprima.

- **A — Canfora e luce.** Lente geometrica inclinata di 35°, disco parzialmente coperto, intervallo trasparente. La nervatura è un piccolo intaglio a lente, omesso a 32/16px. Il disco monocromatico usa opacità 60%. Proposta più vicina al significato letterale di komorebi.
- **B — Il sole lascia una foglia.** Disco con intaglio di una lente inclinata di 45°. La sottrazione resta leggibile in piccolo, ma il riferimento alla foglia è più astratto: è la proposta meno descrittiva.
- **C — Albero luminoso.** Disco sopra un albero geometrico a due livelli, con rami e tronco arrotondati. Un ideogramma visivo originale; non è un glifo 杲 né una riproduzione calligrafica.
- **D — Tra due pagine.** Due lenti inclinate di ±35°, come foglie e pagine di un libro. Il vuoto centrale e il sole collegano studio e luce senza un libro letterale.

Controllo dei render: geometrie distinte mantenute nelle riduzioni a 16px, nessuna variante eliminata per perdita completa della silhouette. Questo giudizio riguarda il marchio renderizzato nella tavola, non il riconoscimento da parte di utenti o la resa in un Dock reale. A e D rendono più esplicito il legame con le foglie; B rimane intenzionalmente più astratto. A/B sono stati corretti dopo che il renderer locale non mostrava correttamente le maschere annidate delle icone: ora gli intagli usano tracciati even-odd e clip vettoriali, verificati nel render finale.

Geometria: cerchi, archi circolari che delimitano le lenti, segmenti, rotazioni 35°/45°. Ogni forma ha pochi punti di costruzione; niente tracciati a mano libera, fotografie, emoji, loghi o elementi di film/anime. Icone: squircle con gradiente #14211E → #6F9A8F, marchio #FBF6E6, luce #F6D58E, bloom e grana deterministica al 2,5%. Il generatore Python è incluso e riproducibile. Il rendering è stato eseguito con AppKit, non pilotando l’interfaccia.

## Passi riservati alla fase 2

Solo dopo scelta: implementazione del logoMark e versione ridotta, AppIcon completo, verifica nei Dock chiaro/scuro, build separata e scheda di stile definitiva. L’opzione di saltare le prove manuali vale per questa sessione; gli screenshot del Dock non vengono inventati. Il master selezionato potrà essere rifinito senza cambiare direzione.

Non è stato scaricato o incorporato un font Mincho: la verifica della licenza OFL, la conversione in contorni di 木漏れ日 e la scheda di stile definitiva fanno parte della fase 2. Non è stato usato un font sostitutivo fingendo che sia quello scelto.

Proposta per il rapporto, non implementata: un singolo passaggio luminoso sul ring a fine sessione potrebbe riprendere la diagonale dell’icona, senza loop e disabilitato con Riduci movimento. Richiede approvazione separata se desiderato.

Nessun commit del compito 5 ancora previsto: la fase esplorativa attende una scelta. I file sono consegnati nella cartella di progetto e in uno ZIP datato. Per il compito 4 il commit resta bloccato da .git in sola lettura; sorgenti e patch sono conservati separatamente.
