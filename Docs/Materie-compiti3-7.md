# Materie completate — compiti 3–7

## Compito 3

Backup personale creato **prima delle modifiche allo schema**, tramite SQLite backup API in sola lettura: `/Users/ale/Library/Application Support/Komorebi Study/Backups/Pre-completamento-20261024-094409`. Integrità della copia verificata. Nessuna migrazione è stata eseguita sul database personale durante lo sviluppo.

La build aggiunge campi opzionali gradeValue, gradeHonors, gradeNote, completedAt e completionVersion. Il testo grade precedente resta intatto. Migrazione idempotente: solo interi 18–30 diventano voto numerico; ogni altro testo resta esatto nella nota. Nessuna lode dedotta automaticamente da testo libero. Data delle completate precedenti = fine dell’ultima sessione associata, altrimenti nil. Per nuove completate viene assegnata la data corrente. La riapertura conserva voto/data/note.

All’avvio reale la nuova build controlla lo schema in sola lettura e crea una nuova copia SQLite e delle preferenze prima di aprire ModelContainer se mancano colonne o record migrati. Fallire il backup impedisce di proseguire. I backup automatici sono nella sottocartella Backups dell’archivio, prefisso SubjectCompletion; gli import legacy hanno prefisso SubjectImport. I backup JSON includono tutti i campi e mantengono il vecchio formato leggibile.

Introdotta la sorgente activeSubjects/completedSubjects nello store, aggiornata al salvataggio solo se la firma dei dati delle materie cambia. Home e Timer usano la sorgente attiva; preparedSubject ripiega sulla prima attiva. Completare una materia non modifica il timer già attivo o la sua sessione salvata. I totali di consultazione restano intatti; solo il progresso dell’obiettivo settimanale esclude le completate, mantenendo il valore dell’obiettivo impostato dall’utente. Non si sottrae la durata degli obiettivi delle materie dal target generale, essendo due impostazioni indipendenti. Calendario e pigmenti invariati.

Verifica: 154 test Release, zero errori, uno saltato per fixture facoltativa. Compresi: migrazione SQLite da modello congelato build 20, copia prima dell’aggiunta delle colonne, caso Misure Elettroniche voto 18, date mancanti, note preservate, idempotenza, sessione attiva, esclusione dal solo obiettivo settimanale e cache invariata ai tick/refresh senza modifiche alle materie.

## Compito 4

Due sezioni con titoli e contatori accessibili. Da completare usa le card precedenti; Completate è comprimibile (preferenza salvata, inizialmente aperta), ordinata per data decrescente con date sconosciute in fondo. Riga compatta con tile/nome, data solo se nota, voto o spunta, tempo/sessioni, Modifica e popover azioni Riapri/Elimina. Eliminazione mantiene la conferma e il blocco per materia della sessione attiva. Nessuna eliminazione eseguita durante lo sviluppo. Note dei voti legacy mostrate integralmente; media aritmetica opzionale non aggiunta.

Il modulo ora accetta voto vuoto o intero 18–30; la lode compare solo a 30 e non può essere salvata con un voto diverso. Messaggio inline e Salva disabilitato per valori non validi. Le date sconosciute delle già completate restano vuote: l’utente può esplicitamente aggiungerle. Nuove completate partono da oggi. Titolo/footer rimangono fissi e le tab rimangono orizzontali come nel checkpoint precedente.

Transizione di opacità 250 ms al cambio di sezione, disattivata con Riduci movimento o Animazioni Off. Niente timer/animazioni continui. Riassunti di tempo/sessioni in cache, ricostruiti in un solo passaggio al cambio delle sessioni o al confine del giorno; nessun filtro per materia ripetuto in ogni card al movimento del mouse.

Verifica: 155 test Release, nessun errore, uno saltato. Inclusi 35 materie, ordine e persistenza sezione, 1.000 letture del catalogo senza ricostruzioni, conservazione dei totali e aggiornamento a mezzanotte. Nessuna misura CPU o prova reale VoiceOver eseguita; non è certificato un limite numerico di consumo.

## Compito 5 — censimento verificato con ricerca dei riferimenti e lettura dei componenti

| Punto | File / componente | Fonte dati e ruolo |
|---|---|---|
| Home «Sessione» | Views/RootView.swift, OverviewView.quickStart | preparedSubject e activeSubjects; avvio studio |
| Timer | Views/RootView.swift, TimerSetup | stesso preparedSubject/activeSubjects; configurazione studio |
| Popover barra menu | KomorebiApp.swift, MenuPanel | riusa TimerSetup e SessionControls; stesso selettore del Timer |
| Scorciatoie Studio | KomorebiApp.swift, comandi | chiamano store.start/preparedSubject, nessun elenco separato |
| Focus e ring | Views/RootView.swift, TimerFace/FocusView | active.subjectName o preparedSubject; nessun elenco, conserva sessione attiva |
| Creazione esame | Views/CalendarView.swift, ExamEditor | subjectID, attualmente elenco subjects completo; da limitare nel compito 6 |
| Modifica esame | stesso ExamEditor | subjectID già salvato; da preservare anche se completata |
| Calendario mensile/dettagli/tooltip | Views/CalendarView.swift | sessions, exams, subjects per colore e nome; consultazione, nessun filtro per materia presente |
| Prossimi esami Home | Views/RootView.swift, OverviewView.upcoming | exams >= inizio giornata; da escludere i collegamenti a completate |
| Countdown Home | Views/RootView.swift, HomeExamCountdown/NextExamCountdown | exams, selezione data locale; stessa esclusione da applicare |
| Cronologia filtro | Views/HistoryView.swift | nomi distinti salvati nelle sessions; da includere tutte le materie con gruppo completate, conservando i vecchi nomi non più associati |
| Modifica sessione | Views/HistoryView.swift, SessionEditor | materia attuale da session + subjects; da limitare alle attive oltre all’attuale |
| Statistiche filtro | Views/StatisticsView.swift | subjectID, subjects completi; da raggruppare attive/completate |
| Statistiche grafici e riepiloghi | Views/StatisticsView.swift | sessions e subjects per metadati; consultazione completa |
| Materie | Views/SubjectsView.swift | activeSubjects/completedSubjects + subjectSummaries; gestione e consultazione |
| Obiettivo per materia | Views/SubjectsView.swift, SubjectFormFields | campo numerico della materia nel modulo, nessun ulteriore selettore |
| Obiettivi generali | Views/SettingsView.swift e GoalEditor | UserSettings, nessuna scelta di materia |
| Fine sessione e nota | Views/RootView.swift, CompletionView; KomorebiApp.swift | record sessione e active, nessun nuovo selettore |
| Backup/restore | Services/BackupService.swift | tutte le subjects/sessions/exams; da mantenere completi |
| Fixture preview | KomorebiApp.swift, configurePreview | dati fittizi in memoria, nessuna selezione personale |

Il solo componente generico per dropdown è Components/Controls.swift, StudyDropdown. Palette e icone dei moduli sono in Components/SubjectAppearance.swift e non selezionano altre materie. Nessun ulteriore Picker di materia trovato. Il censimento è di codice; non viene presentato come apertura manuale di tutti i menu.
