# Microgrid District Simulator (PV + BESS)
**Manuale Operativo per Simulazioni e Analisi Dati**

Questo progetto simula il comportamento elettrico e l'Energy Management System (EMS) di un distretto residenziale e commerciale in Bassa Tensione, dotato di Generazione Distribuita (impianti fotovoltaici) e Sistemi di Accumulo (BESS). Il motore matematico risolve il Power Flow radiale minuto per minuto (1440 flussi al giorno) basandosi sull'algoritmo **Backward/Forward Sweep (BFS)** e sul **Modello PQ** per le utenze.

---

## 🎯 Architettura e Funzionalità Principali

* **Generazione Scenari Dinamica:** Gli asset topologici (Scenari 0-4) e le varianti di dimensionamento vengono costruiti e aggiornati automaticamente dallo script `create_scenarios.m`.
* **Continuità Termodinamica:** Il passaggio dello Stato di Carica (SOC) della batteria tra la mezzanotte del giorno d e le 00:00 del giorno d+1 è garantito senza discontinuità logiche tramite `run_district_range.m`.
* **Gestione EMS (Rule-Based):** Logica istantanea ("Greedy") per il *peak-shaving* locale, nel rigido rispetto dei limiti hardware dell'inverter (S_max) e chimici delle celle.
* **Vettorizzazione del Sizing:** Capacità di scalare proporzionalmente l'hardware (PV e BESS) tramite un moltiplicatore k per l'analisi di sensitività e la ricerca dell'ottimo ingegneristico.
* **Bilancio al Punto di Consegna (PoC):** Misurazione rigorosa dello scambio energetico al trasformatore MT/BT, depurato dall'effetto di mascheramento dei carichi locali per calcoli di autosufficienza termodinamica precisi al 100%.

---

## 🛠️ OPZIONE 1: La Simulazione Automatica (Consigliata)
Usa questa opzione per orchestrare intere campagne di simulazione (es. un intero anno solare) e generare i risultati grezzi definitivi della tesi.

1. Apri MATLAB e posizionati nella directory root del progetto.
2. Apri lo script `main.m`. Questo file funge da "Supervisore Globale".
3. **Imposta i parametri temporali:** Definisci l'anno (`ANNO`), il giorno di inizio (`GIORNO_INIZIO`) e il giorno di fine (`GIORNO_FINE`).
4. **Configura i selettori di ricerca (Interruttori Booleani):**
   * `ESEGUI_TOPOLOGIA = true/false;` (Esegue l'evoluzione spaziale, Scenari da 0 a 4).
   * `ESEGUI_SENSITIVITA = true/false;` (Esegue l'analisi sul dimensionamento scalando la taglia base dello Scenario 4 con il vettore k = 0.5 : 0.1 : 1.2).
5. Premi **Run** (F5).

> **Nota di Ottimizzazione (Soppressione Doppioni):**
> Il `main.m` unisce le due *playlist* in modo intelligente. Qualora vengano attivati entrambi gli interruttori booleani, l'algoritmo intercetta e sopprime in totale autonomia gli scenari matematicamente identici (es. lo Scenario 4 base e lo Scenario di Sensitività con fattore k=1.0), evitando il ricalcolo inutile di centinaia di migliaia di flussi di potenza. I risultati grezzi giornalieri verranno salvati in formato `.mat` nella cartella `results/daily/`.

---

## 📊 OPZIONE 2: Post-Processing e Analisi Dati
Una volta completata la simulazione automatica, i dati grezzi devono essere elaborati per estrarre i KPI (Key Performance Indicators) e generare i grafici di tesi.

### 2.1 Analisi Globale Annuale (Master Script)
Per generare tutti i report CSV definitivi (mensili e annuali) e i grafici macroscopici, esegui dalla Command Window:
run_all_postprocessing

Questo script esegue un'analisi a cascata su tutti i dati salvati e popola automaticamente la cartella `results/summary/` con le tabelle dell'autosufficienza, dell'autoconsumo e delle perdite Joule. Inoltre, salverà nella cartella `figs/summary/` i grafici di sensitività e le distribuzioni mensili.

### 2.2 Analisi Visiva Giornaliera (Smoke Test)
Se desideri generare o aggiornare esclusivamente i grafici di una singola giornata (es. profili di tensione Heatmap, vero scambio Slack P/Q, profili SOC) senza dover ricalcolare l'intero anno, utilizza la funzione di smoke test. 
Dalla Command Window, digita (es. per il 16 Luglio, giorno 197):
smoke_test_day(197, {'scn1_3PV.mat', 'scn4_k100.mat'}, 2023);

Le immagini ad alta risoluzione verranno sovrascritte e salvate nelle rispettive cartelle all'interno di `figs/`.

---

## 🔬 OPZIONE 3: Simulazione Manuale Singolo Giorno (Per Debugging)
Questa opzione è ideale per isolare un problema nel risolutore di rete, testare una nuova logica dell'EMS o analizzare un transitorio critico su un giorno specifico saltando il `main.m`.

Nella *Command Window* di MATLAB, digita:

% 1. Prepara l'ambiente e le path necessarie
startup()

% 2. Genera o aggiorna manualmente i file .mat degli scenari
create_scenarios()

% 3. Lancia il risolutore giornaliero (Es. Giorno 197 - 16 Luglio)
% Parametri: (Giorno, Nome_Scenario, SOC_iniziale)
[outFN, SOC_end] = run_district_day(197, 'scn4_k100.mat', 0.50);