%% igs_cap_sizing.m — IGS with Active PMOS Load Optimization
%  ET4252 Analogue Integrated Circuit Design — TU Delft
%  Daniel Tyukov (5714699), Raghavendra Joshi (6438180)
%
%  LOOP 1 (gm/ID loop): Sweep (gm/ID)_n, (gm/ID)_p, CR
%  LOOP 2 (sizing loop): Self-loading iteration per design point
%  OUTPUT: Optimal Wn, Ln, Wp, Lp, all capacitances, performance metrics

clearvars; close all; clc;

%% 1. Load Technology Data
load 180nch.mat;
load 180pch.mat;

%% 2. Specifications
kB   = 1.38e-23;
T    = 300;
VDD  = 1.8;
ed   = 0.1e-2;          % 0.1% dynamic error
ts   = 5.5e-9;          % settling time target [s]
wu   = log(1/ed) / ts;  % required unity-gain frequency [rad/s]
fu   = wu / (2*pi);
Noise = 100e-6;          % 100 uVrms integrated output noise
G    = 2;                % closed-loop gain Cs/CFtot
FO   = 1;                % fan-out CL/CS
ID_max = 500e-6;         % drain current budget [A]

% Noise coefficients
gamma_n = 2/3;
gamma_p = 2/3;

fprintf('fu = %.1f MHz, wu = %.3e rad/s\n\n', fu/1e6, wu);

%% 3. Define Sweep Ranges
gmid_n_vec = 5:0.5:20;         % NMOS gm/ID [S/A]
gmid_p_vec = 3:0.5:15;         % PMOS gm/ID [S/A]
CR_vec     = 0.05:0.05:0.5;    % capacitance ratio

% Preallocate results storage
N_total = length(gmid_n_vec) * length(gmid_p_vec) * length(CR_vec);
res = struct();
fnames = {'gmid_n','gmid_p','CR','Ln','Lp','Wn','Wp','ID','Area', ...
          'DR_dB','ts_actual','eps_s','noise_actual','CLtot','CFtot', ...
          'CS','CL','Cgs','CF','gm_n','Av0','beta'};
for f = fnames, res.(f{1}) = NaN(N_total,1); end
res.feasible = false(N_total,1);

idx = 0;

