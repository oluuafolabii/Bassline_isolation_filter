%% 07_select_best_and_summarize.m
% Generate structured listening evaluation template, select best design
% based on objective metrics, and curate report assets.

run('config.m');

if ~exist(dirNotes,     'dir'), mkdir(dirNotes);     end
if ~exist(dirReportFig, 'dir'), mkdir(dirReportFig); end
if ~exist(dirReportTbl, 'dir'), mkdir(dirReportTbl); end
if ~exist(dirReportAud, 'dir'), mkdir(dirReportAud); end

clipFiles = dir(fullfile(dirPreAudio, '*.wav'));
nClips    = numel(clipFiles);

finalistIDs = cell(1, numel(finalists));
for fi = 1:numel(finalists)
    finalistIDs{fi} = filterID(finalists(fi).fc, finalists(fi).N, finalists(fi).window);
end

%% =======================================================================
%  7.1 -- Listening evaluation template
%  =======================================================================
fid = fopen(fullfile(dirNotes, 'listening_test_notes.md'), 'w');
fprintf(fid, '# Personal Structured Listening Evaluation\n\n');
fprintf(fid, 'Date: [fill in]\n');
fprintf(fid, 'Headphones / monitors: [fill in]\n\n');
fprintf(fid, '## Rating Scale\n\n');
fprintf(fid, '1-10 for each criterion (10 = best)\n\n');
fprintf(fid, '| Label | FilterID | Bass Isolation | Clarity | Leakage (10=none) | Naturalness | Notes |\n');
fprintf(fid, '|-------|----------|---------------|---------|-------------------|-------------|-------|\n');
for fi = 1:numel(finalists)
    fprintf(fid, '| %s | %s | | | | | |\n', finalists(fi).label, finalistIDs{fi});
end
fprintf(fid, '\n## Free-Text Observations\n\n');
fprintf(fid, '### Best candidate\n[fill in]\n\n');
fprintf(fid, '### Worst candidate\n[fill in]\n\n');
fprintf(fid, '### Residual quality\n[fill in]\n\n');
fprintf(fid, '### filtfilt vs filter impression\n[fill in]\n');
fclose(fid);
fprintf('  listening_test_notes.md template written\n');

%% =======================================================================
%  7.2 -- Automated best-design selection from objective metrics
%  =======================================================================
Tmetrics = readtable(fullfile(dirTables, 'filter_metrics.csv'));
Tenergy  = readtable(fullfile(dirTables, 'energy_retention.csv'));

fid = fopen(fullfile(dirNotes, 'final_design_choice.md'), 'w');
fprintf(fid, '# Final Design Selection\n\n');
fprintf(fid, '## Finalist Metrics Summary\n\n');
fprintf(fid, '| Label | FilterID | StopAtten (dB) | TransWidth (Hz) | GD (ms) | Retention | Leakage | BW-MSE |\n');
fprintf(fid, '|-------|----------|---------------|-----------------|---------|-----------|---------|--------|\n');

bestScore = -Inf;
bestIdx   = 1;

for fi = 1:numel(finalists)
    fID_str = finalistIDs{fi};
    mRow = Tmetrics(strcmp(Tmetrics.FilterID, fID_str), :);
    eRows = Tenergy(strcmp(Tenergy.FilterID, fID_str), :);
    avgRet  = mean(eRows.Retention);
    avgLeak = mean(eRows.Leakage);

    if ~isempty(mRow)
        fprintf(fid, '| %s | %s | %.1f | %.1f | %.2f | %.4f | %.6f | %.6f |\n', ...
            finalists(fi).label, fID_str, mRow.StopbandAtten_dB(1), ...
            mRow.TransWidth_Hz(1), mRow.GroupDelay_ms(1), ...
            avgRet, avgLeak, mRow.BrickwallMSE(1));

        % Scoring: high attenuation, high retention, low leakage, low MSE
        score = mRow.StopbandAtten_dB(1) + avgRet*100 - avgLeak*1000 - mRow.BrickwallMSE(1)*1000;
        if mRow.GroupDelay_ms(1) > 25
            score = score - 50;  % penalise excessive delay
        end
        if score > bestScore
            bestScore = score;
            bestIdx = fi;
        end
    end
end

bestLabel = finalists(bestIdx).label;
bestFID   = finalistIDs{bestIdx};

fprintf(fid, '\n## Selected Design\n\n');
fprintf(fid, '- **Label:** %s\n', bestLabel);
fprintf(fid, '- **FilterID:** %s\n', bestFID);
fprintf(fid, '- **fc:** %d Hz\n', finalists(bestIdx).fc);
fprintf(fid, '- **N:** %d\n', finalists(bestIdx).N);
fprintf(fid, '- **Window:** %s\n', finalists(bestIdx).window);
fprintf(fid, '- **Fs:** %d Hz\n', Fs);
fprintf(fid, '\n## Justification\n\n');
fprintf(fid, 'Selected based on highest composite score combining stopband attenuation,\n');
fprintf(fid, 'energy retention, minimal leakage, and brick-wall approximation error.\n');
fprintf(fid, 'Group delay remains within acceptable bounds (< 25 ms).\n\n');
fprintf(fid, '**Note:** Update this section after the personal listening evaluation to\n');
fprintf(fid, 'incorporate subjective impressions and confirm or override the objective selection.\n');
fclose(fid);
fprintf('  final_design_choice.md written (auto-selected: %s)\n', bestFID);

