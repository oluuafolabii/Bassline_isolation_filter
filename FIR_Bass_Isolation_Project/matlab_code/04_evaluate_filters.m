%% 04_evaluate_filters.m
% Compute objective metrics for all 72 filters (passband ripple, stopband
% attenuation, transition width, group delay, brick-wall MSE). Select 8
% finalists and generate detailed figures for those only.

run('config.m');

if ~exist(dirFigFilters, 'dir'), mkdir(dirFigFilters); end
if ~exist(dirTables,     'dir'), mkdir(dirTables);     end

matFiles = dir(fullfile(dirFilters, 'filt_*.mat'));
assert(numel(matFiles) == 72, 'Expected 72 filter files, found %d', numel(matFiles));

%% Preallocate results table columns
nF = numel(matFiles);
resID          = cell(nF, 1);
resFc          = zeros(nF, 1);
resN           = zeros(nF, 1);
resWin         = cell(nF, 1);
resRipple      = zeros(nF, 1);
resAtten       = zeros(nF, 1);
resTransW      = zeros(nF, 1);
resGD_samp     = zeros(nF, 1);
resGD_ms       = zeros(nF, 1);
resBWmse       = zeros(nF, 1);

for k = 1:nF
    D = load(fullfile(matFiles(k).folder, matFiles(k).name));
    b  = D.b_manual;
    fc = D.fc;
    N  = D.N;

    %% Frequency response
    [H, fH] = freqz(b, 1, nFreqz, Fs);
    magdB = 20*log10(abs(H) + eps);

    %% Passband ripple: 0 to passFrac*fc
    passIdx = fH <= passFrac * fc;
    if any(passIdx)
        resRipple(k) = max(magdB(passIdx)) - min(magdB(passIdx));
    end

    %% Stopband attenuation: stopFrac*fc to Nyquist
    stopIdx = fH >= stopFrac * fc;
    if any(stopIdx)
        resAtten(k) = -max(magdB(stopIdx));
    end

    %% Transition width: first freq where magdB <= -1 to first where <= -40
    idx_m1  = find(magdB <= -1,  1, 'first');
    idx_m40 = find(magdB <= -40, 1, 'first');
    if ~isempty(idx_m1) && ~isempty(idx_m40)
        resTransW(k) = fH(idx_m40) - fH(idx_m1);
    else
        resTransW(k) = NaN;
    end

    %% Group delay (mean in passband)
    gd = grpdelay(b, 1, nFreqz, Fs);
    gdPass = gd(passIdx);
    resGD_samp(k) = mean(gdPass);
    resGD_ms(k)   = resGD_samp(k) / Fs * 1000;

    %% Brick-wall MSE
    idealH = double(fH <= fc);
    resBWmse(k) = mean((abs(H) - idealH).^2);

    resID{k}  = D.fID;
    resFc(k)  = fc;
    resN(k)   = N;
    resWin{k} = char(D.wName);
end

%% Save filter_metrics.csv
Tmetrics = table(resID, resFc, resN, resWin, resRipple, resAtten, ...
    resTransW, resGD_samp, resGD_ms, resBWmse, ...
    'VariableNames', {'FilterID','fc','N','Window', ...
    'PassbandRipple_dB','StopbandAtten_dB','TransWidth_Hz', ...
    'GroupDelay_samples','GroupDelay_ms','BrickwallMSE'});
writetable(Tmetrics, fullfile(dirTables, 'filter_metrics.csv'));
fprintf('  filter_metrics.csv written (%d rows)\n', height(Tmetrics));

%% =======================================================================
%  Finalist deep figures
%  =======================================================================

% Build finalist FilterIDs from config
finalistIDs = cell(1, numel(finalists));
for fi = 1:numel(finalists)
    finalistIDs{fi} = filterID(finalists(fi).fc, finalists(fi).N, finalists(fi).window);
end

% Colour map for consistent colouring across comparison plots
cmap = lines(8);