%% 4. Nested Optimization Loops
for i_n = 1:length(gmid_n_vec)
    gmid_n = gmid_n_vec(i_n);

    % Look up gm/gds and JD vs L for NMOS at this gm/ID
    gm_gds_n_vs_L = look_up(nch, 'GM_GDS', 'GM_ID', gmid_n, 'L', nch.L);
    JD_n_vs_L     = look_up(nch, 'ID_W',   'GM_ID', gmid_n, 'L', nch.L);

    for i_p = 1:length(gmid_p_vec)
        gmid_p = gmid_p_vec(i_p);

        % Noise factor alpha
        gm_ratio = gmid_p / gmid_n;
        alpha = gamma_n + gamma_p * gm_ratio;

        % Look up gm/gds and JD vs L for PMOS at this gm/ID
        gm_gds_p_vs_L = look_up(pch, 'GM_GDS', 'GM_ID', gmid_p, 'L', pch.L);
        JD_p_vs_L     = look_up(pch, 'ID_W',   'GM_ID', gmid_p, 'L', pch.L);

        for i_cr = 1:length(CR_vec)
            CR = CR_vec(i_cr);
            idx = idx + 1;

            beta = 1 / ((1 + G) * (1 + CR));

            % --- Find minimum Ln, Lp satisfying static error ---
            Ln_found = NaN; Lp_found = NaN; Av0_best = NaN;
            JD_n_found = NaN; JD_p_found = NaN;

            for i_L = 1:length(nch.L)
                gn = gm_gds_n_vs_L(i_L);
                jn = JD_n_vs_L(i_L);
                if isnan(gn) || gn <= 0 || isnan(jn) || jn <= 0, continue; end

                for i_Lp = 1:length(pch.L)
                    gp = gm_gds_p_vs_L(i_Lp);
                    jp = JD_p_vs_L(i_Lp);
                    if isnan(gp) || gp <= 0 || isnan(jp) || jp <= 0, continue; end

                    Av0_try = 1 / (1/gn + gm_ratio/gp);
                    if beta * Av0_try >= 12.5
                        Ln_found = nch.L(i_L);
                        Lp_found = pch.L(i_Lp);
                        Av0_best = Av0_try;
                        JD_n_found = jn;
                        JD_p_found = jp;
                        break;
                    end
                end
                if ~isnan(Ln_found), break; end
            end

            if isnan(Ln_found), continue; end

            % --- Noise-derived capacitances (minimum CLtot) ---
            CLtot_noise = (alpha / beta) * kB * T / Noise^2;
            CFtot = CLtot_noise / (FO * G + 1 - beta);
            CS    = G * CFtot;
            CL    = FO * CS;
            Cgs   = CR * (CS + CFtot);

            % --- Self-loading iteration (sizing loop) ---
            % Size gm for actual CLtot including parasitics
            VDS_n = 0.6; VDS_p = 0.6;
            CLtot_est = CLtot_noise;  % initial estimate
            converged = false;

            for iter = 1:50
                % Size for settling at CLtot_est
                gm_n = CLtot_est * wu / beta;
                ID   = gm_n / gmid_n;
                if ID > ID_max, break; end

                Wn = ID / JD_n_found;
                Wp = ID / JD_p_found;

                % Parasitic capacitances
                CGD_W_n = look_up(nch, 'CGD_W', 'GM_ID', gmid_n, 'L', Ln_found, 'VDS', VDS_n);
                CDD_W_n = look_up(nch, 'CDD_W', 'GM_ID', gmid_n, 'L', Ln_found, 'VDS', VDS_n);
                CGD_W_p = look_up(pch, 'CGD_W', 'GM_ID', gmid_p, 'L', Lp_found, 'VDS', VDS_p);
                CDD_W_p = look_up(pch, 'CDD_W', 'GM_ID', gmid_p, 'L', Lp_found, 'VDS', VDS_p);

                if any(isnan([CGD_W_n CDD_W_n CGD_W_p CDD_W_p])), break; end

                Cgd_n = CGD_W_n * Wn;
                Cdb_n = max(CDD_W_n * Wn - Cgd_n, 0);
                Cgd_p = CGD_W_p * Wp;
                Cdb_p = max(CDD_W_p * Wp - Cgd_p, 0);

                % Actual CLtot = noise-derived caps + drain parasitics
                CLtot_new = CL + Cdb_n + Cdb_p + (1 - beta) * CFtot;

                % Check convergence (tight tolerance)
                if abs(CLtot_new - CLtot_est) / CLtot_est < 0.001
                    converged = true;
                    CLtot_est = CLtot_new;
                    break;
                end
                CLtot_est = CLtot_new;
            end

            if ~converged || ID > ID_max, continue; end

            CLtot_actual = CLtot_est;

            % Physical feedback cap
            CF = CFtot - Cgd_n;
            if CF <= 0, continue; end

            % --- Final performance ---
            wu_actual = beta * gm_n / CLtot_actual;
            ts_actual = log(1/ed) / wu_actual;
            eps_s     = 1 / (beta * Av0_best);

            noise_actual = sqrt((alpha / beta) * kB * T / CLtot_actual);

            % Dynamic range
            Vdsat_n = 2 / gmid_n;
            Vdsat_p = 2 / gmid_p;
            Vswing  = VDD - Vdsat_n - Vdsat_p;
            if Vswing <= 0, continue; end
            Vamp  = Vswing / 2;
            P_out = Vamp^2 / 2;
            P_n   = (alpha / beta) * (kB * T / CLtot_actual);
            DR_dB = 10 * log10(P_out / P_n);

            Area = Wn * Ln_found + Wp * Lp_found;

            % --- Check all specs (with floating-point tolerance) ---
            feasible = (ts_actual <= 5.5e-9 * 1.001) && ...
                       (eps_s <= 0.08 * 1.001) && ...
                       (noise_actual <= 100e-6) && ...
                       (ID <= 500e-6) && ...
                       (CF > 0);

            % --- Store ---
            res.gmid_n(idx) = gmid_n;    res.gmid_p(idx) = gmid_p;
            res.CR(idx)     = CR;         res.Ln(idx)     = Ln_found;
            res.Lp(idx)     = Lp_found;   res.Wn(idx)     = Wn;
            res.Wp(idx)     = Wp;         res.ID(idx)     = ID;
            res.Area(idx)   = Area;       res.DR_dB(idx)  = DR_dB;
            res.ts_actual(idx) = ts_actual; res.eps_s(idx) = eps_s;
            res.noise_actual(idx) = noise_actual;
            res.CLtot(idx)  = CLtot_actual; res.CFtot(idx) = CFtot;
            res.CS(idx)     = CS;         res.CL(idx)     = CL;
            res.Cgs(idx)    = Cgs;        res.CF(idx)     = CF;
            res.gm_n(idx)   = gm_n;      res.Av0(idx)    = Av0_best;
            res.beta(idx)   = beta;       res.feasible(idx) = feasible;
        end
    end
