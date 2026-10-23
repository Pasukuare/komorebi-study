# Komorebi — D, tra due pagine

Scelta approvata il 23 ottobre 2026. Icona chiara approvata al posto della proposta scura iniziale. La direzione è luce che attraversa due foglie/pagine, con geometria originale e pochi elementi.

## Marchio

Due lenti circolari su una griglia di 128 unità: raggio 56, estremi verticali ±44, scala 0,76; posizioni (35,73) e (93,73), rotazioni −35°/+35°. Disco a (64,28), raggio 14, opacità 60%. Il vuoto centrale resta trasparente. Nessuna figura, simbolo o elemento ripreso da film/anime; nessun ideogramma nel marchio.

Il marchio è già minimale: la versione piccola mantiene solo due lenti e disco, senza nervature o contorni da perdere sotto i 32px. SVG normale e piccolo forniti separatamente per l’uso negli strumenti grafici. Le Shape SwiftUI conservano la stessa costruzione; il viewport ottico in-app stringe il margine del master, senza deformare il disegno, per conservare altezza e centro visivo rispetto alla foglia precedente.

Token: `ThemeRegistry.packages[0].logoMark = .pagesAndLight`. Risorsa: `ThemeLogoMark.Artwork.pagesAndLight`. Tint: `ThemeLogoMark.colorToken`, attualmente `.accent`; disco: `ThemeLogoMark.discOpacity = 0.6`. Non usare un esadecimale nelle viste. Segui la stagione risolve il medesimo tint tramite la palette del tema. Halloween mantiene `.jackOLantern` e i relativi glow. Il cambio passa dalla dissolvenza del tema già esistente; nessuna nuova animazione.

Il wordmark “komorebi” resta con il font e il testo attuali. Non ricostruirlo nel file dell’icona e non aggiungerlo al Dock. Non cambiare icone di materie, serie o azioni per farle assomigliare al marchio.

## Palette e icona chiara

Palette di riferimento richiesta: #14211E verde bosco; #6F9A8F salvia; #A9C9C4 foschia; #FBF6E6 crema; #F6D58E luce. La variante chiara approvata usa #EEE6D6 → #FBF6E6 per lo sfondo, #14211E per le foglie, stesso colore al 60% per il disco. Bordo verde al 9%: aiuta il profilo su Dock chiaro senza un contorno vistoso. Un raggio diagonale quasi bianco passa da alto-destra a basso-sinistra; la tinta di riferimento per la parte calda resta #F6D58E. Grana fine deterministica al 2,5%, seed 17.

Il marchio scuro sul crema sostituisce il bloom chiaro previsto per la precedente icona scura: il riferimento approvato chiede un segno verde netto, non una sagoma luminosa crema. Nessuna impostazione di tema nuova; questa è l’unica icona installata nel bundle. Master SVG/PNG 1024, icns, iconset e appiconset completi. Livelli SVG separati: sfondo, foglie, luce e grana. Il progetto usa il normale AppIcon.icns, non un progetto Icon Composer; i livelli sono pronti per importazione, senza introdurre una pipeline diversa.

## Gesto firma

La luce è un intervallo: il vuoto tra le foglie e il disco attenuato. Conservare il centro e l’inclinazione; non aggiungere occhi, facce, germogli minuti o effetti a ripetizione. La luce diagonale appartiene all’icona e agli asset di riferimento, non viene aggiunta alle schermate esistenti.

Proposta non implementata: un solo passaggio luminoso sul ring a fine sessione potrebbe riprendere questa diagonale. Deve restare un evento breve, disattivato con Riduci movimento. Non è incluso nelle modifiche all’app.

## Uso di 木漏れ日

Destinato solo a materiale di riferimento o composizioni di altezza almeno 24pt; non applicato alle schermate. Font indicato: Shippori Mincho Regular, senza falso assottigliamento. Il repository ufficiale dichiara SIL OFL 1.1: https://github.com/fontdasu/ShipporiMincho (sezione licenza). Fonte alternativa dei file: https://github.com/google/fonts/tree/main/ofl/shipporimincho.

**Asset in contorni non incluso:** il download locale di TTF/licenza è fallito per risoluzione DNS di raw.githubusercontent.com. La dichiarazione OFL è stata verificata nella pagina ufficiale via ricerca web; il font non è presente localmente, non è stato sostituito con un carattere di sistema e non viene dichiarato convertito. Quando i file sono disponibili, conservare la licenza e convertire i quattro caratteri in tracciati, senza incorporare o installare il font nell’app. Questa parte della precedente richiesta estesa resta pendente; il marchio D e l’icona funzionano senza font aggiuntivi.
