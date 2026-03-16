clearvars;
close all;

% Technology
load 180nch.mat

% Specs
kB = 1.38e-23; T = 300;
ed = 0.1e-2;
ts = 5.5e-9;
tau = ts/log(1/ed);
wu = 1/tau; fu = wu/2/pi
Noise = 100e-6;
G = 2; FO = 1;
L0 = 20;

% Design choices
alpha = 0.84;
CR = 0.33;
beta = 1/(1+G)/(1+CR)
gm_gds = look_up(nch,'GM_GDS', 'GM_ID', 10, 'L', nch.L);
L = interp1(gm_gds, nch.L, L0/beta)

% Compute CLtot (and all other capacitances) based on noise
CLtot = alpha/beta * kB*T/Noise^2
CFtot = CLtot / (FO*G + 1-beta)
CS = G*CFtot
CL = FO*CS
Cgs = CR*(CS+CFtot)

% Compute gm and device size
gm = CLtot*wu/beta
gm_ID = look_up(nch,'GM_ID', 'GM_CGS', gm/Cgs, 'L', L)
ID = gm/gm_ID
JD = look_up(nch,'ID_W', 'GM_ID', gm_ID, 'L', L);
W = ID/JD

% Calculate CF (for netlist entry) and estimate self loading
CGD_W = look_up(nch, 'CGD_W', 'GM_ID', gm_ID, 'L', L, 'VDS', 0.6);
Cgd = CGD_W*W
CF = CFtot - Cgd
CDD_W = look_up(nch, 'CDD_W', 'GM_ID', gm_ID, 'L', L, 'VDS', 0.6);
Cdb = CDD_W*W - Cgd
wu_actual = beta*gm/(CLtot+Cdb);
ts_actual = 1/wu_actual*log(1/ed)


% HSpice plots
% h = loadsig('igs_cap2.tr0');
% t = evalsig(h,'TIME'); t0 = 1e-9;
% vo_raw = evalsig(h,'v_vo');
% vo = vo_raw - vo_raw(1);
% plot(t-t0, vo); xlim([-1 19]*1e-9)
% xlabel('Time (s)'); ylabel('v_o_u_t (V)'); grid;
% text(1.5e-8, 17e-3, sprintf('%d', vo(end)))
% 
% dyn_err = abs((vo - vo(end))/vo(end)); ed = 0.1e-2;
% idx = find(dyn_err<=ed, 1, 'first');
% ts = interp1(dyn_err(idx-3:idx+3), t(idx-3:idx+3), ed, 'pchip');
% semilogy(t-t0, dyn_err, ts-t0, ed, 'o'); xlim([-1 10]*1e-9); ylim([1e-5 10]);
% xlabel('Time (s)'); ylabel('Dynamic error'); grid;
% text(6e-9, ed, sprintf('%d', ts-t0))
% 
% m = loadsig('igs_cap2.ac0');
% f     = evalsig(m, 'HERTZ');
% no    = evalsig(m, 'outnoise');
% ni    = evalsig(m, 'innoise');
% integ = cumtrapz(f, no);
% integ_sqrt = sqrt(integ);
% integ_final = integ_sqrt(end)
% semilogx(f, integ_sqrt)


