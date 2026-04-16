%% 08_review_and_validate.m
% Rigorous validation and quality gate. Programmatically checks:
%   8.1  Output completeness (all expected files exist and are non-empty)
%   8.2  Metric sanity (theoretical bounds)
%   8.3  Manual sinc vs fir1 cross-verification
%   8.4  Group delay exactness
%   8.5  Transition width monotonicity
%   8.6  Energy metric bounds
%   8.7  Write review checklist and validation report

run('config.m');

if ~exist(dirNotes, 'dir'), mkdir(dirNotes); end

clipFiles = dir(fullfile(dirPreAudio, '*.wav'));
nClips    = numel(clipFiles);
nFinalists = numel(finalists);

reportLines = {};
checkItems  = {};
allPass     = true;

log = @(msg) fprintf('  %s\n', msg);
addReport = @(msg) assignin('caller', 'reportLines', [evalin('caller','reportLines'), {msg}]);

fprintf('=== Phase 8: Validation and Review ===\n\n');

%% -----------------------------------------------------------------------
%  8.1 -- Output completeness
%  -----------------------------------------------------------------------
fprintf('--- 8.1 Output completeness ---\n');

dirChecks = {
    dirPreAudio,    '*.wav', nClips,                   'Preprocessed clips';
    dirFilters,     '*.mat', 72,                       'Filter coefficient files';
    dirTables,      '*.csv', 5,                        'CSV tables (min 5)';
};

for dc = 1:size(dirChecks, 1)
    folder = dirChecks{dc, 1};
    pat    = dirChecks{dc, 2};
    minN   = dirChecks{dc, 3};
    desc   = dirChecks{dc, 4};

    found = numel(dir(fullfile(folder, pat)));
    if found >= minN
        msg = sprintf('[PASS] %s: %d files (expected >= %d)', desc, found, minN);
    else
        msg = sprintf('[FAIL] %s: %d files (expected >= %d)', desc, found, minN);
        allPass = false;
    end
    log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
end

% Check specific CSVs
requiredCSVs = {'clip_info.csv','design_grid.csv','filter_bank.csv', ...
                'filter_metrics.csv','band_energy_metrics.csv','energy_retention.csv'};
for j = 1:numel(requiredCSVs)
    fp = fullfile(dirTables, requiredCSVs{j});
    if isfile(fp)
        T = readtable(fp);
        msg = sprintf('[PASS] %s exists (%d rows)', requiredCSVs{j}, height(T));
    else
        msg = sprintf('[FAIL] %s missing', requiredCSVs{j});
        allPass = false;
    end
    log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
end

% filter_metrics.csv row count
Tmet = readtable(fullfile(dirTables, 'filter_metrics.csv'));
if height(Tmet) == 72
    msg = '[PASS] filter_metrics.csv has exactly 72 rows';
else
    msg = sprintf('[FAIL] filter_metrics.csv has %d rows (expected 72)', height(Tmet));
    allPass = false;
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

% Check for NaN in metrics
nanCols = {'PassbandRipple_dB','StopbandAtten_dB','GroupDelay_samples','BrickwallMSE'};
for j = 1:numel(nanCols)
    nNan = sum(ismissing(Tmet.(nanCols{j})));
    if nNan == 0
        msg = sprintf('[PASS] No NaN in %s', nanCols{j});
    else
        msg = sprintf('[WARN] %d NaN values in %s', nNan, nanCols{j});
    end
    log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
end

%% -----------------------------------------------------------------------
%  8.2 -- Metric sanity checks (theoretical bounds)
%  -----------------------------------------------------------------------
fprintf('\n--- 8.2 Metric sanity checks ---\n');

% Expected stopband attenuation ranges by window type
winAttenExpected = containers.Map( ...
    {'rectwin','hann','hamming','blackman'}, ...
    {[10 35], [30 60], [40 70], [60 100]});

for k = 1:height(Tmet)
    wn = Tmet.Window{k};
    atten = Tmet.StopbandAtten_dB(k);
    if winAttenExpected.isKey(wn)
        range = winAttenExpected(wn);
        if atten < range(1) || atten > range(2)
            msg = sprintf('[WARN] %s: stopband atten %.1f dB outside expected [%.0f, %.0f] for %s', ...
                          Tmet.FilterID{k}, atten, range(1), range(2), wn);
            log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
        end
    end
end

% Passband ripple should be 0-5 dB
badRipple = Tmet.PassbandRipple_dB < 0 | Tmet.PassbandRipple_dB > 5;
if any(badRipple)
    msg = sprintf('[WARN] %d filters have passband ripple outside [0, 5] dB', sum(badRipple));
else
    msg = '[PASS] All passband ripple values in [0, 5] dB range';
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

% Brick-wall MSE should be in [0, 1]
badMSE = Tmet.BrickwallMSE < 0 | Tmet.BrickwallMSE > 1;
if any(badMSE)
    msg = sprintf('[WARN] %d filters have brick-wall MSE outside [0, 1]', sum(badMSE));
else
    msg = '[PASS] All brick-wall MSE values in [0, 1]';
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

%% -----------------------------------------------------------------------
%  8.3 -- Manual sinc vs fir1 cross-verification
%  -----------------------------------------------------------------------
fprintf('\n--- 8.3 Manual sinc vs fir1 agreement ---\n');

matFiles = dir(fullfile(dirFilters, 'filt_*.mat'));
maxDiffs = zeros(numel(matFiles), 1);
for k = 1:numel(matFiles)
    D = load(fullfile(matFiles(k).folder, matFiles(k).name));
    maxDiffs(k) = max(abs(D.b_manual - D.b_fir1));
end

