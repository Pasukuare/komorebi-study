# Statistiche e popover — 24 ottobre 2026

## Diagnosi e interventi

- `StatisticsView.swift`: l'hover memorizzava la data continua restituita da ChartProxy nello stato dell'intera schermata. Anche muovendo il puntatore sulla stessa barra cambiava lo stato e venivano rivalutati totali, raggruppamenti e serie. La selezione vive ora in `StatisticsStudyChart`, riceve i bucket già calcolati e pubblica solo il giorno/mese canonico quando cambia. Tooltip, selezione via click e selezione nativa del grafico sono conservati. Rimosso lo spotlight aggiuntivo applicato al rettangolo del grafico; il trattamento della card resta presente.
- `Style.swift`: i callback di ingresso/uscita hover partono solo al cambio effettivo. La posizione viene salvata solo dove lo spotlight è effettivamente disegnato, evitando aggiornamenti per righe, selezioni e modalità chiara.
- `KomorebiApp.swift`: il fondo di MenuPanel ignora le safe area ed è esteso anche al fondo della finestra ospitante tramite `MenuPanelWindowSurface`. Colore dai token, superficie opaca, nessuna modifica alla sidebar o alla finestra principale. La superficie non intercetta click. È una correzione del contenuto dell'app; l'evidenziazione della voce nella barra dei menu resta gestita da macOS.

## Verifiche eseguite

`swift test`: 110 test, 1 saltato, 0 errori.

Nuove regressioni: 1.000 date diverse nello stesso giorno -> 1 cambio di selezione; cambio giorno e uscita dal grafico; bucket vuoti; selezione mensile con cambio ora legale Europe/Rome; fondo della finestra opaco nei due temi e nelle due modalità, aggiornamento del colore e assenza di hit testing.

La verifica del fondo usa una NSWindow di test, non il vero MenuBarExtra. Non sono stati riprodotti hover, scroll e apertura del popover con strumenti UI; quindi non si dichiara conclusa la verifica visiva delle bande. Nessuna nuova misura di CPU, watt, frame rate o hitch. I watt indicati dall'utente non vengono trasformati in una misura di consumo del solo processo.

## Verifica pratica residua

Con la nuova build Release: nella stessa settimana di Statistiche muovere il cursore sulla stessa barra, poi tra barre; controllare tooltip e click. Confrontare CPU e watt nelle stesse condizioni di luminosità, carico delle altre app, timer e decorazioni. Aprire il popover con la finestra principale nascosta: verificare assenza di bande sopra e sotto, anche in chiaro e dopo il cambio tema. Controllare una nota estesa e una finestra bassa, dove il contenuto può scorrere.

Archivio personale, timer e navigazione non modificati. L'app installata non è stata sostituita. La build è firmata localmente ad hoc e non notarizzata.
