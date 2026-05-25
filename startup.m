% File: startup.m  (mettilo nella root del progetto)
function startup()
    % Root del progetto ricavata dalla posizione di questo file
    root = fileparts(mfilename('fullpath'));

    % Aggiungo SOLO le cartelle necessarie per il codice core (evita genpath globale)
    addpath(fullfile(root,'src'));
    addpath(fullfile(root,'post'));
    addpath(fullfile(root,'post','utils'));

    % Aggiungo YALMIP includendo tutte le sue sottocartelle (FONDAMENTALE)
    yalmip_path = fullfile(root, 'YALMIP-master');
    if exist(yalmip_path, 'dir')
        addpath(genpath(yalmip_path));
        fprintf('[MG] YALMIP caricato con successo nel Path.\n');
    else
        warning('[MG] ATTENZIONE: Cartella YALMIP-master non trovata nella root!');
    end

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