function [bar,parr,autolav,farm,rist,scu] = profiles_synthetic(t)
% Returns 6 kW vectors (1×NSTEPS)

bar      = f_bar(t);
parr     = f_parr(t);
autolav  = f_autolav(t);
farm     = f_farm(t);
rist     = f_rist(t);
scu      = f_scu(t);

% ---------- local functions ----------------------------------------------
function P = f_bar(tt)
h = tt/60;
P = 2 + 8*exp(-((h-7).^2)/1.2) + 6*exp(-((h-12).^2)/4) ...
      + 5*exp(-((h-19).^2)/1.8);
P(h<6 | h>22) = 0.8;
P = P.*(1+0.05*randn(size(P)));
end

function P = f_parr(tt)
h = tt/60;
P = 1.5 + 3*exp(-((h-10).^2)/4) + 3.5*exp(-((h-16).^2)/3);
P(h<9 | h>19) = 0.3;
P = P.*(1+0.08*randn(size(P)));
end

function P = f_autolav(tt)
rng(23);
P = 0.5*ones(size(tt));
for s = 1:randi([8 20])
    st = randi([8*60 20*60]);  dur = randi([3 6]);
    P(st:st+dur) = 15 + 2*randn;
end
end

function P = f_farm(tt)
h = tt/60;
P = 0.8 + 2*exp(-((h-11).^2)/2) + 2.5*exp(-((h-17).^2)/2);
P((h<8.5)|(h>19)|(h>13 & h<15.5)) = 0.6;
end

function P = f_rist(tt)
h = tt/60;
P = 5 + 25*exp(-((h-12.5).^2)/2) + 30*exp(-((h-20).^2)/1.5);
P(h<10 | h>23.5) = 2;
P = P.*(1+0.07*randn(size(P)));
end

function P = f_scu(tt)
h = tt/60;
P = 3 + 18*exp(-((h-11).^2)/3);
P(h<7.5 | h>14.5) = 1;
end
end
