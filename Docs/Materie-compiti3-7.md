# Materie completate — compiti 3–7

## Compito 3

Backup personale creato **prima delle modifiche allo schema**, tramite SQLite backup API in sola lettura: `/Users/ale/Library/Application Support/Komorebi Study/Backups/Pre-completamento-20261024-094409`. Integrità della copia verificata. Nessuna migrazione è stata eseguita sul database personale durante lo sviluppo.

La build aggiunge campi opzionali gradeValue, gradeHonors, gradeNote, completedAt e completionVersion. Il testo grade precedente resta intatto. Migrazione idempotente: solo interi 18–30 diventano voto numerico; ogni altro testo resta esatto nella nota. Nessuna lode dedotta automaticamente da testo libero. Data delle completate precedenti = fine dell’ultima sessione associata, altrimenti nil. Per nuove completate viene assegnata la data corrente. La riapertura conserva voto/data/note.

All’avvio reale la nuova build controlla lo schema in sola lettura e crea una nuova copia SQLite e delle preferenze prima di aprire ModelContainer se mancano colonne o record migrati. Fallire il backup impedisce di proseguire. I backup automatici sono nella sottocartella Backups dell’archivio, prefisso SubjectCompletion; gli import legacy hanno prefisso SubjectImport. I backup JSON includono tutti i campi e mantengono il vecchio formato leggibile.

Introdotta la sorgente activeSubjects/completedSubjects nello store, aggiornata al salvataggio solo se la firma dei dati delle materie cambia. Home e Timer usano la sorgente attiva; preparedSubject ripiega sulla prima attiva. Completare una materia non modifica il timer già attivo o la sua sessione salvata. I totali di consultazione restano intatti; solo il progresso dell’obiettivo settimanale esclude le completate, mantenendo il valore dell’obiettivo impostato dall’utente. Non si sottrae la durata degli obiettivi delle materie dal target generale, essendo due impostazioni indipendenti. Calendario e pigmenti invariati.

Verifica: 154 test Release, zero errori, uno saltato per fixture facoltativa. Compresi: migrazione SQLite da modello congelato build 20, copia prima dell’aggiunta delle colonne, caso Misure Elettroniche voto 18, date mancanti, note preservate, idempotenza, sessione attiva, esclusione dal solo obiettivo settimanale e cache invariata ai tick/refresh senza modifiche alle materie.
