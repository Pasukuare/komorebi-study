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
| Home «Sessione» | Views/RootView.swift, OverviewView.quickStart | preparedSubject e activeSubjectChoices; avvio studio |
| Timer | Views/RootView.swift, TimerSetup | stesso preparedSubject/activeSubjectChoices; configurazione studio |
| Popover barra menu | KomorebiApp.swift, MenuPanel | riusa TimerSetup e SessionControls; stesso selettore del Timer |
| Scorciatoie Studio | KomorebiApp.swift, comandi | chiamano store.start/preparedSubject, nessun elenco separato |
| Focus e ring | Views/RootView.swift, TimerFace/FocusView | active.subjectName o preparedSubject; nessun elenco, conserva sessione attiva |
| Creazione esame | Views/CalendarView.swift, ExamEditor | subjectID e activeSubjectChoices; solo attive più opzione Nessuna materia |
| Modifica esame | stesso ExamEditor | subjectID già salvato conservato tramite editingSubjectChoices, alternative attive |
| Calendario mensile/dettagli/tooltip | Views/CalendarView.swift | sessions, exams, subjects per colore e nome; consultazione, nessun filtro per materia presente |
| Prossimi esami Home | Views/RootView.swift, OverviewView.upcoming | homeExams >= inizio giornata; esclusi i collegamenti a completate |
| Countdown Home | Views/RootView.swift, HomeExamCountdown/NextExamCountdown | homeExams, selezione data locale; stessa esclusione delle completate |
| Cronologia filtro | Views/HistoryView.swift | historySubjectChoices, raggruppate attive/completate e vecchi nomi non più associati; filtro per ID |
| Modifica sessione | Views/HistoryView.swift, SessionEditor | editingSubjectChoices: materia attuale più alternative attive |
| Statistiche filtro | Views/StatisticsView.swift | subjectID e consultationSubjectChoices, raggruppate attive/completate |
| Statistiche grafici e riepiloghi | Views/StatisticsView.swift | sessions e subjects per metadati; consultazione completa |
| Materie | Views/SubjectsView.swift | activeSubjects/completedSubjects + subjectSummaries; gestione e consultazione |
| Obiettivo per materia | Views/SubjectsView.swift, SubjectFormFields | campo numerico della materia nel modulo, nessun ulteriore selettore |
| Obiettivi generali | Views/SettingsView.swift e GoalEditor | UserSettings, nessuna scelta di materia |
| Fine sessione e nota | Views/RootView.swift, CompletionView; KomorebiApp.swift | record sessione e active, nessun nuovo selettore |
| Backup/restore | Services/BackupService.swift | tutte le subjects/sessions/exams; da mantenere completi |
| Fixture preview | KomorebiApp.swift, configurePreview | dati fittizi in memoria, nessuna selezione personale |

Il solo componente generico per dropdown è Components/Controls.swift, StudyDropdown. Palette e icone dei moduli sono in Components/SubjectAppearance.swift e non selezionano altre materie. Nessun ulteriore Picker di materia trovato. Il censimento è di codice; non viene presentato come apertura manuale di tutti i menu.

## Compito 6

Il catalogo condiviso ora conserva anche ID, lookup e opzioni pronte per avvio/consultazione. La firma è strutturata (nessuna concatenazione ambigua dei nomi). L’elenco attivo non viene filtrato nei body o all’apertura dei menu. Home, Timer e MenuPanel riusano activeSubjectChoices; comandi Studio e guardia dello store impediscono avvii senza materie attive. Nessun cambiamento al timer già attivo.

Cronologia e Statistiche mostrano tutte le materie, con separatore non selezionabile «Completate». La Cronologia filtra per ID, così conserva sessioni con il vecchio nome dopo una rinomina; i nomi storici non più associati rimangono selezionabili senza collisione con «Tutte». Il Calendario non aveva un filtro per materia: non ne è stato aggiunto uno e la consultazione resta completa.

Creazione esami: attive e opzione Nessuna materia, già consentita. Modifica esami: conservato anche il collegamento corrente completato/eliminato, per consentire correzioni di data/note senza assegnazioni silenziose. Modifica sessione: corrente sempre presente; alternative attive. Salvare una nota senza cambiare scelta non riscrive nemmeno subjectName. Una scelta divenuta completata in un’altra finestra viene rifiutata se diversa dall’originale.

Home nasconde da Prossimi esami/countdown solo gli esami collegati a ID completati. Esami senza materia o con collegamento ormai mancante restano visibili: nessuno stato viene dedotto o cancellato. Riaprire una materia ripristina subito i suoi esami. Calendario e contatori degli esami restano invariati.

Se la selezione salvata viene completata, la preferenza viene corretta verso la prima attiva senza avvio; con zero attive preparedSubject è nil, avvio disabilitato, motivo e pulsante Aggiungi una materia presenti nei componenti condivisi. Il nuovo collegamento apre la sezione Materie anche dalla barra dei menu; nessun’altra navigazione cambia.

Verifica: 157 test Release, zero errori, uno saltato. Tre materie con sessione passata, scelta attuale completata, ultima attiva completata, riapertura, filtro consultazione, editor sessioni con materia completata, esami nascosti/ripristinati e countdown verificati via sorgenti condivise e test. Non sono dichiarati provati click reali o apertura manuale di tutti i popover. La scansione SQLite pre-backup considera anche gli errori di lettura come richiesta di backup, per fallire in sicurezza anziché saltare la copia.


## Compito 7 — nomi esatti