end

%% 5. Find Optimum
fi = find(res.feasible);
fprintf('\n=== Found %d feasible design points out of %d ===\n\n', length(fi), N_total);

if isempty(fi)
    % Debug: show closest-to-feasible
    fprintf('DEBUG: Showing top 5 closest designs (by settling time):\n');
    [~, si] = sort(res.ts_actual);
    for k = 1:min(5, length(si))
        j = si(k);
        if isnan(res.ts_actual(j)), continue; end
        fprintf('  gmid_n=%.1f gmid_p=%.1f CR=%.2f | ts=%.2fns eps_s=%.1f%% noise=%.1fuV ID=%.0fuA Area=%.0f\n', ...
            res.gmid_n(j), res.gmid_p(j), res.CR(j), res.ts_actual(j)*1e9, ...
            res.eps_s(j)*100, res.noise_actual(j)*1e6, res.ID(j)*1e6, res.Area(j));
    end
    error('No feasible design found! Check debug output above.');
end

% Among feasible: balance DR maximization with area minimization
% Normalize both metrics to [0, 1] and combine
f_DR   = res.DR_dB(fi);
f_area = res.Area(fi);
DR_norm   = (f_DR - min(f_DR)) / (max(f_DR) - min(f_DR) + eps);
Area_norm = (f_area - min(f_area)) / (max(f_area) - min(f_area) + eps);
FOM = DR_norm - Area_norm;  % maximize DR, minimize area
[~, best_fom] = max(FOM);
bi = fi(best_fom);

% Also print Pareto summary
fprintf('--- Top 5 by balanced FOM (DR vs Area) ---\n');
[~, fom_sort] = sort(FOM, 'descend');
for k = 1:min(5, length(fom_sort))
    j = fi(fom_sort(k));
    fprintf('  gmid_n=%.1f gmid_p=%.1f CR=%.2f | ts=%.2fns eps=%.1f%% noise=%.0fuV ID=%.0fuA Area=%.0f DR=%.1fdB\n', ...
        res.gmid_n(j), res.gmid_p(j), res.CR(j), res.ts_actual(j)*1e9, ...
        res.eps_s(j)*100, res.noise_actual(j)*1e6, res.ID(j)*1e6, res.Area(j), res.DR_dB(j));
end
fprintf('-------------------------------------------\n\n');

%% 6. Print Final Design
fprintf('============================================\n');
fprintf('   OPTIMAL DESIGN PARAMETERS\n');
fprintf('============================================\n');
fprintf('  (gm/ID)_n     = %.1f S/A\n', res.gmid_n(bi));
fprintf('  (gm/ID)_p     = %.1f S/A\n', res.gmid_p(bi));
fprintf('  CR             = %.2f\n', res.CR(bi));
fprintf('  beta           = %.4f\n', res.beta(bi));
fprintf('  Av0            = %.1f\n', res.Av0(bi));
fprintf('--------------------------------------------\n');
fprintf('  Wn             = %.2f um\n', res.Wn(bi));
fprintf('  Ln             = %.3f um\n', res.Ln(bi));
fprintf('  Wp             = %.2f um\n', res.Wp(bi));
fprintf('  Lp             = %.3f um\n', res.Lp(bi));
fprintf('  Area (M1+M2)   = %.1f um^2\n', res.Area(bi));
fprintf('--------------------------------------------\n');
fprintf('  ID             = %.1f uA\n', res.ID(bi) * 1e6);
fprintf('  gm_n           = %.3f mS\n', res.gm_n(bi) * 1e3);
fprintf('--------------------------------------------\n');
fprintf('  CS             = %.3f pF\n', res.CS(bi) * 1e12);
fprintf('  CF (physical)  = %.1f fF\n', res.CF(bi) * 1e15);
fprintf('  CFtot          = %.1f fF\n', res.CFtot(bi) * 1e15);
fprintf('  CL             = %.3f pF\n', res.CL(bi) * 1e12);
fprintf('  CLtot (actual) = %.3f pF\n', res.CLtot(bi) * 1e12);
fprintf('  Cgs            = %.1f fF\n', res.Cgs(bi) * 1e15);
fprintf('--------------------------------------------\n');
fprintf('  Settling time  = %.2f ns  (spec: <= 5.5 ns)\n', res.ts_actual(bi) * 1e9);
fprintf('  Static error   = %.2f %%   (spec: <= 8 %%)\n', res.eps_s(bi) * 100);
fprintf('  Output noise   = %.1f uVrms (spec: <= 100)\n', res.noise_actual(bi) * 1e6);
fprintf('  DR             = %.1f dB\n', res.DR_dB(bi));
fprintf('============================================\n');

