# Komorebi Study

Applicazione macOS nativa, offline, per coltivare una routine di studio. Versione 1.0 MVP, Apple Silicon, macOS 15 o successivo. Swift, SwiftUI, Swift Charts, SwiftData, UserNotifications e AVFoundation. Nessuna dipendenza esterna.

## Avvio

Apri `Komorebi Study.dmg` e trascina **Komorebi Study** su **Applications**. Puoi anche aprire direttamente la `.app` consegnata. L'app è firmata ad hoc per uso locale: non è notarizzata da Apple e non possiede una firma Developer ID. La distribuzione pubblica con Gatekeeper richiede firma e notarizzazione con il tuo account Apple Developer. Non disabilitare Gatekeeper globalmente.

Scegli l'obiettivo iniziale, seleziona una materia e premi **Inizia a studiare**. In **Materie** puoi aggiungere e modificare nome, icona, colore e obiettivo settimanale. L'ultima materia e modalità sono ricordate.

## Funzioni incluse

- Pomodoro configurabile, preset 25/5, 50/10 e 90/20, pause lunghe ogni N sessioni.
- Cronometro libero e conto alla rovescia personalizzato, espresso in minuti (120 = 2 ore), con pausa facoltativa.
- Pausa, ripresa, salvataggio automatico e recupero della sessione attiva dopo il riavvio dell'app.
- Archivio SwiftData locale, note, modifica e cancellazione delle sessioni.
- Obiettivi giornalieri, settimanali e per materia; soglia personalizzabile della serie di giorni.
- Grafici giornalieri, settimanali e mensili nell'anno, distribuzione per materia, media giornaliera e confronto settimanale.
- Calendario mensile a intensità di colore con dettaglio delle sessioni.
- Cronologia ricercabile per note e materia, con filtri per modalità, date e durata minima.
- Riepilogo settimanale e informazioni locali basate sui dati, senza AI esterna.
- Menu bar con tempo, pausa, stop e riapertura dell'app; funziona anche con la finestra chiusa. Badge Dock.
- Notifiche native opzionali e suono di completamento. Attivale nelle impostazioni e autorizzale in macOS.
- Focus a schermo intero, cinque palette, aspetto sistema/chiaro/scuro, particelle leggere a 12 fps solo con animazioni Full. Reduce Motion è rispettato; Off e Reduced mantengono lo sfondo statico. La palette Morning ha una lieve tinta calda dal pomeriggio.
- Tre ambienti sintetizzati originali: pioggia, vento, camino. Volume regolabile; nessun file audio di terzi. Sono suoni sintetici, non registrazioni realistiche.
- Export CSV e backup JSON; importazione con controllo versione e deduplicazione per ID.
- Controlli SwiftUI accessibili, descrizioni dei grafici native e scorciatoie: Spazio, ⌘ Invio, ⌘ punto. I campi di testo mantengono l'uso normale della tastiera.

## Comportamento del timer

L'interfaccia si aggiorna ogni secondo, ma il tempo deriva dalle date di inizio, pausa e ripresa. I tick persi non alterano il conteggio. Lo sleep conta come studio se non metti in pausa il timer; un conto alla rovescia viene limitato alla durata prevista. Il cronometro continua anche se esci dall'app e viene recuperato alla riapertura. Per smettere di registrare premi Pausa o Termina.

Le pause Pomodoro vengono preparate in pausa e avviate con **Riprendi**. Al termine di una pausa, la nuova sessione richiede **Avvia**. Questo evita cicli automatici e ore di studio inventate quando sei lontano. Lo stop salva anche una sessione parziale. Il numero dei Pomodoro completati è conservato fra riaperture e determina la pausa lunga.

Le statistiche principali includono le sessioni terminate: il tempo ancora in corso è indicato separatamente. Le sessioni a cavallo della mezzanotte vengono ripartite proporzionalmente alla loro sovrapposizione con i giorni; la posizione esatta delle singole pause non è ricostruita. Le statistiche usano calendario e fuso orario attuali del Mac. Il confronto settimanale indica esplicitamente che la settimana corrente è ancora parziale.

