=========================================================================
⚡ MICROGRID DISTRICT SIMULATOR & ADVANCED MPC OPTIMIZER
=========================================================================
Operational Manual for Simulations, Optimization, and Stress Testing
Developed by: Matteo Baldini (Master's Thesis in Mechanical Engineering)
Core Time Resolution: 1 minute (1440 steps/day)
Predictive Engine Resolution: 15 minutes (96 steps/day)
=========================================================================

This software simulates and optimizes the thermo-electrical behavior and the Energy Management System (EMS) of a 16-bus LV radial distribution network equipped with distributed solar PV generation and electrochemical storage systems (BESS).

The simulator integrates a proprietary electrical solver based on the Backward/Forward Sweep (BFS) algorithm and a global predictive engine driven by convex Quadratic Programming (QP) paired with local reactive power regulation (STATCOM).

-------------------------------------------------------------------------
📂 REPOSITORY STRUCTURE AND DATA FLOW
-------------------------------------------------------------------------
/microgrid-lv-timeseries-pv-bess
├── startup.m             # Initializes Paths, YALMIP, and environment variables
├── shutdown.m            # Cleans up environment paths at session end
├── main.m                # Global Supervisor for baseline simulations (Greedy)
├── main_mpc.m            # Global Supervisor for predictive optimization (EMPC)
├── run_master_stresstests.m # Master script for Topological & Load Stress Tests
│
├── data/                 # Raw PVGIS datasets (Rome 2023) & Stochastic load profiles
├── src/                  # Physical and mathematical core files
│   ├── bfs_powerflow_radial1.m # Topological radial power flow solver (BFS)
│   ├── run_district_day.m      # 1-min baseline daily simulation engine
│   ├── run_district_day_mpc.m  # 1-min daily engine driven by EMPC + STATCOM
│   └── +utils/
│       ├── empc_optimizer.m    # YALMIP QP Formulation (Gurobi Solver)
│       ├── get_forecast_15min.m # 15-minute aggregated forecast extractor
│       └── dispatch_bess.m     # Instantaneous EMS logic (Greedy dispatch)
│
├── post/                 # Statistical analysis and KPI generation scripts
├── results/              # Output raw data (.mat) and aggregated tables (.csv)
└── figs/                 # Voltage heatmaps and automated thesis plots

-------------------------------------------------------------------------
🛠️ OPERATIONAL MODE 1: Baseline Instantaneous Simulation (Greedy)
-------------------------------------------------------------------------
Use this mode to evaluate the standard grid behavior under reactive rule-based logic (batteries instantly chase load surplus/deficit).

1. Open MATLAB in the project root folder and execute the setup script:
   >> startup()
2. Open and configure the 'main.m' script:
   - Define the time window via 'GIORNO_INIZIO' and 'GIORNO_FINE'.
   - Enable/Disable the simulation tracks using the boolean switches:
     * `ESEGUI_TOPOLOGIA = true/false;` (Simulates evolutionary scenarios 0 to 4).
     * `ESEGUI_SENSITIVITA = true/false;` (Simulates sizing variations scaling via k factor).
3. Run the script (F5). The algorithm automatically detects and suppresses duplicate scenarios to optimize computation time. Raw outputs are saved in 'results/daily/'.

-------------------------------------------------------------------------
🧠 OPERATIONAL MODE 2: Global Predictive Optimization (MPC)
-------------------------------------------------------------------------
Use this mode to execute the core advanced algorithmic framework: the Day-Ahead optimizer built via YALMIP and Gurobi, paired with local closed-loop Q-V STATCOM control.

1. Ensure Gurobi Optimizer is properly licensed and active on your machine.
2. Initialize environment paths:
   >> startup()
3. Open 'main_mpc.m' and set the critical days to evaluate (e.g., Day 196 for summer peak or 357 for winter load electrification).
4. Run the script. The workflow automatically executes three sequential steps:
   - Step 1 (Forecaster): Aggregates loads and PV profiles into 15-minute intervals.
   - Step 2 (YALMIP): Solves the QP problem minimizing OPEX and peaks, utilizing Slack variables (Big-M method) and soft constraints to ensure 100% feasibility.
   - Step 3 (Power Flow): Zero-Order Hold expands setpoints to 1-minute resolution, executing the BFS power flow with integrated Volt-VAR Droop Control (+-2% deadband).
5. Advanced outputs are stored in 'results/daily_mpc/'.

-------------------------------------------------------------------------
🔬 OPERATIONAL MODE 3: Diagnostic Stress Testing Suites
-------------------------------------------------------------------------
Use this mode to push the network infrastructure beyond its nominal boundaries and validate the resilience of the predictive control compared to the heuristic baseline.

1. To run the complete diagnostic stress suite, execute:
   >> run_master_stresstests
2. The script automatically coordinates two distinct campaigns:
   - TEST 1 (Topological Stress - Day 97): Scales the 'L_scale' multiplier to increase line impedance. Evaluates the *Voltage Rise* phenomenon, highlighting the distributed Greedy control degradation paradox.
   - TEST 2 (Load Stress - Day 357): Scales the 'Load_scale' multiplier up to $6\times$ the nominal value. Evaluates *Voltage Drop* prevention and quantifies the Load Hosting Capacity expansion (+18.2%).

-------------------------------------------------------------------------
📊 POST-PROCESSING AND AUTOMATED REPORTING
-------------------------------------------------------------------------
The software features dedicated automation utilities to convert raw data into publication-ready figures and tables.

- To process baseline files and export annual/monthly KPIs:
  >> run(fullfile('post', 'run_all_postprocessing.m'))
- To process MPC files and export the corresponding CSV data:
  >> run(fullfile('post', 'run_all_postprocessing_mpc.m'))
- To generate advanced battery health diagnostics (SOC vs Power scatter plots, Safe Operating Area analysis, and energy throughput per zone):
  >> plot_battery_health
- To evaluate a single day with quick visual outputs (Voltage heatmaps, true PoC net exchange):
  >> smoke_test_day(Day, {'Scenario_Name.mat'}, Year)