for fi = 1:numel(finalists)
    fID_str = finalistIDs{fi};
    D = load(fullfile(dirFilters, sprintf('filt_%s.mat', fID_str)));
    b  = D.b_manual;
    fc = D.fc;
    N  = D.N;
    L  = N + 1;
    lbl = finalists(fi).label;

    [H, fH] = freqz(b, 1, nFreqz, Fs);
    magdB = 20*log10(abs(H) + eps);
    phase = unwrap(angle(H));
    gd    = grpdelay(b, 1, nFreqz, Fs);

    %% Impulse response (stem)
    fig = figure('Position', [100 100 900 350]);
    stem(0:N, b, 'filled', 'MarkerSize', 2, 'Color', cmap(fi,:));
    xlabel('Sample n'); ylabel('h[n]');
    title(sprintf('Impulse Response: %s (fc=%d, N=%d, %s)', lbl, fc, N, D.wName), 'Interpreter', 'none');
    set(gca, 'FontSize', figFontSize);
    print(fig, fullfile(dirFigFilters, sprintf('%s_impulse.png', fID_str)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);

    %% Magnitude response (dB) -- three zoom levels
    magViews = struct('label',{'full','0-1000Hz','0-500Hz'}, ...
                      'xlim',{[0 Fs/2],[0 1000],[0 500]});
    for v = 1:numel(magViews)
        fig = figure('Position', [100 100 900 400]);
        plot(fH, magdB, 'Color', cmap(fi,:), 'LineWidth', 1.2);
        xlim(magViews(v).xlim); ylim([-120 5]);
        xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
        title(sprintf('|H(f)| %s: %s (fc=%d, N=%d, %s)', ...
              magViews(v).label, lbl, fc, N, D.wName), 'Interpreter', 'none');
        xline(fc, '--r', sprintf('fc=%d', fc), 'FontSize', 9);
        set(gca, 'FontSize', figFontSize);
        print(fig, fullfile(dirFigFilters, sprintf('%s_mag_%s.png', fID_str, magViews(v).label)), ...
              '-dpng', sprintf('-r%d', figDPI));
        close(fig);
    end

    %% Phase response (unwrapped)
    fig = figure('Position', [100 100 900 400]);
    plot(fH, phase, 'Color', cmap(fi,:), 'LineWidth', 1.2);
    xlabel('Frequency (Hz)'); ylabel('Phase (rad)');
    title(sprintf('Phase Response: %s (fc=%d, N=%d, %s)', lbl, fc, N, D.wName), 'Interpreter', 'none');
    set(gca, 'FontSize', figFontSize);
    print(fig, fullfile(dirFigFilters, sprintf('%s_phase.png', fID_str)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);

    %% Group delay
    fig = figure('Position', [100 100 900 400]);
    plot(fH, gd, 'Color', cmap(fi,:), 'LineWidth', 1.2);
    xlim([0 1000]);
    xlabel('Frequency (Hz)'); ylabel('Group Delay (samples)');
    title(sprintf('Group Delay: %s (fc=%d, N=%d, %s)', lbl, fc, N, D.wName), 'Interpreter', 'none');
    yline(N/2, '--k', sprintf('N/2 = %d', N/2), 'FontSize', 9);
    set(gca, 'FontSize', figFontSize);
    print(fig, fullfile(dirFigFilters, sprintf('%s_grpdelay.png', fID_str)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);

    %% Brick-wall overlay
    fig = figure('Position', [100 100 900 400]);
    hold on;
    idealH = double(fH <= fc);
    plot(fH, idealH, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Ideal brick-wall');
    plot(fH, abs(H), 'Color', cmap(fi,:), 'LineWidth', 1.2, 'DisplayName', lbl);
    xlim([0 2000]); ylim([-0.1 1.3]);
    xlabel('Frequency (Hz)'); ylabel('|H(f)|');
    title(sprintf('Brick-Wall Comparison: %s', lbl), 'Interpreter', 'none');
    legend('Location', 'northeast');
    set(gca, 'FontSize', figFontSize);
    hold off;
    print(fig, fullfile(dirFigFilters, sprintf('%s_brickwall.png', fID_str)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);
end

%% =======================================================================
%  Comparison overlay plots
%  =======================================================================

%% Window comparison: F2 vs F3 vs F4 (N=200, fc=200, Hamming/Blackman/Rectwin)
compSets = {
    struct('title','Window Comparison (N=200, fc=200)', 'suffix','cmp_window', ...
           'ids',{{finalistIDs{2}, finalistIDs{3}, finalistIDs{4}}}, ...
           'labels',{{'F2 Hamming','F3 Blackman','F4 Rectangular'}});
    struct('title','Order Comparison (Hamming, fc=200)', 'suffix','cmp_order', ...
           'ids',{{finalistIDs{1}, finalistIDs{2}, finalistIDs{5}}}, ...
           'labels',{{'F1 N=100','F2 N=200','F5 N=1000'}});
    struct('title','Cutoff Comparison (Hamming, N=1000)', 'suffix','cmp_cutoff', ...
           'ids',{{finalistIDs{7}, finalistIDs{5}, finalistIDs{8}}}, ...
           'labels',{{'F7 fc=150','F5 fc=200','F8 fc=250'}});
};

for cs = 1:numel(compSets)
    S = compSets{cs};
    fig = figure('Position', [100 100 1000 450]);
    hold on;
    for j = 1:numel(S.ids)
        [Hc, fHc] = deal_freqz(fullfile(dirFilters, sprintf('filt_%s.mat', S.ids{j})), nFreqz, Fs);
        plot(fHc, 20*log10(abs(Hc)+eps), 'LineWidth', 1.3, 'DisplayName', S.labels{j});
    end
    xlim([0 1000]); ylim([-100 5]);
    xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
    title(S.title, 'Interpreter', 'none');
    legend('Location', 'southwest');
    set(gca, 'FontSize', figFontSize);
    hold off;
    print(fig, fullfile(dirFigFilters, sprintf('%s.png', S.suffix)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);
end

fprintf('  Finalist figures generated in %s\n', dirFigFilters);

%% =======================================================================
%  Local helper function
%  =======================================================================
function [H, fH] = deal_freqz(matPath, nPts, Fs_)
    D = load(matPath);
    [H, fH] = freqz(D.b_manual, 1, nPts, Fs_);
end
