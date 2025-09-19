# Microgrid LV Time-Series (PV + BESS) — Rome

**One-minute low-voltage microgrid simulator** with distributed PV and BESS,  
Backward/Forward Sweep power flow, robust KPI pipeline (daily → monthly → annual),  
and reproducible plots for papers and reports. MATLAB code.

> **📄 One-pager:** [PDF](/docs/One_pager.pdf)

---

## Features

- **Radial LV network** (16 buses, 400 V); BFS solver (`src/bfs_powerflow_radial1.m`)
- **PV**: PVGIS Rome 2023 (kW per 1 kWp), hourly → 1-min PCHIP
- **BESS**: P-only baseline dispatch with SOC-safe limits (10–95%), efficiency `η_c/η_d`, dead-band
- **Stateful SOC** across days (`src/run_district.m`, `src/run_district_range.m`)
- **KPIs**: import/export, PV, losses, self-sufficiency, self-consumption (`post/utils/energy_balance.m`)
- **Verification**: time-series vs robust energy balance; voltage-limit assertions (`verify_day_robust.m`)
- **Reproducibility**: deterministic seeds for synthetic loads; clean startup/shutdown

---

## Quick start

> Requirements: **MATLAB R2022b+** (tested). Nessun toolbox richiesto per il core.

1) **Clone e setup path**
```matlab
startup
create_scenarios ```

2) **Run one day (1-min step)**

```
[outFN, SOC_end] = run_district_day(32, 'scn4_8PV_4BESS.mat');```
