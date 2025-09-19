# microgrid-lv-timeseries-pv-bess

Time-series LV microgrid (400 V, 16-bus) with PV+BESS — BFS power flow, robust KPIs, and a fully reproducible pipeline (Rome 2023). MATLAB.

- **Docs (quick start & features):** [`docs/README.md`](docs/README.md)  
- **📄 One-pager:** [PDF](docs/One_pager.pdf)  
- **License:** MIT

## Run in 30 seconds
```matlab
startup
create_scenarios
[outFN, SOC_end] = run_district_day(32, 'scn4_8PV_4BESS.mat');
post_process_day(2023, 32, 'scn4_8PV_4BESS.mat');
```
