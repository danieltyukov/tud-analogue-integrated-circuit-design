% HW2 Part D - Extract ID and gm using lookup tables
% Compare with LTSpice simulation from Part C
clearvars;

% Load NMOS lookup table
load('180nch.mat');

% Target operating point (same as Part C)
VGS = 0.75;    % V
VDS = 1.5;     % V
L   = 0.7;     % um
W   = 20;      % 20 um (lookup table uses um)

% Extract current density ID/W [A/m]
id_w = look_up(nch, 'ID_W', 'VGS', VGS, 'VDS', VDS, 'L', L);

% Drain current
ID = id_w * W;

% Extract gm/ID ratio [S/A]
gm_id = look_up(nch, 'GM_ID', 'VGS', VGS, 'VDS', VDS, 'L', L);

% Transconductance
gm = gm_id * ID;

% LTSpice reference values (from Part C)
ID_ltspice = 357.681e-6;  % A
gm_ltspice = 2.09e-3;     % S

% Display results
fprintf('=== Part D: Lookup Table Results ===\n');
fprintf('W/L = 20um / 0.7um, VGS = 0.75V, VDS = 1.5V\n\n');
fprintf('ID/W  = %.4e A/m\n', id_w);
fprintf('ID    = %.2f uA\n', ID*1e6);
fprintf('gm/ID = %.2f S/A\n', gm_id);
fprintf('gm    = %.4f mS\n\n', gm*1e3);
fprintf('=== Comparison with LTSpice ===\n');
fprintf('         Lookup Table    LTSpice       Error\n');
fprintf('ID:      %.2f uA      %.2f uA     %.2f%%\n', ...
    ID*1e6, ID_ltspice*1e6, (ID - ID_ltspice)/ID_ltspice * 100);
fprintf('gm:      %.4f mS      %.4f mS     %.2f%%\n', ...
    gm*1e3, gm_ltspice*1e3, (gm - gm_ltspice)/gm_ltspice * 100);
