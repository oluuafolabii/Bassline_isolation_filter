%% 06_compare_results.m
% Generate before/after comparison figures for each finalist filter applied
% to each clip: waveform overlay, FFT overlay, PSD overlay, spectrogram
% comparison, band-energy bar charts, and filtfilt vs filter comparison.

run('config.m');

if ~exist(dirFigFiltered, 'dir'), mkdir(dirFigFiltered); end

clipFiles = dir(fullfile(dirPreAudio, '*.wav'));
nClips    = numel(clipFiles);

psdWin  = hamming(psdWinLen, 'periodic');
stftWin = hann(stftWinLen, 'periodic');
cmap    = lines(numel(finalists));

% Finalist IDs
finalistIDs = cell(1, numel(finalists));
for fi = 1:numel(finalists)
    finalistIDs{fi} = filterID(finalists(fi).fc, finalists(fi).N, finalists(fi).window);
end

for ci = 1:nClips
    [x_orig, ~] = audioread(fullfile(clipFiles(ci).folder, clipFiles(ci).name));
    [~, clipName, ~] = fileparts(clipFiles(ci).name);
    t = (0:length(x_orig)-1) / Fs;

    for fi = 1:numel(finalists)
        fID_str = finalistIDs{fi};
        lbl = finalists(fi).label;
        fc  = finalists(fi).fc;

        filtPath = fullfile(dirFiltAudio, sprintf('%s_%s.wav', clipName, fID_str));
        if ~isfile(filtPath), continue; end
        [y, ~] = audioread(filtPath);

        % Ensure same length
        minLen = min(length(x_orig), length(y));
        xo = x_orig(1:minLen);
        yf = y(1:minLen);
        tt = t(1:minLen);

        %% 1 -- Waveform overlay (full + 0.5s zoom)
        fig = figure('Position', [50 50 1100 500]);
        subplot(2,1,1);
        plot(tt, xo, 'Color', [0.6 0.6 0.6], 'DisplayName', 'Original'); hold on;
        plot(tt, yf, 'Color', cmap(fi,:), 'DisplayName', lbl); hold off;
        xlabel('Time (s)'); ylabel('Amplitude');
        title(sprintf('Waveform: %s vs %s', clipName, lbl), 'Interpreter', 'none');
        legend('Location', 'northeast'); set(gca, 'FontSize', figFontSize);

        subplot(2,1,2);
        zoomEnd = min(0.5, tt(end));
        zIdx = tt <= zoomEnd;
        plot(tt(zIdx), xo(zIdx), 'Color', [0.6 0.6 0.6], 'DisplayName', 'Original'); hold on;
        plot(tt(zIdx), yf(zIdx), 'Color', cmap(fi,:), 'DisplayName', lbl); hold off;
        xlabel('Time (s)'); ylabel('Amplitude');
        title(sprintf('Waveform Zoom (0 - %.1f s)', zoomEnd));
        legend('Location', 'northeast'); set(gca, 'FontSize', figFontSize);

        print(fig, fullfile(dirFigFiltered, sprintf('%s_%s_waveform.png', clipName, fID_str)), ...
              '-dpng', sprintf('-r%d', figDPI));
        close(fig);

        %% 2 -- FFT overlay
        Nfft = length(xo);
        Xo = fft(xo); Yf = fft(yf);
        XodB = 20*log10(abs(Xo(1:floor(Nfft/2)+1)) + eps);
        YfdB = 20*log10(abs(Yf(1:floor(Nfft/2)+1)) + eps);
        refPeak = max(XodB);
        XodB = XodB - refPeak;
        YfdB = YfdB - refPeak;
        fAxis = (0:floor(Nfft/2)) * Fs / Nfft;

        fftViews = struct('label',{'0-1000Hz','0-400Hz'}, 'xlim',{[0 1000],[0 400]});
        for v = 1:numel(fftViews)
            fig = figure('Position', [100 100 900 400]);
            plot(fAxis, XodB, 'Color', [0.6 0.6 0.6], 'DisplayName', 'Original'); hold on;
            plot(fAxis, YfdB, 'Color', cmap(fi,:), 'DisplayName', lbl); hold off;
            xlim(fftViews(v).xlim);
            xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
            title(sprintf('FFT %s: %s vs %s', fftViews(v).label, clipName, lbl), 'Interpreter', 'none');
            xline(fc, '--r', sprintf('fc=%d', fc), 'FontSize', 9);
            legend('Location', 'southwest'); set(gca, 'FontSize', figFontSize);
            print(fig, fullfile(dirFigFiltered, sprintf('%s_%s_fft_%s.png', clipName, fID_str, fftViews(v).label)), ...
                  '-dpng', sprintf('-r%d', figDPI));
            close(fig);
        end

        %% 3 -- PSD overlay
        [pOrig, fP] = pwelch(xo, psdWin, psdOverlap, psdNfft, Fs);
        [pFilt, ~]   = pwelch(yf, psdWin, psdOverlap, psdNfft, Fs);
        pOdB = 10*log10(pOrig + eps);
        pFdB = 10*log10(pFilt + eps);

        psdViews = struct('label',{'full','0-500Hz'}, 'xlim',{[0 Fs/2],[0 500]});
        for v = 1:numel(psdViews)
            fig = figure('Position', [100 100 900 400]);
            plot(fP, pOdB, 'Color', [0.6 0.6 0.6], 'DisplayName', 'Original'); hold on;
            plot(fP, pFdB, 'Color', cmap(fi,:), 'DisplayName', lbl); hold off;
            xlim(psdViews(v).xlim);
            xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
            title(sprintf('PSD %s: %s vs %s', psdViews(v).label, clipName, lbl), 'Interpreter', 'none');
            xline(fc, '--r', sprintf('fc=%d', fc), 'FontSize', 9);
            legend('Location', 'southwest'); set(gca, 'FontSize', figFontSize);
            print(fig, fullfile(dirFigFiltered, sprintf('%s_%s_psd_%s.png', clipName, fID_str, psdViews(v).label)), ...
                  '-dpng', sprintf('-r%d', figDPI));
            close(fig);
        end

        %% 4 -- Spectrogram comparison (stacked)
        specViews = struct('label',{'full','0-500Hz'}, 'ylim',{[0 Fs/2],[0 500]});
        [So, fSo, tSo] = spectrogram(xo, stftWin, stftOverlap, stftNfft, Fs);
        [Sf, ~,   ~]   = spectrogram(yf, stftWin, stftOverlap, stftNfft, Fs);
        SodB = 10*log10(abs(So).^2 + eps);
        SfdB = 10*log10(abs(Sf).^2 + eps);
        clims = [min(SodB(:)) max(SodB(:))];

        for v = 1:numel(specViews)
            fig = figure('Position', [50 50 1100 700]);
            subplot(2,1,1);
            imagesc(tSo, fSo, SodB); axis xy; ylim(specViews(v).ylim); caxis(clims);
            xlabel('Time (s)'); ylabel('Frequency (Hz)');
            title(sprintf('Original %s: %s', specViews(v).label, clipName), 'Interpreter', 'none');
            colorbar; colormap('jet'); set(gca, 'FontSize', figFontSize);

            subplot(2,1,2);
            imagesc(tSo, fSo, SfdB); axis xy; ylim(specViews(v).ylim); caxis(clims);
            xlabel('Time (s)'); ylabel('Frequency (Hz)');
            title(sprintf('Filtered %s: %s (%s)', specViews(v).label, lbl, fID_str), 'Interpreter', 'none');
            colorbar; colormap('jet'); set(gca, 'FontSize', figFontSize);

            print(fig, fullfile(dirFigFiltered, sprintf('%s_%s_spec_%s.png', clipName, fID_str, specViews(v).label)), ...
                  '-dpng', sprintf('-r%d', figDPI));
            close(fig);
        end
    end
    fprintf('  Comparison figures done for %s\n', clipName);
