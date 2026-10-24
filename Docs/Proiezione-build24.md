# Proiezione — build 24

## Compito 1 — censimento di sola lettura

| Dato/punto | File e punto | Comportamento esistente |
|---|---|---|
| Sessioni salvate | Sources/Models/Models.swift, StudySession | UUID, subjectID/subjectName, startDate/endDate, duration in secondi, pauseDuration, note e activityData opzionale con intervalli effettivi |
| Persistenza/lettura | Sources/Services/StudyStore.swift, init/refresh/save | SwiftData ModelContainer locale; sessions recuperate ordinate per startDate decrescente |
| Conteggio effettivo | StudyStore.savedTiming/contribution/totals; SavedStudyTiming.contribution | Intervalli misurati se presenti, altrimenti ripartizione proporzionale del record; pause escluse e attraversamento mezzanotte già gestiti |
| Home | Sources/Views/RootView.swift, OverviewView/DailyGoalCard | store.sessions, riassunti e componenti LiveStudyTime; il nuovo calcolo userà solo record salvati |
| Statistiche | Sources/Views/StatisticsView.swift, StatisticsView/buckets/shares | store.sessions e contributi temporali dello store |
| Cronologia | Sources/Views/HistoryView.swift, HistoryView.filtered | store.sessions, filtri di materia/modalità/date/testo |
| Esami | Sources/Models/Models.swift, StudyExam/ExamRecord | subjectID, title legacy, date, hasTime, note (comprende luogo/aula), examKind/examKindDetail opzionali |
| Modulo esame | Sources/Views/CalendarView.swift, ExamEditor | Materia, tipo facoltativo, data, orario facoltativo, Note/aula |
| Countdown | Sources/Views/RootView.swift, NextExamCountdown.nearest | Differenza tra inizio di oggi e inizio del giorno dell’esame con calendario locale; gli esami del giorno restano visibili |
| Obiettivi | Sources/Models/Models.swift, UserSettings.dailyGoal/weeklyGoal; StudyStore.settings/persistSettings | Ore in UserSettings, persistite in UserDefaults e backup JSON. Valori scelti dall’utente, nessun obiettivo per esame |
| Grafici | Sources/Views/StatisticsView.swift, StatisticsBars | Swift Charts (Chart, BarMark, assi e chartOverlay). Nessuna dipendenza grafica esterna |
| Ore necessarie / inizio preparazione | Ricerca nei modelli e nelle viste | Non esistono ancora. Nessun valore da dedurre dall’obiettivo giornaliero o da weeklyGoal della materia |

Il censimento non modifica il codice. Le implementazioni iniziano nel Compito 2.

## Compito 2 — modello, formule e cache

Aggiunti solo i campi opzionali StudyExam.requiredStudyHours e preparationStart, conservati anche da ExamRecord/backup JSON. Nessun valore assegnato agli esami precedenti. Backup personale pre-schema creato in sola lettura: `~/Library/Application Support/Komorebi Study/Backups/Pre-proiezione-20261024-105508`; integrità della copia controllata. Nessuna migrazione personale eseguita durante le prove. Al primo avvio la build controlla le colonne SQLite prima di ModelContainer e crea un backup datato Projection se mancano (o la lettura non riesce).

ProjectionCalculator è una funzione pura su ore giornaliere e date, indipendente da SwiftData/UI/timer. ExamCalendarDays.remaining è condivisa con NextExamCountdown: giorni tra gli inizi delle giornate locali, escluso il giorno dell’esame, con supporto ai cambi d’ora.

- Fatte = sessioni salvate della materia dal giorno iniziale, incluse quelle salvate oggi. Sessione in corso esclusa. Ripartizione tra giorni e pause riusata da SavedStudyTiming.
- Ritmo = ore negli ultimi min(7, giorni trascorsi dalla preparazione) giorni completi / stesso divisore; giorni a zero compresi. Oggi escluso per evitare una media su una giornata parziale; se la preparazione inizia oggi, si usano le sole sessioni salvate oggi e divisore 1.
- Proiezione finale = fatte + ritmo × giorni rimasti.
- Ritmo necessario = max(0, necessarie − fatte) / giorni rimasti. Oggi con ore mancanti il valore è non calcolabile, non infinito; se già raggiunto è zero. Esame passato escluso dalla card.
- Ritardo = max(0, necessarie − proiezione finale).
- Priorità stati: passato; raggiunto; esame oggi; ritmo necessario oltre obiettivo giornaliero o 12h; in linea; indietro. Le eccezioni oggi/passato sono esplicite e non introducono divisioni per zero.

Il caso richiesto produce 20h fatte, 2h/giorno, 27 giorni, 74h previste, 130/27 = 4,8148h/giorno necessarie, 76h di ritardo, indietro con obiettivo giornaliero 6h.

Lo store ricostruisce risultati e punti solo se cambiano i dati rilevanti di sessioni/esami, ore/data iniziale, materie attive, obiettivo giornaliero, giorno o fuso orario. Nessun calcolo durante hover, apertura menu, tick del timer o ridisegno UI. Le letture del risultato sono lookup in cache. Le aggregazioni giornaliere sono condivise tra esami della stessa materia. Le ore non vengono ripartite artificialmente tra esami diversi della stessa materia: ciascuno usa il proprio intervallo di preparazione.

## Compito 3 — card Home

Nuova card sotto Obiettivo settimanale, stesso bordo/raggio/superficie e titolo serif delle altre card. Nessun cambiamento alle card precedenti. Esame iniziale = più vicino con materia attiva; menu condiviso se più di uno, scelta conservata finché eleggibile. Esami non collegati o con materia mancante sono esclusi perché le ore non sono attribuibili; rimangono nel Calendario.

Senza ore: domanda sul nome della materia, campo vuoto, data iniziale esplicitamente modificabile (oggi), Imposta. Nessun valore di ore precompilato. Matita per riaprire l’editor; modificare le ore non azzera la data iniziale. Input italiano/inglese, validazione di numero positivo finito, ripristino dei soli campi modificati se il salvataggio fallisce. Le cifre originali non vengono arrotondate nell’editor.

Con ore: frase principale, Fatte/A questo ritmo/Servono, stato e ritmo richiesto con confronto al ritmo attuale. Ambra/terracotta per ritardo e limite di ritmo, salvia per in linea/raggiunto; nessun rosso. Testo esplicito: solo sessioni salvate. Esame oggi senza giorni disponibili mostra il residuo e nessun ritmo inventato. Nessun esame eleggibile: messaggio e pulsante Apri Calendario.

La card Proiezione esclude il proprio spotlight, lasciando immutati gli stili delle altre card: il movimento sul futuro grafico non ridisegnerà un gradiente grande quanto la card. I controlli mantengono i loro hover/focus condivisi.

Verifica Compito 3: 171 test Release, nessun errore, uno saltato. Coperti parsing vuoto/zero/non finito/virgola, dietro→in linea→raggiunto con sessioni salvate, ordine 19/27 giorni, materia completata esclusa/riaperta, 1.000 letture senza ricostruire la cache. Catture native fuori schermo della card numerica e della richiesta vuota nelle quattro combinazioni di tema/modalità. Non sono prove di click, tastiera o VoiceOver reali.
