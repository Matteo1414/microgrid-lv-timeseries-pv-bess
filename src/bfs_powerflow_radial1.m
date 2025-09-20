%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bfs_powerflow_radial1.m   (optimized)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [V_sol, I_branches, iter, success] = bfs_powerflow_radial1( ...
        lineData, P, Q, V_init, Vslack, angSlack, maxIter, toll)

N      = numel(P);
nLines = size(lineData,1);
success = false;

fromBus = lineData(:,1);
toBus   = lineData(:,2);
Zpu     = lineData(:,3) + 1j*lineData(:,4);

% -------- precomputed row-index (NxN) ------------------------------------
idxLineMat = zeros(N);                 % 0 if non-existent
for m = 1:nLines
    idxLineMat(fromBus(m),toBus(m)) = m;
end

% -------- parent / children ----------------------------------------------
parent   = zeros(N,1);
children = cell(N,1);
for m = 1:nLines
    parent(toBus(m))      = fromBus(m);
    children{fromBus(m)}  = [children{fromBus(m)}, toBus(m)];
end

% -------- initializations -------------------------------------------------
V          = V_init;
I_branches = complex(NaN(nLines,1),NaN(nLines,1));

% -------- BFS iterations --------------------------------------------------
for iter = 1:maxIter
    % ---------- BACKWARD SWEEP -------------------------------------------
    I_inj = zeros(N,1);
    for k = 2:N
        if V(k) ~= 0
            I_inj(k) = conj((P(k)+1j*Q(k))/V(k));
        end
    end

    nodeList = getNodeListFromLeaves(parent,1);
    for tbus = nodeList
        if tbus == 1, continue; end
        fbus = parent(tbus);

        iLine = I_inj(tbus);
        I_inj(fbus) = I_inj(fbus) + iLine;

        idx = idxLineMat(fbus,tbus);
        I_branches(idx) = iLine;
    end

    % ---------- FORWARD SWEEP --------------------------------------------
    V_new    = V;
    V_new(1) = Vslack*exp(1j*angSlack);

    nodeListFwd = getNodeListFromSlack(children,1);
    for cNode = nodeListFwd
        fNode  = parent(cNode);
        idx    = idxLineMat(fNode,cNode);
        V_new(cNode) = V_new(fNode) - I_branches(idx)*Zpu(idx);
    end

    % ---------- Convergence ----------------------------------------------
    if max(abs(V_new - V)) < toll
        success = true;  V = V_new;  break;
    end
    V = V_new;
end

V_sol = V;

end  % ---------- end function --------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nodeList = getNodeListFromLeaves(parent,slackBus)
N = numel(parent);
isLeaf = true(N,1);  isLeaf(slackBus)=false;
for k = 1:N
    if parent(k)>0, isLeaf(parent(k)) = false; end
end
stack = find(isLeaf).'; visited=false(N,1); nodeList=[];
while ~isempty(stack)
    t = stack(end); stack(end)=[];
    if ~visited(t)
        nodeList=[nodeList,t]; visited(t)=true;
        p = parent(t);
        if p>0 && ~visited(p), stack=[stack,p]; end
    end
end
nodeList = unique(nodeList,'stable');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nodeListFwd = getNodeListFromSlack(children,slackBus)
queue = slackBus; visited=false(numel(children),1); visited(slackBus)=true;
nodeListFwd=[];
while ~isempty(queue)
    f = queue(1); queue(1)=[]; %#ok<AGROW>
    for c = children{f}
        if ~visited(c)
           nodeListFwd=[nodeListFwd,c]; queue=[queue,c]; visited(c)=true; %#ok<AGROW>
        end
    end
end
end
