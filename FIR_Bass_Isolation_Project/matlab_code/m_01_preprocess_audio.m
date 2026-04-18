%% 01_preprocess_audio.m
% Load raw audio, convert to mono, remove DC, normalize, resample to 48 kHz,
% trim to clipDuration seconds, save preprocessed clips, and write clip_info.csv.

run('config.m');

wavFiles = dir(fullfile(dirOrigAudio, '*.wav'));
assert(~isempty(wavFiles), 'No .wav files found in %s', dirOrigAudio);

if ~exist(dirPreAudio, 'dir'), mkdir(dirPreAudio); end
if ~exist(dirTables,   'dir'), mkdir(dirTables);   end

clipIDs   = {};
filenames = {};
origFs    = [];
finalFs   = [];
channels  = [];
durations = [];

for i = 1:numel(wavFiles)
    srcPath = fullfile(wavFiles(i).folder, wavFiles(i).name);
    [x, FsIn] = audioread(srcPath);
    info = audioinfo(srcPath);

    nCh = size(x, 2);

    % Mono conversion
    if nCh >= 2
        x = mean(x, 2);
    end

    % DC removal
    x = x - mean(x);

    % Peak normalize (eps guards against silence)
    x = x ./ (max(abs(x)) + eps);

    % Resample to target Fs
    if FsIn ~= Fs
        x = resample(x, Fs, FsIn);
    end

    % Trim to exactly clipDuration seconds
    targetLen = Fs * clipDuration;
    if length(x) > targetLen
        x = x(1:targetLen);
    elseif length(x) < targetLen
        x = [x; zeros(targetLen - length(x), 1)]; %#ok<AGROW>
    end

    % Save
    [~, baseName, ~] = fileparts(wavFiles(i).name);
    outName = sprintf('clip%d_%s.wav', i, baseName);
    outPath = fullfile(dirPreAudio, outName);
    audiowrite(outPath, x, Fs);

    % Metadata
    clipIDs{end+1}   = sprintf('clip%d', i); %#ok<SAGROW>
    filenames{end+1} = outName;              %#ok<SAGROW>
    origFs(end+1)    = FsIn;                 %#ok<SAGROW>
    finalFs(end+1)   = Fs;                   %#ok<SAGROW>
    channels(end+1)  = nCh;                  %#ok<SAGROW>
    durations(end+1) = length(x) / Fs;       %#ok<SAGROW>

    fprintf('  Preprocessed: %s -> %s (%.1f s)\n', wavFiles(i).name, outName, durations(end));
end

% Write clip_info.csv
T = table(clipIDs(:), filenames(:), origFs(:), finalFs(:), channels(:), durations(:), ...
    'VariableNames', {'ClipID','Filename','OriginalFs','FinalFs','Channels','Duration_s'});
writetable(T, fullfile(dirTables, 'clip_info.csv'));

fprintf('  Saved clip_info.csv (%d clips)\n', numel(clipIDs));
