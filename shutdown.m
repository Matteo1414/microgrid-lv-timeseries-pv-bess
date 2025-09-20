% File: shutdown.m  (root del progetto)
function shutdown()
    root = getenv('MG_ROOT');
    if isempty(root) || ~isfolder(root), return; end

    rmpath( fullfile(root,'src'), ...
            fullfile(root,'post'), ...
            fullfile(root,'post','utils') );

    fprintf('[MG] Paths removed. Root: %s\n', root);
end
