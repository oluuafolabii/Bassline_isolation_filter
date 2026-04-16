%% 00_check_dependencies.m
% Verifies MATLAB version, required toolboxes, functions, audio files,
% and runs a smoke test before any project code executes.

fprintf('=== FIR Bass Isolation: Dependency Check ===\n\n');
logLines = {};

%% 0.1 -- MATLAB version (require R2020b / 9.9+)
v = ver('MATLAB');
matlabVer = str2double(v.Version);
if matlabVer >= 9.9
    msg = sprintf('[PASS] MATLAB %s (%s)', v.Version, v.Release);
else
    msg = sprintf('[FAIL] MATLAB %s -- R2020b (9.9) or later required', v.Version);
    error(msg);
end
fprintf('%s\n', msg);
logLines{end+1} = msg;

%% 0.2 -- Signal Processing Toolbox
if license('test', 'Signal_Toolbox')
    spVer = ver('signal');
    msg = sprintf('[PASS] Signal Processing Toolbox %s', spVer.Version);
else
    msg = '[FAIL] Signal Processing Toolbox license not available';
    error(msg);
end
fprintf('%s\n', msg);
logLines{end+1} = msg;

%% 0.3 -- Required toolbox functions
toolboxFcns = {'fir1','freqz','grpdelay','pwelch','spectrogram', ...
               'resample','filtfilt','rectwin','hann','hamming','blackman'};
for k = 1:numel(toolboxFcns)
    if exist(toolboxFcns{k}, 'file') > 0
        msg = sprintf('[PASS] %s', toolboxFcns{k});
    else
        msg = sprintf('[FAIL] %s -- not found', toolboxFcns{k});
        error(msg);
    end
    fprintf('  %s\n', msg);
    logLines{end+1} = msg; %#ok<SAGROW>
end

%% 0.4 -- Core MATLAB functions
coreFcns = {'audioread','audiowrite','fft','ifft','sinc','filter','conv', ...
            'stem','plot','subplot','figure','saveas','trapz', ...
            'mean','max','abs','round','length','size','find','zeros', ...
            'writetable','table'};
for k = 1:numel(coreFcns)
    if exist(coreFcns{k}, 'builtin') > 0 || exist(coreFcns{k}, 'file') > 0
        msg = sprintf('[PASS] %s', coreFcns{k});
    else
        msg = sprintf('[WARN] %s -- not found (may be a keyword)', coreFcns{k});
    end
    fprintf('  %s\n', msg);
    logLines{end+1} = msg; %#ok<SAGROW>
end

%% 0.5 -- Audio files in audio_original/
scriptDir = fileparts(mfilename('fullpath'));
projRoot  = fileparts(scriptDir);
audioDir  = fullfile(projRoot, 'audio_original');
wavFiles  = dir(fullfile(audioDir, '*.wav'));
nWav = numel(wavFiles);
if nWav >= 2
    msg = sprintf('[PASS] %d .wav files found in audio_original/', nWav);
else
    msg = sprintf('[FAIL] Only %d .wav file(s) in audio_original/ -- need at least 2', nWav);
    error(msg);
end
fprintf('%s\n', msg);
logLines{end+1} = msg;

%% 0.6 -- Smoke test: design a filter, compute frequency response
try
    b_test = fir1(50, 0.1, hann(51));
    [H, ~] = freqz(b_test, 1, 1024, 48000);
    assert(numel(H) == 1024, 'freqz output length unexpected');
    msg = '[PASS] Smoke test (fir1 + freqz)';
catch ME
    msg = sprintf('[FAIL] Smoke test -- %s', ME.message);
    error(msg);
end
fprintf('%s\n', msg);
logLines{end+1} = msg;

%% Write log
notesDir = fullfile(projRoot, 'notes');
if ~exist(notesDir, 'dir'), mkdir(notesDir); end
fid = fopen(fullfile(notesDir, 'dependency_check.txt'), 'w');
fprintf(fid, 'Dependency Check Log -- %s\n', datestr(now));
fprintf(fid, '=========================================\n');
for k = 1:numel(logLines)
    fprintf(fid, '%s\n', logLines{k});
end
fclose(fid);

fprintf('\n=== All dependency checks PASSED ===\n');
