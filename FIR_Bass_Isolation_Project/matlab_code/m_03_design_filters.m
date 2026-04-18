%% 03_design_filters.m
% Generate all 72 filter conditions (3 cutoffs x 6 orders x 4 windows).
% For each: design via manual windowed-sinc AND fir1, save coefficients,
% write design_grid.csv and filter_bank.csv.

run('config.m');

if ~exist(dirFilters, 'dir'), mkdir(dirFilters); end
if ~exist(dirTables,  'dir'), mkdir(dirTables);  end

gridRows  = {};
bankRows  = {};
filtCount = 0;

for fc = cutoffsHz
    Wn = fc / (Fs/2);

    for N = ordersN
        assert(mod(N, 2) == 0, 'Filter order N=%d must be even for Type I FIR', N);
        L = N + 1;  % filter length (odd)

        for wIdx = 1:numel(winNames)
            wName = winNames(wIdx);
            filtCount = filtCount + 1;
            fID = filterID(fc, N, wName);

            % Generate window vector (symmetric for FIR design)
            switch wName
                case "rectwin",  w = rectwin(L);
                case "hann",     w = hann(L, 'symmetric');
                case "hamming",  w = hamming(L, 'symmetric');
                case "blackman", w = blackman(L, 'symmetric');
                otherwise, error('Unknown window: %s', wName);
            end

            %% Manual windowed-sinc design
            n  = (0:N).';
            m  = n - N/2;
            hd = 2*fc/Fs * sinc(2*fc/Fs * m);
            b_manual = hd .* w;
            b_manual = b_manual / sum(b_manual);  % DC gain = 1

            %% fir1 cross-verification design
            b_fir1 = fir1(N, Wn, w, 'scale');

            %% Save .mat
            matFile = sprintf('filt_%s.mat', fID);
            save(fullfile(dirFilters, matFile), ...
                 'b_manual', 'b_fir1', 'fc', 'N', 'Fs', 'wName', 'Wn', 'fID');

            %% Accumulate grid row
            gridRows{end+1} = {fID, Fs, fc, N, char(wName), Wn}; %#ok<SAGROW>

            %% Accumulate bank rows (one per method)
            bankRows{end+1} = {fID, Fs, fc, N, char(wName), 'manual_sinc', matFile}; %#ok<SAGROW>
            bankRows{end+1} = {fID, Fs, fc, N, char(wName), 'fir1',        matFile}; %#ok<SAGROW>
        end
    end
end

%% Write design_grid.csv
gridMat = vertcat(gridRows{:});
Tgrid = cell2table(gridMat, ...
    'VariableNames', {'FilterID','Fs','fc','N','Window','Wn'});
writetable(Tgrid, fullfile(dirTables, 'design_grid.csv'));

%% Write filter_bank.csv
bankMat = vertcat(bankRows{:});
Tbank = cell2table(bankMat, ...
    'VariableNames', {'FilterID','Fs','fc','N','Window','Method','FileName'});
writetable(Tbank, fullfile(dirTables, 'filter_bank.csv'));

fprintf('  Designed %d filter conditions, saved to %s\n', filtCount, dirFilters);
fprintf('  design_grid.csv : %d rows\n', height(Tgrid));
fprintf('  filter_bank.csv : %d rows\n', height(Tbank));
