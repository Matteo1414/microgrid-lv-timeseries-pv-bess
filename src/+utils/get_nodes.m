function nodes = get_nodes(A)
% utils.get_nodes  Return a vector with the .node fields of a struct array
%
%   nodes = utils.get_nodes(PV)

    if isempty(A)
        nodes = [];
    else
        nodes = [A.node];     % assumes .node exists
    end
end
