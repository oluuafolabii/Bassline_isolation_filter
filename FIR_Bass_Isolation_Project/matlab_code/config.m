%% config.m
% Central configuration for the FIR Bass Isolation project.
% Every script sources this file -- single point of truth for all parameters.

%% Resolve project root (parent of matlab_code/)
cfgDir   = fileparts(mfilename('fullpath'));
projRoot = fileparts(cfgDir);

%% Sampling rate
Fs = 48000;

%% Clip duration (seconds)
clipDuration = 20;

%% Experimental grid
cutoffsHz = [150, 200, 250];
ordersN   = [50, 100, 200, 500, 1000, 2000];
winNames  = ["rectwin", "hann", "hamming", "blackman"];

%% Frequency-response resolution
nFreqz = 2^17;  % 131072 points

%% Spectrogram parameters (periodic Hann for STFT)
stftWinLen  = 4096;
stftOverlap = 3072;
stftNfft    = 16384;

%% PSD parameters (periodic Hamming for Welch)
psdWinLen  = 8192;
psdOverlap = 6144;
psdNfft    = 32768;

%% Metric band-edge fractions relative to fc
passFrac = 0.8;   % passband upper edge = passFrac * fc
stopFrac = 2.0;   % stopband lower edge = stopFrac * fc

%% Folder paths
dirOrigAudio   = fullfile(projRoot, 'audio_original');
dirPreAudio    = fullfile(projRoot, 'audio_preprocessed');
dirFiltAudio   = fullfile(projRoot, 'audio_filtered');
dirFigOrig     = fullfile(projRoot, 'figures_original');
dirFigFilters  = fullfile(projRoot, 'figures_filters');
dirFigFiltered = fullfile(projRoot, 'figures_filtered');
dirFilters     = fullfile(projRoot, 'filters');
dirTables      = fullfile(projRoot, 'tables');
dirNotes       = fullfile(projRoot, 'notes');
dirReportFig   = fullfile(projRoot, 'report_assets', 'figures');
dirReportTbl   = fullfile(projRoot, 'report_assets', 'tables');
dirReportAud   = fullfile(projRoot, 'report_assets', 'audio');

%% Finalist filter definitions (Label, N, Window, fc)
finalists = struct( ...
    'label',  {'F1','F2','F3','F4','F5','F6','F7','F8'}, ...
    'N',      {100, 200, 200, 200, 1000, 1000, 1000, 1000}, ...
    'window', {'hamming','hamming','blackman','rectwin','hamming','blackman','hamming','hamming'}, ...
    'fc',     {200, 200, 200, 200, 200, 200, 150, 250} ...
);

%% Helper: build a FilterID string from fc, N, window name
filterID = @(fc, N, winName) sprintf('fc%d_N%d_%s', fc, N, winName);

%% Figure defaults
set(0, 'DefaultFigureVisible', 'off');  % suppress GUI during batch runs
figFontSize = 11;
figDPI      = 300;
