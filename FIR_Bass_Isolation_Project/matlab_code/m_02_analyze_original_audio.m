%% 02_analyze_original_audio.m
% Generate waveform, FFT, Welch PSD, and spectrogram plots for each
% preprocessed clip. Write cutoff_decisions.md with spectral observations.

run('config.m');

if ~exist(dirFigOrig, 'dir'), mkdir(dirFigOrig); end
if ~exist(dirNotes,   'dir'), mkdir(dirNotes);   end

wavFiles = dir(fullfile(dirPreAudio, '*.wav'));
assert(~isempty(wavFiles), 'No preprocessed .wav files found in %s', dirPreAudio);

stftWin = hann(stftWinLen, 'periodic');
psdWin  = hamming(psdWinLen, 'periodic');

for i = 1:numel(wavFiles)
    [x, ~] = audioread(fullfile(wavFiles(i).folder, wavFiles(i).name));
    [~, clipName, ~] = fileparts(wavFiles(i).name);
    t = (0:length(x)-1) / Fs;

    %% 1 -- Waveform
    fig = figure('Position', [100 100 900 350]);
    plot(t, x, 'Color', [0.2 0.4 0.8]);
    xlabel('Time (s)'); ylabel('Amplitude');
    title(sprintf('Waveform: %s', clipName), 'Interpreter', 'none');
    set(gca, 'FontSize', figFontSize);
    print(fig, fullfile(dirFigOrig, sprintf('%s_waveform.png', clipName)), '-dpng', sprintf('-r%d', figDPI));
    close(fig);

    %% 2 -- FFT magnitude spectrum
    N_fft = length(x);
    X = fft(x);
    Xmag = abs(X(1:floor(N_fft/2)+1));
    XmagdB = 20*log10(Xmag / max(Xmag) + eps);
    fAxis = (0:floor(N_fft/2)) * Fs / N_fft;

    fftViews = struct('label', {'full','0-1000Hz','0-400Hz'}, ...
                      'xlim',  {[0 Fs/2], [0 1000], [0 400]});

    for v = 1:numel(fftViews)
        fig = figure('Position', [100 100 900 400]);
        plot(fAxis, XmagdB, 'Color', [0.1 0.3 0.7]);
        xlim(fftViews(v).xlim); ylim([-120 0]);
        xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
        title(sprintf('FFT %s: %s', fftViews(v).label, clipName), 'Interpreter', 'none');
        set(gca, 'FontSize', figFontSize);
        % Mark candidate cutoffs
        for fc = cutoffsHz
            xline(fc, '--r', sprintf('%d Hz', fc), 'FontSize', 9, 'LabelOrientation', 'aligned');
        end
        print(fig, fullfile(dirFigOrig, sprintf('%s_fft_%s.png', clipName, fftViews(v).label)), ...
              '-dpng', sprintf('-r%d', figDPI));
        close(fig);
    end

    %% 3 -- Welch PSD
    [pxx, fPsd] = pwelch(x, psdWin, psdOverlap, psdNfft, Fs);
    pxxdB = 10*log10(pxx + eps);

    psdViews = struct('label', {'full','0-500Hz'}, 'xlim', {[0 Fs/2], [0 500]});
    for v = 1:numel(psdViews)
        fig = figure('Position', [100 100 900 400]);
        plot(fPsd, pxxdB, 'Color', [0.1 0.5 0.3]);
        xlim(psdViews(v).xlim);
        xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
        title(sprintf('Welch PSD %s: %s', psdViews(v).label, clipName), 'Interpreter', 'none');
        set(gca, 'FontSize', figFontSize);
        for fc = cutoffsHz
            xline(fc, '--r', sprintf('%d Hz', fc), 'FontSize', 9, 'LabelOrientation', 'aligned');
        end
        print(fig, fullfile(dirFigOrig, sprintf('%s_psd_%s.png', clipName, psdViews(v).label)), ...
              '-dpng', sprintf('-r%d', figDPI));
        close(fig);
    end

    %% 4 -- Spectrograms
    [S, fSpec, tSpec] = spectrogram(x, stftWin, stftOverlap, stftNfft, Fs);
    SdB = 10*log10(abs(S).^2 + eps);

    specViews = struct('label', {'full','0-500Hz','0-2000Hz'}, ...
                       'ylim',  {[0 Fs/2], [0 500], [0 2000]});
    for v = 1:numel(specViews)
        fig = figure('Position', [100 100 1000 450]);
        imagesc(tSpec, fSpec, SdB);
        axis xy; ylim(specViews(v).ylim);
        xlabel('Time (s)'); ylabel('Frequency (Hz)');
        title(sprintf('Spectrogram %s: %s', specViews(v).label, clipName), 'Interpreter', 'none');
        colorbar; colormap('jet');
        set(gca, 'FontSize', figFontSize);
        print(fig, fullfile(dirFigOrig, sprintf('%s_spec_%s.png', clipName, specViews(v).label)), ...
              '-dpng', sprintf('-r%d', figDPI));
        close(fig);
    end

    fprintf('  Figures saved for %s\n', clipName);
end

%% Write cutoff_decisions.md template
fid = fopen(fullfile(dirNotes, 'cutoff_decisions.md'), 'w');
fprintf(fid, '# Cutoff Frequency Observations\n\n');
fprintf(fid, 'After inspecting the low-frequency FFT, PSD, and spectrogram plots:\n\n');
fprintf(fid, '## 150 Hz\n');
fprintf(fid, '- Is most bass energy below 150 Hz? \n');
fprintf(fid, '- Observations: [fill in after inspection]\n\n');
fprintf(fid, '## 200 Hz\n');
fprintf(fid, '- Does 200 Hz capture musically useful bass? \n');
fprintf(fid, '- Observations: [fill in after inspection]\n\n');
fprintf(fid, '## 250 Hz\n');
fprintf(fid, '- Does 250 Hz leak too much midrange? \n');
fprintf(fid, '- Observations: [fill in after inspection]\n\n');
fprintf(fid, '## Recommendation\n');
fprintf(fid, '- Primary cutoff for presentation: [fill in]\n');
fprintf(fid, '- Justification: [fill in]\n');
fclose(fid);

fprintf('  cutoff_decisions.md template written to notes/\n');
