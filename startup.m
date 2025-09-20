% File: startup.m  (mettilo nella root del progetto)
function startup()
    % Root del progetto ricavata dalla posizione di questo file
    root = fileparts(mfilename('fullpath'));

    % Aggiungo SOLO le cartelle necessarie (evita genpath)
    addpath(fullfile(root,'src'));
    addpath(fullfile(root,'post'));
    addpath(fullfile(root,'post','utils'));

    % Cartelle output (idempotente)
    mk(fullfile(root,'results','daily'));
    mk(fullfile(root,'results','summary'));
    mk(fullfile(root,'figs'));

    % Espongo la root a fine sessione (serve per shutdown)
    setenv('MG_ROOT', root);

    fprintf('[MG] Paths ready. Root: %s\n', root);

    % helper locale
    function mk(p), if ~exist(p,'dir'), mkdir(p); end, end
end
