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