## Dati e backup

L'archivio si trova in `~/Library/Application Support/Komorebi Study/Study.store`, con i relativi file di SQLite. Impostazioni e timer di recupero sono nelle preferenze del bundle `com.komorebi.study`. Il backup JSON esporta sessioni, materie e impostazioni, ma non il timer in corso. Termina il timer prima del backup completo.

L'importazione **unisce** i dati: aggiunge gli ID mancanti, mantiene i record esistenti e sostituisce le impostazioni. Non ripristina una versione precedente di una sessione già presente con lo stesso ID. L'eliminazione di una materia conserva nome e statistiche delle sessioni passate. Esporta un backup prima di cancellazioni importanti.

Durante il collaudo locale è stata creata una breve sessione con nota “Verifica tecnica del timer”. È un record di prova nel Mac di sviluppo, non contenuto nel DMG.

## Aprire e compilare in Xcode

1. Apri **Komorebi Study.xcodeproj**.
2. Seleziona lo schema **Komorebi Study** e destinazione **My Mac**.
3. Premi **⌘ R** per compilare e avviare. Target minimo: macOS 15; architettura arm64.
4. Per la distribuzione pubblica imposta il tuo Team in Signing & Capabilities, poi usa Product → Archive e il flusso Developer ID/notarizzazione di Xcode.

Per generare automaticamente app e DMG locali dalla cartella del progetto:

```sh
./Scripts/build-release.sh
```

I risultati saranno in `Dist/Komorebi Study.app` e `Dist/Komorebi Study.dmg`. Lo script compila in Release, firma ad hoc, verifica la firma, crea un'immagine compressa con collegamento ad Applications e verifica il DMG. Accetta una cartella di destinazione come primo argomento.

## Test

```sh
./Scripts/test.sh
```

Il pacchetto Swift non ha dipendenze da scaricare. I test usano archivi in memoria e preferenze isolate. Il progetto Xcode compila l'app; i test sono eseguibili tramite Swift Package Manager.

## Architettura

- `Models/`: modelli SwiftData, impostazioni Codable, stato del timer e formattazione.
- `Services/StudyStore.swift`: stato osservabile, timestamp, transizioni, persistenza, aggregazioni e notifiche.
- `Services/BackupService.swift`: export e importazione validata e deduplicata.
- `Services/AmbientAudio.swift`: generazione audio locale e riproduzione AVFoundation.
- `Views/`: schermate native separate.
- `Components/`: componenti comuni e paesaggio vettoriale originale.
- `Tests/`: casi limite del timer, salvataggio, pausa, allocazione giornaliera e backup.
- `Resources/`: icona originale inclusa nel progetto Xcode.

## Confini della prima versione

Questo è un MVP utilizzabile, non l'intera roadmap. WidgetKit non incluso; niente registrazioni Forest/Café/Night, illustrazioni dipinte complesse o simulazioni meteorologiche. Il timer personalizzato usa un unico campo minuti; il filtro durata ha un limite minimo. Gli insight includono confronto settimanale, ultima finestra di 30 giorni e sessione più lunga di oggi; non includono ancora analisi per fascia oraria o giorno più produttivo. Non è stato eseguito un collaudo su hardware con macOS 15, un ciclo fisico di sleep di lunga durata né un audit completo VoiceOver. Notifiche soggette ai permessi e a Non disturbare di macOS.

Non sono presenti account, richieste di rete, telemetria, acquisti o servizi remoti.

## Aggiornamento: Home ed esami

Home ora mostra obiettivi, progressi, ultime sessioni e prossimi esami; Timer contiene i controlli di studio. Nel Calendario seleziona un giorno e premi Aggiungi esame: inserisci nome, materia facoltativa, data, eventuale ora e note/aula. Seleziona il giorno per modificare o eliminare un esame. Gli esami sono locali e inclusi nel backup JSON; i vecchi backup senza esami rimangono compatibili. Non sono eventi del Calendario Apple e non inviano promemoria.
