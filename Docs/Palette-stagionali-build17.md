# Palette stagionali — build 17

## Intervento

Le palette delle materie conservano i 24 identificativi stagionali e gli 8 classici. Non vengono riscritti i colori salvati, le materie, i voti o le sessioni; i nuovi token si propagano a tile, titoli, progressi, grafici e pigmenti del Calendario attraverso le risoluzioni esistenti. I colori Classici restano invariati.

- Primavera: fiori rosa/glicine, germogli verde fresco, pesco, cielo e primula.
- Estate: mare ciano, menta, cobalto, magenta oleandro, corallo e agrume, con saturazione più piena.
- Autunno: zucca, acero, senape, castagna, vino e bosco più olivastro; predominanza calda e terrosa.
- Inverno: ardesia e indaco, brina, verde abete, bacca e cenere neutra; predominanza fredda.

Il generatore modifica la luminosità HSL mantenendo la tonalità e, in scuro, riducendo leggermente la saturazione. Evita l’interpolazione uniforme verso il bianco, che prima faceva convergere i colori verso tinte simili. In Halloween le varianti stagionali vengono usate direttamente prima della correzione di contrasto sulle superfici reali; i classici mantengono il comportamento precedente. Nessun calcolo aggiunto al movimento del mouse o ai tick del timer.

Il selettore mostra anche una descrizione breve della palette sotto i tab, localizzata in italiano e inglese. Dimensioni dei pallini, interazioni e selezione non cambiano.

## Riferimenti e scelte

Le associazioni stagionali sono una scelta di design, non una classificazione scientifica universale. Riferimenti botanici consultati:

- RHS, Autumn-interest shrubs: https://www.rhs.org.uk/plants/types/shrubs/autumn-interest — pigmenti autunnali gialli/arancio/rossi/viola.
- RHS, Three ways to bring colour into your garden: https://www.rhs.org.uk/garden-inspiration/get-gardening/bright-and-colourful-garden-inspiration — fioriture estive, fogliame e rami invernali.

## Verifiche e limiti

Suite SwiftPM Release: 137 test, nessun errore, uno saltato (fixture opzionale di migrazione). Audit localizzazione superato: 435 voci inglesi, 311 chiavi letterali/plurali. contrasto testo >= 4.5:1, icone sui tile >= 3:1 su superfici reali Komorebi/Halloween, chiaro/scuro. Test CIELAB Delta E 76 > 10 tra i pallini della stessa palette in tutte le quattro combinazioni: protezione contro colori quasi duplicati, non garanzia di riconoscibilità per ogni forma di daltonismo. Nomi, icone dei tab, descrizioni e selezione restano disponibili oltre al solo colore.

Rendering automatico di quattro tavole delle palette. Il test ha individuato Ardesia e Cenere ancora troppo vicine: Cenere è stata corretta in un neutro distinto. Il test del pannello materia controlla ancora che resti entro 650 pt con nome lungo e voto dopo l’aggiunta della descrizione.

Nessuna prova nativa con mouse/tastiera, misurazione dello schermo o valutazione colorimetrica sul Mac dell’utente eseguita. Le tavole sono render fuori schermo, non screenshot dell’app in uso. Dati di prova e archivio temporaneo; nessun archivio personale utilizzato. Build separata, firma ad hoc senza notarizzazione; Applicazioni non sostituita.

## Token finali

| ID | Nome | Chiaro | Scuro |
|---|---|---|---|
| primavera.ciliegio | Ciliegio | #B52B66 | #E49EBC |
| primavera.germoglio | Germoglio | #467022 | #8FC95F |
| primavera.glicine | Glicine | #8542C0 | #C4A7DE |
| primavera.pesco | Pesco | #AC401B | #E8A189 |
| primavera.cielo-aprile | Cielo d’aprile | #1F6B8E | #75BCDC |
| primavera.primula | Primula | #766417 | #D6BC52 |
| estate.mare | Mare | #006C8D | #31C9F6 |
| estate.corallo | Corallo | #BC280F | #F19C8E |
| estate.oleandro | Oleandro | #B2208A | #E898D2 |
| estate.menta | Menta | #00725A | #31F6CD |
| estate.cobalto | Cobalto | #235BD5 | #99B3EA |
| estate.agrume | Agrume | #8A5B00 | #F6B331 |
| autunno.zucca | Zucca | #995216 | #E5A56F |
| autunno.acero | Acero | #AE3426 | #E5A199 |
| autunno.senape | Senape | #7B6219 | #D5B453 |
| autunno.castagna | Castagna | #805038 | #CFAC9A |
| autunno.vino | Vino | #79334D | #D6A5B7 |
| autunno.bosco | Bosco | #5F6A30 | #ABBA70 |
| inverno.ardesia | Ardesia | #4F6783 | #A5B5C7 |
| inverno.mirtillo | Mirtillo | #5451A1 | #B1AFD5 |
| inverno.agrifoglio | Agrifoglio | #23663E | #65C58B |
| inverno.bacca | Bacca | #9E3654 | #DCA3B3 |
| inverno.brina | Brina | #2A6D7D | #79BDCD |
| inverno.cenere | Cenere | #65655F | #B3B3AE |

## File modificati

- Sources/Components/Themes.swift
- Sources/Components/SubjectAppearance.swift
- Sources/ThemeResources/Translations.json
- Scripts/audit-seasonal-colors.py
- Tests/SeasonalPaletteTests.swift
- Komorebi Study.xcodeproj/project.pbxproj
- Docs/Palette-stagionali-build17.md
- Docs/PASSAGGIO-PROGETTO.md
