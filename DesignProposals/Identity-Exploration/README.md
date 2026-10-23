# Komorebi — esplorazione dell’identità

Fase 1: proposte, non implementate nell’app. Halloween conserva la zucca B, il wordmark resta invariato e l’icona Dock attuale non è stata modificata.

Apri tavola.html per vedere le dimensioni reali: marchio 128/32/16 px, su chiaro e scuro; icone da master SVG 1024×1024 ridotte a 128 e 32 px. tavola.png è il confronto completo renderizzato nel browser.

- A — Foglia con sole: lente ottenuta da due archi circolari e disco di luce in negativo. Ammesso a 16 px. La direzione consigliata per il legame immediato con il nome.
- B — La k che germoglia: monogramma serif costruito con rettangoli, un poligono semplice e una foglia a lente inclinata. Ammesso a 16 px: resta la k, la foglia è un dettaglio secondario.
- C — Chioma di luce: tre foglie traslucide ruotate in cerchio, sovrapposizioni più luminose. Scartato: a 16 px sembra un’elica.
- D — Un raggio tra le foglie: foglia e fascio diagonale in negativo. Scartato: a 16 px la silhouette si frammenta.
- E — Clessidra di luce: due coppe circolari contrapposte, una foglia in negativo e un piccolo grano di luce. Ammesso a 16 px: riconoscibile come clessidra, richiamo al tempo di studio.

File: marchio-A.svg … marchio-E.svg (monocromatici, currentColor, intagli trasparenti); icona-A-1024.svg … icona-E-1024.svg (master di esplorazione); tavola.html e tavola.png.

Geometria semplice, senza disegno libero: archi di cerchio, cerchi, rettangoli e poligoni; orientamenti 35°/45° e distribuzione a 120° delle tre foglie. Ogni forma rimane entro circa dodici punti di controllo. Nessun font richiesto per il monogramma, nessuna immagine raster incorporata negli SVG, nessuna dipendenza esterna.

La valutazione a 16 px è visiva, non una misura automatica di riconoscibilità. I concept scartati restano nella tavola per rendere confrontabili tutte e cinque le richieste.

Fase 2 in attesa della scelta: rifinitura del solo concept selezionato, integrazione tramite logoMark nel tema Komorebi, AppIcon completo e livelli separati se pertinenti, build separata e prove nel Dock chiaro/scuro. Nessuna di queste operazioni è stata anticipata.
