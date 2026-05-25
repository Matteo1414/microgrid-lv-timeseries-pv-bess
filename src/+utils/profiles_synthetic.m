function [bar,parr,autolav,farm,rist,scu] = profiles_synthetic(t)
% PROFILES_SYNTHETIC - Returns 6 kW vectors (1xNSTEPS) 
% with realistic STOCHASTIC block-based load profiles.

    bar     = f_bar(t);
    parr    = f_parr(t);
    autolav = f_autolav(t);
    farm    = f_farm(t);
    rist    = f_rist(t);
    scu     = f_scu(t);

    % ---------- local functions ----------------------------------------------
    function P = f_bar(tt)
        h = tt/60;
        N = length(tt);
        P = 1.5 * ones(1,N); % Base frigo/vetrine sempre accese
        
        open_idx = find(h>=6.5 & h<=22);
        P(open_idx) = 3 + 0.5*rand(1,length(open_idx)); % Luci e macchinari base
        
        % Macchina Caffè / Piastre (picchi brevi e intensi di 3-5 min)
        for s = 1:randi([30 50]) % Rush mattutino
            st = randi([6*60 11*60]); dur = randi([2 5]); 
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 3 + rand(1, length(idx));
        end
        for s = 1:randi([20 40]) % Rush serale / aperitivo
            st = randi([17*60 21*60]); dur = randi([2 5]);
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 2.5 + rand(1, length(idx));
        end
    end

    function P = f_parr(tt)
        h = tt/60;
        N = length(tt);
        P = 0.5 * ones(1,N); % Stand-by
        
        open_idx = find(h>=9 & h<=19);
        P(open_idx) = 2 + 0.3*rand(1,length(open_idx)); % Luci/Cassa
        
        % Accensione Phon e Caschi (picchi di 1.5-2 kW per 15-30 min)
        for s = 1:randi([15 25])
            st = randi([9*60 18.5*60]); dur = randi([15 30]);
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 1.5 + 0.3*randn(1, length(idx));
        end
    end

    function P = f_autolav(tt)
        rng(23); % Manteniamo il seed fisso come prima per coerenza
        N = length(tt);
        P = 0.5 * ones(1,N); % Pompe in stand-by
        
        % Spruzzi di idropulitrici (15 kW netti per 3-6 minuti)
        for s = 1:randi([8 20])
            st = randi([8*60 20*60]);  dur = randi([3 6]);
            idx = st : min(st+dur, N);
            P(idx) = 15 + 2*randn(1, length(idx));
        end
    end

    function P = f_farm(tt)
        h = tt/60;
        N = length(tt);
        P = 1.2 * ones(1,N); % Frigoriferi per medicinali h24
        
        morn = find(h>=8.5 & h<=13);
        P(morn) = 4 + 0.4*randn(1,length(morn)); % Luci e banchi
        
        aft = find(h>=15.5 & h<=19.5);
        P(aft) = 4.5 + 0.5*randn(1,length(aft));
        
        % Compressori HVAC che attaccano e staccano (1.5 kW step)
        for s = 1:randi([4 8])
            st = randi([8*60 18*60]); dur = randi([20 45]);
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 1.5;
        end
    end

    function P = f_rist(tt)
        h = tt/60;
        N = length(tt);
        P = 2.5 * ones(1,N); % Celle frigorifere h24
        
        % Base Preparazione e Servizio
        prep1 = find(h>=10 & h<12); P(prep1) = 6 + 1.5*randn(1,length(prep1));
        lunch = find(h>=12 & h<15.5); P(lunch) = 18 + 2*randn(1,length(lunch));
        prep2 = find(h>=18 & h<20); P(prep2) = 8 + 1.5*randn(1,length(prep2));
        din   = find(h>=20 & h<23.5); P(din) = 22 + 3*randn(1,length(din));
        
        % Forni e Lavastoviglie industriali (botte da 5-8 kW per 10-20 min)
        for s = 1:randi([8 15])
            st = randi([12*60 14.5*60]); dur = randi([10 20]);
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 5 + 1.5*randn(1, length(idx));
        end
        for s = 1:randi([12 20])
            st = randi([20*60 23*60]); dur = randi([10 20]);
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 6 + 2*randn(1, length(idx));
        end
    end

    function P = f_scu(tt)
        h = tt/60;
        N = length(tt);
        P = 1.5 * ones(1,N); % Server, UPS, allarmi notturni
        
        open_idx = find(h>=7.5 & h<=14.5);
        P(open_idx) = 10 + 1.5*randn(1,length(open_idx)); % Illuminazione e uffici
        
        % Cicli Impianto di Condizionamento/Riscaldamento (ON 20min, OFF 40min)
        for st = 7.5*60 : 60 : 14*60
            idx = st : min(st+20, N);
            P(idx) = P(idx) + 8;
        end
        
        % Accensione aule informatica / Laboratori (4 kW per 45-60 min)
        for s = 1:4 
            st = randi([8*60 13*60]); dur = randi([45 60]); 
            idx = st : min(st+dur, N);
            P(idx) = P(idx) + 4 + randn(1, length(idx));
        end
    end
end