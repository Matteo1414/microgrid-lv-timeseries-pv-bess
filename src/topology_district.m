%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  topology_district.m               (must run in the same folder)
%
%  Creates in the MATLAB workspace the variables:
%     • N  (number of buses)                  • lineData   (topology)
%     • idxLineMat  (row lookup matrix)       • fromBus, toBus, Zpu (opt.)
%
%  ────────────────────────────────────────────────────────────────────────────
%  WARNING
%  – This file must be executed after Zbase has been defined in the main,
%    so that the function to_pu(L) knows Zbase.
%  – Any change to line lengths or parameters must be done here and will
%    automatically propagate to ALL scripts that call it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% (Topo-1) General data
N = 16;                   % bus 1 = slack

%% (Topo-2) Reference LV line impedance
Z_line_km = 0.20 + 1j*0.15;   % Ω/km   (Cu 4×150 mm² 3-phase 0.4 kV)

%% (Topo-3) Branch lengths (km)
L_1_2  = 0.03;                  % 30 m  → school
L_1_3  = 0.05; L_3_4 = 0.05; L_4_5 = 0.05; L_5_6 = 0.05;           % shops
L_1_7  = 0.15; L_7_8 = 0.08; L_8_9 = 0.08; L_9_10 = 0.08; L_10_11 = 0.08;
L_1_12 = 0.15; L_12_13 = 0.08; L_13_14 = 0.08; L_14_15 = 0.08; L_15_16 = 0.08;

%% (Topo-4) Per-unit conversion
to_pu = @(Lkm) (Z_line_km*Lkm)/Zbase;       % anonymous function (uses Zbase)

Zpu_vec = [
    to_pu(L_1_2)
    to_pu(L_1_3)   ; to_pu(L_3_4) ; to_pu(L_4_5) ; to_pu(L_5_6)
    to_pu(L_1_7)   ; to_pu(L_7_8) ; to_pu(L_8_9) ; to_pu(L_9_10); to_pu(L_10_11)
    to_pu(L_1_12)  ; to_pu(L_12_13); to_pu(L_13_14); to_pu(L_14_15); to_pu(L_15_16)
];

%% (Topo-5) Topology matrix  [from  to   Rpu   Xpu]
lineData = [
    1  2   real(Zpu_vec(1))   imag(Zpu_vec(1));
    1  3   real(Zpu_vec(2))   imag(Zpu_vec(2));
    3  4   real(Zpu_vec(3))   imag(Zpu_vec(3));
    4  5   real(Zpu_vec(4))   imag(Zpu_vec(4));
    5  6   real(Zpu_vec(5))   imag(Zpu_vec(5));
    1  7   real(Zpu_vec(6))   imag(Zpu_vec(6));
    7  8   real(Zpu_vec(7))   imag(Zpu_vec(7));
    8  9   real(Zpu_vec(8))   imag(Zpu_vec(8));
    9 10   real(Zpu_vec(9))   imag(Zpu_vec(9));
   10 11   real(Zpu_vec(10))  imag(Zpu_vec(10));
    1 12   real(Zpu_vec(11))  imag(Zpu_vec(11));
   12 13   real(Zpu_vec(12))  imag(Zpu_vec(12));
   13 14   real(Zpu_vec(13))  imag(Zpu_vec(13));
   14 15   real(Zpu_vec(14))  imag(Zpu_vec(14));
   15 16   real(Zpu_vec(15))  imag(Zpu_vec(15));
];

%% (Topo-6) Helper tables
fromBus = lineData(:,1);
toBus   = lineData(:,2);
Zpu     = lineData(:,3)+1j*lineData(:,4);

% Row lookup → idxLineMat(i,j) = row number corresponding to line i→j
idxLineMat = zeros(N);                % 0 if branch does not exist
for m = 1:size(lineData,1)
    idxLineMat(fromBus(m),toBus(m)) = m;
end