end

%% =======================================================================
%  Band-energy bar charts (all finalists per clip)
%  =======================================================================
Tenergy = readtable(fullfile(dirTables, 'band_energy_metrics.csv'));

for ci = 1:nClips
    [~, clipName, ~] = fileparts(clipFiles(ci).name);

    %% Retention bar chart
    fig = figure('Position', [100 100 900 450]);
    retVals = zeros(1, numel(finalists));
    lbls    = cell(1, numel(finalists));
    for fi = 1:numel(finalists)
        fID_str = finalistIDs{fi};
        row = Tenergy(strcmp(Tenergy.Clip, clipName) & strcmp(Tenergy.FilterID, fID_str), :);
        if ~isempty(row)
            retVals(fi) = row.Retention(1);
        end
        lbls{fi} = finalists(fi).label;
    end
    bar(retVals, 'FaceColor', [0.2 0.5 0.8]);
    set(gca, 'XTickLabel', lbls, 'FontSize', figFontSize);
    ylabel('Energy Retention (ratio)'); ylim([0 1.1]);
    title(sprintf('Energy Retention Below fc: %s', clipName), 'Interpreter', 'none');
    print(fig, fullfile(dirFigFiltered, sprintf('%s_retention_bar.png', clipName)), ...
          '-dpng', sprintf('-r%d', figDPI));
    close(fig);

    %% Leakage bar chart
    fig = figure('Position', [100 100 900 450]);
    leakVals = zeros(1, numel(finalists));
    for fi = 1:numel(finalists)
        fID_str = finalistIDs{fi};
        row = Tenergy(strcmp(Tenergy.Clip, clipName) & strcmp(Tenergy.FilterID, fID_str), :);
        if ~isempty(row)
            leakVals(fi) = row.Leakage(1);
        end
    end
    bar(leakVals, 'FaceColor', [0.8 0.3 0.2]);
    set(gca, 'XTickLabel', lbls, 'FontSize', figFontSize);
    ylabel('Leakage Ratio'); ylim([0 max(leakVals)*1.3 + eps]);
    title(sprintf('Leakage Above fc: %s', clipName), 'Interpreter', 'none');
    print(fig, fullfile(dirFigFiltered, sprintf('%s_leakage_bar.png', clipName)), ...
          '-dpng', sprintf('-r%d', figDPI));
    close(fig);