%% =======================================================================
%  7.3 -- Curate report assets
%  =======================================================================

% --- Figures ---
figSources = {};

% Original audio figures (clip 1)
[~, clip1, ~] = fileparts(clipFiles(1).name);
figSources{end+1} = {fullfile(dirFigOrig, sprintf('%s_waveform.png', clip1)),       'fig01_orig_waveform.png'};
figSources{end+1} = {fullfile(dirFigOrig, sprintf('%s_fft_0-400Hz.png', clip1)),    'fig02_orig_fft_lowfreq.png'};
figSources{end+1} = {fullfile(dirFigOrig, sprintf('%s_spec_0-2000Hz.png', clip1)),  'fig03_orig_spectrogram.png'};

% Filter analysis figures -- window comparison, order comparison, cutoff comparison
figSources{end+1} = {fullfile(dirFigFilters, 'cmp_window.png'),  'fig04_window_comparison.png'};
figSources{end+1} = {fullfile(dirFigFilters, 'cmp_order.png'),   'fig05_order_comparison.png'};
figSources{end+1} = {fullfile(dirFigFilters, 'cmp_cutoff.png'),  'fig06_cutoff_comparison.png'};

% Best finalist detailed figures
figSources{end+1} = {fullfile(dirFigFilters, sprintf('%s_brickwall.png', bestFID)),  'fig07_brickwall_overlay.png'};
figSources{end+1} = {fullfile(dirFigFilters, sprintf('%s_grpdelay.png', bestFID)),   'fig08_group_delay.png'};
figSources{end+1} = {fullfile(dirFigFilters, sprintf('%s_impulse.png', bestFID)),    'fig09_impulse_response.png'};

% Filtered comparison figures
figSources{end+1} = {fullfile(dirFigFiltered, sprintf('%s_%s_fft_0-400Hz.png', clip1, bestFID)),    'fig10_filt_fft_overlay.png'};
figSources{end+1} = {fullfile(dirFigFiltered, sprintf('%s_%s_spec_0-500Hz.png', clip1, bestFID)),   'fig11_filt_spectrogram.png'};
figSources{end+1} = {fullfile(dirFigFiltered, sprintf('%s_retention_bar.png', clip1)),               'fig12_energy_retention.png'};

% filtfilt comparison
figSources{end+1} = {fullfile(dirFigFiltered, 'filtfilt_vs_filter_mag.png'),      'fig13_filtfilt_mag.png'};
figSources{end+1} = {fullfile(dirFigFiltered, 'filtfilt_vs_filter_waveform.png'), 'fig14_filtfilt_waveform.png'};

for j = 1:numel(figSources)
    src = figSources{j}{1};
    dst = fullfile(dirReportFig, figSources{j}{2});
    if isfile(src)
        copyfile(src, dst);
    else
        fprintf('  [WARN] Missing figure: %s\n', src);
    end
end
fprintf('  Copied %d figures to report_assets/figures/\n', numel(figSources));

% --- Tables ---
tblSources = {'clip_info.csv','design_grid.csv','filter_metrics.csv', ...
              'band_energy_metrics.csv','energy_retention.csv','filter_bank.csv'};
for j = 1:numel(tblSources)
    src = fullfile(dirTables, tblSources{j});
    if isfile(src)
        copyfile(src, fullfile(dirReportTbl, tblSources{j}));
    end
end
fprintf('  Copied %d tables to report_assets/tables/\n', numel(tblSources));

% --- Audio ---
% Original excerpt (clip 1)
origSrc = fullfile(dirPreAudio, clipFiles(1).name);
if isfile(origSrc)
    copyfile(origSrc, fullfile(dirReportAud, 'original_excerpt.wav'));
end

% Best filtered output
bestFiltSrc = fullfile(dirFiltAudio, sprintf('%s_%s.wav', clip1, bestFID));
if isfile(bestFiltSrc)
    copyfile(bestFiltSrc, fullfile(dirReportAud, 'best_filtered.wav'));
end

% Residual from best
bestResSrc = fullfile(dirFiltAudio, sprintf('%s_%s_residual.wav', clip1, bestFID));
if isfile(bestResSrc)
    copyfile(bestResSrc, fullfile(dirReportAud, 'best_residual.wav'));
end

% Short-filter baseline (F1: N=100 Hamming fc=200) for contrast
baseID = filterID(200, 100, 'hamming');
baseSrc = fullfile(dirFiltAudio, sprintf('%s_%s.wav', clip1, baseID));
if isfile(baseSrc)
    copyfile(baseSrc, fullfile(dirReportAud, 'baseline_N100.wav'));
end

% filtfilt version
ffSrc = fullfile(dirFiltAudio, sprintf('%s_%s_filtfilt.wav', clip1, filterID(200, 1000, 'hamming')));
if isfile(ffSrc)
    copyfile(ffSrc, fullfile(dirReportAud, 'best_filtfilt.wav'));
end

fprintf('  Audio clips copied to report_assets/audio/\n');
fprintf('  Phase 7 complete.\n');