% fir1 uses -6 dB semantics vs brick-wall, so some divergence is expected
tightMatch = sum(maxDiffs < 1e-6);
looseMatch = sum(maxDiffs < 0.01);
msg = sprintf('[INFO] %d/72 filters match < 1e-6, %d/72 match < 0.01 (fir1 vs manual)', ...
              tightMatch, looseMatch);
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

if looseMatch == 72
    msg = '[PASS] All manual/fir1 pairs agree within 0.01 tolerance';
else
    msg = sprintf('[WARN] %d filters diverge > 0.01 between manual sinc and fir1', 72 - looseMatch);
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

%% -----------------------------------------------------------------------
%  8.4 -- Group delay exactness (should be N/2 samples)
%  -----------------------------------------------------------------------
fprintf('\n--- 8.4 Group delay exactness ---\n');

gdErrors = zeros(height(Tmet), 1);
for k = 1:height(Tmet)
    expectedGD = Tmet.N(k) / 2;
    gdErrors(k) = abs(Tmet.GroupDelay_samples(k) - expectedGD);
end

if all(gdErrors < 0.5)
    msg = '[PASS] All group delays within 0.5 samples of N/2';
else
    nBad = sum(gdErrors >= 0.5);
    msg = sprintf('[FAIL] %d filters have group delay deviating > 0.5 samples from N/2', nBad);
    allPass = false;
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

%% -----------------------------------------------------------------------
%  8.5 -- Transition width monotonicity (should decrease with increasing N)
%  -----------------------------------------------------------------------
fprintf('\n--- 8.5 Transition width monotonicity ---\n');

monoPass = true;
for fc = cutoffsHz
    for wIdx = 1:numel(winNames)
        wn = winNames(wIdx);
        mask = Tmet.fc == fc & strcmp(Tmet.Window, wn);
        subset = Tmet(mask, :);
        subset = sortrows(subset, 'N');
        tw = subset.TransWidth_Hz;
        % Remove NaN before checking
        tw = tw(~isnan(tw));
        if numel(tw) >= 2
            diffs = diff(tw);
            if any(diffs > 0)
                msg = sprintf('[WARN] TransWidth not monotonically decreasing for fc=%d, %s', fc, wn);
                log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
                monoPass = false;
            end
        end
    end
end
if monoPass
    msg = '[PASS] Transition width decreases monotonically with N for all fc/window combos';
    log(msg); reportLines{end+1} = msg; %#ok<SAGROW>
end

%% -----------------------------------------------------------------------
%  8.6 -- Energy metric bounds
%  -----------------------------------------------------------------------
fprintf('\n--- 8.6 Energy retention/leakage bounds ---\n');

Tret = readtable(fullfile(dirTables, 'energy_retention.csv'));

badRet = Tret.Retention < 0 | Tret.Retention > 1.1;
if any(badRet)
    msg = sprintf('[WARN] %d rows have retention outside [0, 1.1]', sum(badRet));
else
    msg = '[PASS] All energy retention values in [0, 1.1]';
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

badLeak = Tret.Leakage < 0 | Tret.Leakage > 1;
if any(badLeak)
    msg = sprintf('[WARN] %d rows have leakage outside [0, 1]', sum(badLeak));
else
    msg = '[PASS] All leakage ratios in [0, 1]';
end
log(msg); reportLines{end+1} = msg; %#ok<SAGROW>

%% -----------------------------------------------------------------------
%  8.7 -- Write validation report and review checklist
%  -----------------------------------------------------------------------
fprintf('\n--- 8.7 Writing reports ---\n');

% Validation report
fid = fopen(fullfile(dirNotes, 'validation_report.txt'), 'w');
fprintf(fid, 'Validation Report -- %s\n', datestr(now));
fprintf(fid, '==========================================\n\n');
for j = 1:numel(reportLines)
    fprintf(fid, '%s\n', reportLines{j});
end
fprintf(fid, '\n==========================================\n');
if allPass
    fprintf(fid, 'OVERALL: ALL CHECKS PASSED\n');
else
    fprintf(fid, 'OVERALL: SOME CHECKS FAILED -- review items above\n');
end
fclose(fid);

% Review checklist
checklistItems = {
    'All scripts (01-07) run without errors or warnings'
    'config.m is the single source of truth for all parameters'
    '72 filter coefficient files exist in filters/'
    'filter_metrics.csv has 72 rows with no NaN in critical columns'
    'Stopband attenuation values match expected theoretical ranges per window type'
    'Transition width decreases monotonically with increasing N'
    'Group delay equals N/2 samples (+/- 0.5) for every filter'
    'Manual sinc and fir1 designs agree within tolerance (or divergence documented)'
    '8 finalist filters have complete figure sets'
    'All exported audio plays correctly and is delay-aligned'
    'Residual audio contains audible mid/high content, minimal bass'
    'filtfilt output shows zero delay and sharper rolloff vs filter'
    'Energy retention > 95% for best candidate below fc'
    'All report_assets/ figures have labels, titles, legends, and >= 300 DPI'
    '00_run_all.m completes end-to-end from clean state without errors'
    'notes/final_design_choice.md contains justified selection with metric citations'
};

fid = fopen(fullfile(dirNotes, 'review_checklist.md'), 'w');
fprintf(fid, '# Review Checklist\n\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));
for j = 1:numel(checklistItems)
    fprintf(fid, '- [ ] %s\n', checklistItems{j});
end
fprintf(fid, '\n## Reviewer Notes\n\n');
fprintf(fid, '[Add notes after manual review]\n');
fclose(fid);

fprintf('  validation_report.txt written\n');
fprintf('  review_checklist.md written\n');

if allPass
    fprintf('\n=== ALL AUTOMATED VALIDATION CHECKS PASSED ===\n');
else
    fprintf('\n=== SOME CHECKS FAILED -- see notes/validation_report.txt ===\n');
end