end

%% =======================================================================
%  filtfilt vs filter comparison
%  =======================================================================
bestID = filterID(200, 1000, 'hamming');
Dbest  = load(fullfile(dirFilters, sprintf('filt_%s.mat', bestID)));
b_best = Dbest.b_manual;
N_best = Dbest.N;

[Hcausal, fH] = freqz(b_best, 1, nFreqz, Fs);
% filtfilt effective response = |H|^2
HzpMag = abs(Hcausal).^2;

fig = figure('Position', [100 100 900 450]);
plot(fH, 20*log10(abs(Hcausal)+eps), 'b', 'LineWidth', 1.3, 'DisplayName', 'filter (causal)'); hold on;
plot(fH, 20*log10(HzpMag+eps),       'r', 'LineWidth', 1.3, 'DisplayName', 'filtfilt (zero-phase)'); hold off;
xlim([0 1000]); ylim([-120 5]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('filter vs filtfilt: %s', bestID), 'Interpreter', 'none');
legend('Location', 'southwest'); set(gca, 'FontSize', figFontSize);
print(fig, fullfile(dirFigFiltered, 'filtfilt_vs_filter_mag.png'), '-dpng', sprintf('-r%d', figDPI));
close(fig);

% Waveform comparison for first clip
[x1, ~] = audioread(fullfile(clipFiles(1).folder, clipFiles(1).name));
[~, clip1Name, ~] = fileparts(clipFiles(1).name);

y_causal  = filter(b_best, 1, x1);
d = round(N_best/2);
y_causal_aligned = [y_causal(d+1:end); zeros(d,1)];
y_zp = filtfilt(b_best, 1, x1);

tPlot = (0:length(x1)-1) / Fs;
zoomSamp = round(0.5 * Fs);

fig = figure('Position', [50 50 1100 500]);
subplot(2,1,1);
plot(tPlot, x1, 'Color', [0.7 0.7 0.7], 'DisplayName', 'Original'); hold on;
plot(tPlot, y_causal_aligned, 'b', 'DisplayName', 'filter (aligned)');
plot(tPlot, y_zp, 'r', 'DisplayName', 'filtfilt'); hold off;
xlabel('Time (s)'); ylabel('Amplitude');
title('filter vs filtfilt: Full waveform');
legend('Location', 'northeast'); set(gca, 'FontSize', figFontSize);

subplot(2,1,2);
idx = 1:zoomSamp;
plot(tPlot(idx), x1(idx), 'Color', [0.7 0.7 0.7], 'DisplayName', 'Original'); hold on;
plot(tPlot(idx), y_causal_aligned(idx), 'b', 'DisplayName', 'filter (aligned)');
plot(tPlot(idx), y_zp(idx), 'r', 'DisplayName', 'filtfilt'); hold off;
xlabel('Time (s)'); ylabel('Amplitude');
title('filter vs filtfilt: 0 - 0.5 s zoom');
legend('Location', 'northeast'); set(gca, 'FontSize', figFontSize);

print(fig, fullfile(dirFigFiltered, 'filtfilt_vs_filter_waveform.png'), '-dpng', sprintf('-r%d', figDPI));
close(fig);

fprintf('  All comparison figures saved to %s\n', dirFigFiltered);