La ricerca di capitalized/localizedCapitalized/uppercased/lowercased/textCase non ha trovato trasformazioni dei nomi nel codice preesistente. Non è quindi dimostrato che «Dei» sia una capitalizzazione automatica dell’app: titolo dell’esame e nome della materia sono due valori distinti salvati. Non sono stati riscritti titoli preesistenti o il database personale.

Per rendere esplicita la regola, nomi di materie/esami, menu, righe, Focus, countdown e valori dei riepiloghi usano Text(verbatim:) e textCase(nil). I campi Nome materia/Nome esame disattivano la correzione automatica; gli altri editor mantengono il comportamento precedente. Un test conserva esattamente «Teoria dei Sistemi — f(x) e iOS» tra catalogo, countdown e backup.

### Verifica finale e limiti

- Suite Release: 159 test, zero errori, uno saltato perché richiede una fixture facoltativa non fornita.
- Audit pulsanti: 360 campioni, nessun contrasto insufficiente o stato mancante. Audit localizzazione: 467 voci inglesi, 341 chiavi letterali/plurali, superato.
- Build Xcode Release separata 1.8 (21), firma locale ad hoc e DMG verificati. Non notarizzata e non installata in Applicazioni.
- Catture native **fuori schermo**, non uso manuale/CUA: Materie/editor e percorsi Home, Timer, barra dei menu, Calendario, Cronologia, Statistiche, modifica sessione, nuovo esame, sezioni Materie e zero attive, nelle quattro combinazioni Komorebi/Halloween chiaro/scuro. Tre materie fittizie: Teoria dei Sistemi, Misure Elettroniche (completata, voto 18, sessione passata), Tesi. Prima ricostruita dal commit db64daa/build 20 con la stessa fixture; Dopo build 21. Nessuna prova sull’archivio personale.
- Le catture del corpo completo di Materie sono più alte di una finestra minima, per mostrare entrambe le sezioni. I test dedicati dell’editor mantengono larghezza 520 e limite dell’80% della finestra madre.
- Apertura manuale dei dropdown, click su padding, navigazione Tab/Invio/Esc, VoiceOver, riapertura reale dopo installazione e CPU/GPU con 30+ materie **non eseguiti**. I test di dati e cache non sostituiscono queste misure. Rimane una checklist nel rapporto del checkpoint 1–2, da estendere ai tre soggetti sopra.
- Gli avvisi Charts sugli anchor di AxisValueLabel compaiono sia nei render Prima sia Dopo; non sono crash o nuove regressioni dichiarate risolte. Gli avvisi FocusState dei render ImageRenderer restano un limite del metodo. È stato corretto anche un problema della fixture SQLite dei test (modifiche lasciate pendenti prima di eliminare Test.store), che produceva errori di teardown, non un difetto dell’archivio personale.
- Nessun timer/animazione continua aggiunto. Cache del catalogo e riassunti di 35 materie verificati; l’intervallo settimanale del progresso viene calcolato una sola volta per valutazione. Nessuna promessa numerica su CPU o frame rate.

### Risultati dei casi richiesti

| Controllo | Risultato eseguito |
|---|---|
| Escludere completate da avvio/creazione | Test della sorgente condivisa e dei gate superati; render dei campi prodotti |
| Materia selezionata completata → prima attiva | Superato, nessun timer avviato |
| Ultima attiva completata → vuoto | Superato; catture Home/Timer/Menu senza attive |
| Riapri → ritorno nelle scelte/esami | Superato sui modelli e sulle sorgenti condivise |
| Sessione attiva completata → continua/salva | Superato con ID e collegamento invariati |
| Modifica sessione di completata | Corrente presente, altre attive; convalida e conservazione del nome verificati dal codice e dai test |
| Prossimi esami/countdown | Esclusione e ripristino superati; Calendario conserva gli esami |
| Voto/data/note legacy | Migrazione da schema reale di prova, idempotenza, persistenza e backup superati |
| Zero/una/molte completate | Casi dati, vuoti e catalogo con 35 materie verificati; render zero/una prodotti |
| Keyboard/VoiceOver e click reali | Non eseguiti; semantica e azioni conservate nel codice |
| Consumo CPU con 30+ materie | Non misurato; cache e assenza di ricostruzioni ripetute verificate |

Opzioni non attivate: media aritmetica e nuovo popover senza freccia. La sequenza conta sette compiti, non tre/quattro come nei refusi del prompt. Tutti i sette interventi di implementazione e verifica automatica sono completati; restano le verifiche manuali esplicitamente elencate.

### File e commit

Compiti 1–2: df9e2a6, db64daa (rapporto separato). Compito 3: e892ebb; Compito 4: ef92462; Compito 5: feee42a; Compito 6: b98e598. Il commit del Compito 7 e il manifesto finale sono allegati nella consegna.

File modificati rispetto alla build 20: Sources/Models/Models.swift; Sources/Services/StudyStore.swift; Sources/Services/BackupService.swift; Sources/Components/Controls.swift; Sources/Components/Style.swift; Sources/Views/RootView.swift; Sources/Views/SubjectsView.swift; Sources/Views/CalendarView.swift; Sources/Views/HistoryView.swift; Sources/Views/StatisticsView.swift; Sources/KomorebiApp.swift; Sources/ThemeResources/Translations.json; Tests/CompletedSubjectsTests.swift; Tests/SubjectEditorTests.swift; Tests/SubjectPolishTests.swift; Tests/SubjectWorkflowRenderTests.swift; Komorebi Study.xcodeproj/project.pbxproj; Docs/Materie-compiti3-7.md; Docs/PASSAGGIO-PROGETTO.md. FILE-MODIFICATI.json fornisce anche il confronto completo dal primo compito.
