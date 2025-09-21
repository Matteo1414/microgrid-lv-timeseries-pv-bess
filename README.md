# microgrid-lv-timeseries-pv-bess

Time-series LV microgrid (400 V, 16-bus) with PV+BESS — BFS power flow, robust KPIs, and a fully reproducible pipeline (Rome 2023). MATLAB.

- **Docs (quick start & features):** [`docs/README.md`](docs/README.md)  
- **📄 One-pager:** [PDF](docs/One_pager.pdf)  
- **License:** MIT


[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=Matteo1414/microgrid-lv-timeseries-pv-bess)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)




## Run in 30 seconds
```matlab
startup
create_scenarios             % crea gli scenari .mat in data/scenarios/
[outFN, SOC_end] = run_district_day(32, 'scn4_8PV_4BESS.mat');
post_process_day(2023, 32, 'scn4_8PV_4BESS.mat');
```
