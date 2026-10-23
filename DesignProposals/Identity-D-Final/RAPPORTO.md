# Komorebi Study — Concept D e icona chiara

23 ottobre 2026. Scelta dell’utente: D, nella versione chiara mostrata nel riferimento. Implementazione principale pronta e verificata automaticamente. Nessuna app sostituita in Applicazioni. I vincoli precedenti su prove solo da codice/test, senza CUA, sono mantenuti.

## Modifiche

- Tema Komorebi: il pacchetto dichiara `.pagesAndLight` nella proprietà `logoMark`. ThemeLogoView disegna due lenti geometriche e il disco al 60% tramite Shape vettoriali, tinti dal token del tema. Nessun controllo sul nome del tema; nessun colore aggiunto alle viste. La versione già minimale conserva lenti e disco anche sotto 32px. Il viewport ottico elimina il margine del master per conservare altezza visiva e centratura.
- Marchio visibile nella sidebar e nell’intestazione del popover menu mediante ThemeBrand. Il wordmark conserva testo e font. Le icone funzionali della barra dei menu, delle materie, della serie e del timer restano invariate.
- Halloween conserva la zucca B, il glow, i font e tutti i token. Il nuovo marchio passa dalla dissolvenza del pacchetto tema già presente.
- AppIcon: unica icona chiara, fondo crema, foglie verde scuro e disco attenuato. Master SVG/PNG 1024, AppIcon.iconset e AppIcon.appiconset con dieci PNG standard/Retina, file ICNS completo e livelli SVG separati. Nessuna nuova impostazione o libreria. Resources/AppIcon.icns aggiornato; gli altri file sono sorgenti e materiali di riferimento.
- Scripts/Icon.swift ora rasterizza il master approvato; Scripts/build-icon.sh rigenera l’intero set. Il primo tentativo con iconutil ha rifiutato l’iconset nell’ambiente limitato: il packer incluso genera il contenitore ICNS standard con chunk PNG, poi verificato con decodifica dei dieci chunk e caricamento AppKit.
- Corretto un test del compito 4 che confrontava due JSON senza ordinare le chiavi: produceva un errore intermittente pur contenendo gli stessi dati. Il test ora usa outputFormatting.sortedKeys; nessuna modifica al salvataggio dell’app.

## Verifiche eseguite

- `swift test --disable-sandbox --cache-path /tmp/komorebi-spm-cache`: **97 test, uno saltato, zero errori**. L’unico salto richiede un fixture opzionale di archivio reale; non è stato usato l’archivio personale.
- Build Release riuscita: `swift build -c release -debug-info-format none --disable-sandbox --cache-path /tmp/komorebi-spm-cache`.
- Nuovi test su proprietà del pacchetto, zucca invariata, tint/contrasto >=3:1 del corpo del marchio sulla sidebar in entrambi i temi di modalità e nelle quattro stagioni; opacità del disco 60%; lenti simmetriche, vuoto centrale e disco separato a 16/20/24/28/32/48/128; altezza del wordmark rispetto alla precedente foglia; render disponibili in chiaro/scuro; ICNS con dieci immagini delle dimensioni corrette e decodifica AppKit riuscita.
- `bash Scripts/build-icon.sh`: riuscito. `git diff --check`: riuscito.
- Anteprima degli asset chiara/scura e immagini prima/dopo del marchio renderizzate localmente e ispezionate. Sono render, **non screenshot della finestra o del Dock**. Le dimensioni più piccole sono incluse per l’ispezione degli asset; non si dichiara effettuata una prova di riconoscibilità con utenti.
- Bundle Release separati firmati ad hoc, firme verificate. Nessun avvio della build ordinaria. Nessuna misura aggiuntiva di CPU/FPS/energia e nessuna prova nativa dell’interfaccia dichiarata.

## Consegna

Usare **Komorebi-Prova-D.app** per le prove: identificatore `com.komorebi.study.preview.identityd.compact`, archivio in memoria, preferenze isolate, fixture dimostrative, tema Komorebi chiaro iniziale. Non conserva sessioni dopo la chiusura. La build ordinaria **Komorebi-Study-D.app** resta separata ma, se avviata, usa l’archivio personale: non è stata aperta durante il lavoro. Nessuna installazione in Applicazioni.

Sorgenti nel pacchetto datato; icona e vettori in Identita-D. Anteprima chiara/scura: anteprima.png; confronto del marchio: marchio-prima-dopo-light.png e marchio-prima-dopo-dark.png. I file contengono immagini statiche, non catture della UI. Lo ZIP include anche le ottimizzazioni del compito 4 già implementate e il relativo rapporto.

## File modificati per questa scelta

- Sources/Components/Themes.swift — risorsa D, token e Shape.
- Sources/KomorebiApp.swift — riuso ThemeBrand nel marchio del popover.
- Resources/AppIcon.icns — icona chiara D.
- Scripts/Icon.swift — rasterizzatore del master SVG.
- Scripts/build-icon.sh — nuova rigenerazione completa.
- Tests/AppearanceTests.swift — aspettativa del nuovo marchio Komorebi.
- Tests/BrandIdentityTests.swift — nuove verifiche dell’identità e dell’ICNS.
- Tests/RenderingIsolationTests.swift — ordinamento stabile del JSON nel test.
- DesignProposals/Identity-D-Final — SVG/PNG, iconset/appiconset, livelli, generatori, scheda e rapporto.

Le modifiche del compito 4 erano già presenti e non sono state annullate. La patch complessiva allegata comprende sia 4 sia D rispetto alla revisione Git e17445c. Nessun nuovo commit: .git è in sola lettura e il precedente tentativo di creare index.lock è stato negato. Non si aggira il blocco: consegnata copia datata e patch, senza riscrivere la cronologia.

## Parte ancora pendente della richiesta estesa

L’asset 木漏れ日 in Mincho convertito in contorni **non è incluso**. Il repository ufficiale Shippori Mincho conferma OFL 1.1 (https://github.com/fontdasu/ShipporiMincho), ma il download locale del TTF/licenza da raw.githubusercontent.com è fallito per DNS. Non è stato usato un font sostitutivo e non si dichiara una conversione mai eseguita. Le regole d’uso sono nella scheda di stile. Il marchio D, il wordmark esistente e l’icona non dipendono da quel font.

Gli screenshot reali nel Dock chiaro/scuro non sono stati eseguiti, come da istruzione di saltare controllo CUA/interfaccia: fornite simulazioni dichiarate. La proposta di un solo passaggio luminoso sul ring è descritta nella scheda, non implementata. Non viene dichiarata la conclusione integrale del compito 5 finché manca l’asset Mincho richiesto; l’implementazione di marchio e icona approvati è pronta.
