%% 05_apply_filters.m
% Filter all preprocessed clips with all 72 filters. Compute PSD-based
% band-energy metrics. Export WAV + residual for the 8 finalists.
% Run filtfilt on the best candidate for zero-phase comparison.

run('config.m');

if ~exist(dirFiltAudio, 'dir'), mkdir(dirFiltAudio); end
if ~exist(dirTables,    'dir'), mkdir(dirTables);    end

clipFiles = dir(fullfile(dirPreAudio, '*.wav'));
matFiles  = dir(fullfile(dirFilters,  'filt_*.mat'));
nClips    = numel(clipFiles);
nFilters  = numel(matFiles);

psdWin = hamming(psdWinLen, 'periodic');

% Finalist IDs for audio export
finalistIDs = cell(1, numel(finalists));
for fi = 1:numel(finalists)
    finalistIDs{fi} = filterID(finalists(fi).fc, finalists(fi).N, finalists(fi).window);
end
finalistSet = containers.Map(finalistIDs, num2cell(1:numel(finalists)));

%% Preallocate energy metrics storage
energyRows = {};

%% Define energy bands (Hz)
bandEdges = [0 150; 0 200; 0 250; 250 1000; 1000 Fs/2];
bandLabels = {'0-150','0-200','0-250','250-1000','1000+'};
nBands = size(bandEdges, 1);

for ci = 1:nClips
    [x, ~] = audioread(fullfile(clipFiles(ci).folder, clipFiles(ci).name));
    [~, clipName, ~] = fileparts(clipFiles(ci).name);

    % Original PSD for reference energy
    [pxx_orig, fPsd] = pwelch(x, psdWin, psdOverlap, psdNfft, Fs);
    E_in = zeros(1, nBands);
    for bi = 1:nBands
        bIdx = fPsd >= bandEdges(bi,1) & fPsd < bandEdges(bi,2);
        E_in(bi) = trapz(fPsd(bIdx), pxx_orig(bIdx));
    end

    for mi = 1:nFilters
        D  = load(fullfile(matFiles(mi).folder, matFiles(mi).name));
        b  = D.b_manual;
        fc = D.fc;
        N  = D.N;
        fID_str = D.fID;

        %% Causal filtering + delay alignment
        y = filter(b, 1, x);
        d = round(N/2);
        y_aligned = [y(d+1:end); zeros(d, 1)];

        %% PSD of filtered signal
        [pxx_filt, ~] = pwelch(y_aligned, psdWin, psdOverlap, psdNfft, Fs);
        E_out = zeros(1, nBands);
        for bi = 1:nBands
            bIdx = fPsd >= bandEdges(bi,1) & fPsd < bandEdges(bi,2);
            E_out(bi) = trapz(fPsd(bIdx), pxx_filt(bIdx));
        end

        % Retention = energy kept below fc / energy that was below fc
        switch fc
            case 150, fcBandIdx = 1;
            case 200, fcBandIdx = 2;
            case 250, fcBandIdx = 3;
        end
        retention = E_out(fcBandIdx) / (E_in(fcBandIdx) + eps);

        % Leakage = energy above fc in output / energy above fc in input
        aboveFcIdx = fPsd >= fc;
        E_in_above  = trapz(fPsd(aboveFcIdx), pxx_orig(aboveFcIdx));
        E_out_above = trapz(fPsd(aboveFcIdx), pxx_filt(aboveFcIdx));
        leakage = E_out_above / (E_in_above + eps);

        energyRows{end+1} = {clipName, fID_str, fc, N, char(D.wName), ...
            E_out(1), E_out(2), E_out(3), E_out(4), E_out(5), ...
            retention, leakage}; %#ok<SAGROW>

        %% Export WAV + residual for finalists
        if finalistSet.isKey(fID_str)
            outBase = sprintf('%s_%s', clipName, fID_str);
            audiowrite(fullfile(dirFiltAudio, [outBase '.wav']), ...
                       y_aligned / (max(abs(y_aligned)) + eps), Fs);

            residual = x - y_aligned;
            audiowrite(fullfile(dirFiltAudio, [outBase '_residual.wav']), ...
                       residual / (max(abs(residual)) + eps), Fs);
        end
    end
    fprintf('  Clip %d/%d (%s): all %d filters applied\n', ci, nClips, clipName, nFilters);
end

%% Write band_energy_metrics.csv
colNames = {'Clip','FilterID','fc','N','Window', ...
            'E_0_150','E_0_200','E_0_250','E_250_1000','E_1000plus', ...
            'Retention','Leakage'};
eMat = vertcat(energyRows{:});
Tenergy = cell2table(eMat, 'VariableNames', colNames);
writetable(Tenergy, fullfile(dirTables, 'band_energy_metrics.csv'));

%% Extract energy_retention.csv (summary view)
Tret = Tenergy(:, {'Clip','FilterID','fc','N','Window','Retention','Leakage'});
writetable(Tret, fullfile(dirTables, 'energy_retention.csv'));
fprintf('  Energy metrics saved (%d rows)\n', height(Tenergy));

%% =======================================================================
%  filtfilt comparison for best candidate (F5: N=1000, Hamming, fc=200)
%  =======================================================================
bestID = filterID(200, 1000, 'hamming');
Dbest  = load(fullfile(dirFilters, sprintf('filt_%s.mat', bestID)));
b_best = Dbest.b_manual;

for ci = 1:nClips
    [x, ~] = audioread(fullfile(clipFiles(ci).folder, clipFiles(ci).name));
    [~, clipName, ~] = fileparts(clipFiles(ci).name);

    y_zp = filtfilt(b_best, 1, x);
    outName = sprintf('%s_%s_filtfilt.wav', clipName, bestID);
    audiowrite(fullfile(dirFiltAudio, outName), y_zp / (max(abs(y_zp)) + eps), Fs);
    fprintf('  filtfilt exported: %s\n', outName);
end

fprintf('  Phase 5 complete.\n');