%% 7. Optimization Plots
figure('Name', 'DR vs (gm/ID)_p');
m1 = res.feasible & abs(res.gmid_n - res.gmid_n(bi))<0.01 & abs(res.CR - res.CR(bi))<0.001;
if sum(m1) > 1
    plot(res.gmid_p(m1), res.DR_dB(m1), 'b-o', 'LineWidth', 1.5); hold on;
    plot(res.gmid_p(bi), res.DR_dB(bi), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
    xlabel('(g_m/I_D)_p [S/A]'); ylabel('DR [dB]');
    title(sprintf('DR vs PMOS Inversion | (g_m/I_D)_n=%.1f, CR=%.2f', res.gmid_n(bi), res.CR(bi)));
    grid on; legend('Feasible', 'Optimum');
    saveas(gcf, 'plot_DR_vs_gmid_p.png');
end

figure('Name', 'Area vs CR');
m2 = res.feasible & abs(res.gmid_n - res.gmid_n(bi))<0.01 & abs(res.gmid_p - res.gmid_p(bi))<0.01;
if sum(m2) > 1
    plot(res.CR(m2), res.Area(m2), 'b-o', 'LineWidth', 1.5); hold on;
    plot(res.CR(bi), res.Area(bi), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
    xlabel('CR'); ylabel('Area [um^2]');
    title(sprintf('Area vs CR | (g_m/I_D)_n=%.1f, (g_m/I_D)_p=%.1f', res.gmid_n(bi), res.gmid_p(bi)));
    grid on; legend('Feasible', 'Optimum');
    saveas(gcf, 'plot_Area_vs_CR.png');
end

figure('Name', 'Design Space');
scatter(res.DR_dB(fi), res.Area(fi), 20, res.ID(fi)*1e6, 'filled'); hold on;
plot(res.DR_dB(bi), res.Area(bi), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
xlabel('DR [dB]'); ylabel('Area [um^2]');
title('Feasible Design Space'); c = colorbar; c.Label.String = 'I_D [uA]';
grid on; legend('Feasible', 'Optimum');
saveas(gcf, 'plot_Design_Space.png');

%% 8. Comparison Table
fprintf('\n============================================\n');
fprintf('   COMPARISON TABLE (MATLAB vs SPICE)\n');
fprintf('============================================\n');
fprintf('  Parameter              | MATLAB        | SPICE | Error\n');
fprintf('  -----------------------|---------------|-------|------\n');
fprintf('  Wn [um]                | %12.2f  |       |\n', res.Wn(bi));
fprintf('  Ln [um]                | %12.3f  |       |\n', res.Ln(bi));
fprintf('  Wp [um]                | %12.2f  |       |\n', res.Wp(bi));
fprintf('  Lp [um]                | %12.3f  |       |\n', res.Lp(bi));
fprintf('  Total Area [um^2]      | %12.1f  |       |\n', res.Area(bi));
fprintf('  CR                     | %12.2f  |       |\n', res.CR(bi));
fprintf('  DR [dB]                | %12.1f  |       |\n', res.DR_dB(bi));
fprintf('  (gm/ID)_n [S/A]       | %12.1f  |       |\n', res.gmid_n(bi));
fprintf('  (gm/ID)_p [S/A]       | %12.1f  |       |\n', res.gmid_p(bi));
fprintf('  Noise [uVrms]          | %12.1f  |       |\n', res.noise_actual(bi)*1e6);
fprintf('  Settling Time [ns]     | %12.2f  |       |\n', res.ts_actual(bi)*1e9);
fprintf('  Static Error [%%]       | %12.2f  |       |\n', res.eps_s(bi)*100);
fprintf('  ID [uA]                | %12.1f  |       |\n', res.ID(bi)*1e6);
fprintf('============================================\n');
