# ⚡ Microgrid District Simulator & MPC Optimizer

![MATLAB](https://img.shields.io/badge/MATLAB-R2023a-blue.svg)
![Optimization](https://img.shields.io/badge/Solver-Gurobi%20%7C%20YALMIP-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

> **Advanced time-series simulator for Low Voltage (LV) microgrids featuring Backward/Forward Sweep (BFS) power flow, Rule-Based BESS dispatch, and Model Predictive Control (MPC) optimization.**

This repository contains the complete source code developed for my Master's Thesis in Mechanical Engineering (110/110 cum laude). The project demonstrates how advanced predictive algorithms can overcome the physical limits of traditional electrical grids under high renewable penetration and extreme load electrification.

## 🚀 Core Features

* **Custom Power Flow Engine:** Robust implementation of the topological **Backward/Forward Sweep (BFS)** algorithm, overcoming the limitations of Newton-Raphson in highly resistive LV networks (high R/X ratio).
* **High-Resolution Time-Series:** 1-minute resolution dynamic modeling capturing severe power gradients, cloud transients, and real-world BESS electrochemical stress.
* **Model Predictive Control (MPC):** Day-Ahead optimal scheduling built with **YALMIP** and solved via **Gurobi**. Features asymmetric quadratic peak-shaving, OPEX minimization, and Soft Constraints (Big-M method) to guarantee 100% mathematical feasibility.
* **Active Voltage Regulation:** Local Volt-VAR droop control simulating STATCOM capabilities via bidirectional inverters to actively mitigate *Voltage Rise* and *Voltage Drop* anomalies.

## 📂 Repository Structure

The architecture is highly modular, separating raw data, core physics, and post-processing:

    microgrid-lv-timeseries-pv-bess/
    ├── data/           # Load profiles (Markov-chain based) & PVGIS solar data
    ├── docs/           # Documentation and related reports
    ├── post/           # Data analysis, KPI generation, and plotting scripts
    ├── src/            # Core simulation engine and solver functions
    │   ├── bfs_powerflow_radial1.m    # BFS Solver
    │   ├── run_district_day.m         # 1-min baseline simulation engine
    │   ├── run_district_day_mpc.m     # MPC-driven simulation engine
    │   └── +utils/                    # Dispatch, forecasting, and YALMIP optimizer
    ├── startup.m       # Path initialization script
    └── shutdown.m      # Environment cleanup script

## ⚙️ How to Run

1. Clone the repository to your local machine.
2. Ensure **MATLAB**, **YALMIP**, and the **Gurobi Optimizer** are installed.
3. Run `startup.m` in the MATLAB command window to initialize environment variables and add subfolders to the path.
4. **Baseline Heuristic Simulation:** Execute `src/main.m` to run the standard rule-based scenarios.
5. **Predictive Control Simulation:** Execute `src/main_mpc.m` to run the advanced MPC optimization.
6. **Diagnostics:** Run the stress test scripts to evaluate topological and load weaknesses.

## 📊 Key Engineering Outcomes

By shifting from a standard heuristic control approach to the MPC architecture, the system achieved:
* **-21.9% reduction in Joule heating losses** on cables due to smoothed current ramps.
* **+18.2% increase in Load Hosting Capacity**, preventing grid voltage collapse during extreme winter electrification scenarios ($5.2\times$ load stress).
* Total suppression of terminal node overvoltages ($>1.10$ p.u.) during summer solar peaks, maintaining the infrastructure strictly within safety standards.
