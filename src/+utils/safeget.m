function out = safeget(S, fieldName)
% utils.safeget  Return S.(fieldName) if it exists, otherwise struct([])
%
%   out = utils.safeget(S,'PV')

    if isfield(S, fieldName)
        out = S.(fieldName);
    else
        out = struct([]);        % empty struct compatible with get_nodes
    end
end
