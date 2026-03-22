%% plot_noise_integral.m — Running output noise integral from SPICE data
%  Reads exported LTSpice noise data and computes cumulative RMS

clearvars; close all; clc;

%% Load SPICE noise data
data = readmatrix('igs_pmos_load.txt', 'NumHeaderLines', 1);
f = data(:,1);           % frequency [Hz]
Svn = data(:,2);         % V(onoise) spectral density [V/sqrt(Hz)]
Svn_sq = Svn.^2;         % noise PSD [V^2/Hz]

%% Running integral (cumulative RMS noise)
noise_sq_cumul = cumtrapz(f, Svn_sq);
noise_rms_cumul = sqrt(noise_sq_cumul);

fprintf('Total integrated noise (SPICE): %.2f uVrms\n', noise_rms_cumul(end)*1e6);

%% Plot
figure('Position', [100 100 700 400], 'Color', 'w');
semilogx(f, noise_rms_cumul * 1e6, 'b-', 'LineWidth', 2);
hold on;

% Mark the final value
plot(f(end), noise_rms_cumul(end)*1e6, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
text(f(end)/5, noise_rms_cumul(end)*1e6 + 3, ...
    sprintf('%.1f \\muVrms', noise_rms_cumul(end)*1e6), ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r', 'HorizontalAlignment', 'right');

% Mark 100 uV spec line
yline(100, 'r--', 'LineWidth', 1.2);
text(20, 103, 'Spec: 100 \muVrms', 'FontSize', 9, 'Color', 'r');

% Mark MATLAB kT/C prediction
yline(92.3, 'g--', 'LineWidth', 1.2);
text(20, 89, 'MATLAB kT/C: 92.3 \muVrms', 'FontSize', 9, 'Color', [0 0.6 0]);

xlabel('Frequency [Hz]', 'FontSize', 11);
ylabel('Cumulative RMS Noise [\muVrms]', 'FontSize', 11);
title('Running Output Noise Integral (from SPICE)', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 10);
xlim([10 10e9]);
ylim([0 max(noise_rms_cumul*1e6)*1.15]);

saveas(gcf, 'plot_running_noise_integral.png');
fprintf('Plot saved to plot_running_noise_integral.png\n');
