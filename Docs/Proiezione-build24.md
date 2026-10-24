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
