# Design and Implementation of a Low-Pass FIR Filter for Bassline Isolation in Audio Signals Using the Windowing Method

---

## Abstract

This report presents the design, implementation, and evaluation of a low-pass Finite Impulse Response (FIR) filter for isolating bass-frequency components from complex audio signals. Using the windowing method, 72 filter configurations were systematically explored across three cutoff frequencies (150, 200, 250 Hz), six filter orders (50, 100, 200, 500, 1000, 2000), and four window functions (Rectangular, Hann, Hamming, Blackman). Each filter was applied to four diverse audio clips spanning bass drum, bass guitar, dubstep, and funk bass genres. Filter performance was evaluated through frequency-domain metrics including stopband attenuation, transition bandwidth, passband ripple, and group delay, as well as energy-based metrics such as bass retention ratio and spectral leakage ratio. The selected design — a 1000th-order filter with a Blackman window and 200 Hz cutoff — achieved 76.5 dB of stopband attenuation, 87.7% average bass energy retention, and only 4.0% spectral leakage, with a group delay of 10.42 ms. A zero-phase filtering comparison using `filtfilt` was also conducted. All design, filtering, and analysis were performed in MATLAB R2025a.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Theoretical Background](#2-theoretical-background)
3. [Methodology](#3-methodology)
4. [Filter Design and Implementation](#4-filter-design-and-implementation)
5. [Results and Analysis](#5-results-and-analysis)
6. [Discussion](#6-discussion)
7. [Conclusion](#7-conclusion)
8. [References](#8-references)
9. [Appendices](#9-appendices)

---

## 1. Introduction

### 1.1 Background and Motivation

In modern music production and audio engineering, the ability to isolate specific frequency components from a mixed audio signal is a fundamental task. Basslines and kick drums occupy the low-frequency range of the audio spectrum, typically below 250 Hz, and are often layered with mid-range instruments, vocals, and high-frequency elements such as hi-hats and cymbals. Isolating these low-frequency components has practical applications in remixing, audio equalization, content analysis, and music transcription.

Digital filtering provides a principled approach to this problem. Among the various filter types, FIR (Finite Impulse Response) filters are widely used in audio processing due to their inherent stability, guaranteed linear phase response (when designed with symmetric coefficients), and straightforward implementation via discrete-time convolution. The windowing method is one of the most well-established techniques for FIR filter design, offering a direct and intuitive approach to approximating an ideal frequency-selective filter.

### 1.2 Objective

The objective of this project is to design and implement a low-pass FIR filter using the windowing method to isolate low-frequency components — specifically basslines and kick drums — from complex, multi-layered audio signals. The project investigates the effects of cutoff frequency, filter order, and window function on filter performance, and evaluates each configuration against an ideal low-pass (brick-wall) filter response.

### 1.3 Scope

The project encompasses the following:

- Preprocessing of four raw audio tracks into a standardized format (mono, 48 kHz, 20-second duration, peak-normalized).
- Frequency-domain analysis of the original audio to characterize spectral content.
- Systematic design of 72 FIR low-pass filters spanning the parameter space.
- Objective evaluation of all filters using magnitude response, phase response, group delay, passband ripple, stopband attenuation, transition bandwidth, and brick-wall mean squared error.
- Application of all filters to all audio clips with energy-based performance metrics (bass retention and spectral leakage).
- Selection of a best overall design based on a composite scoring function.
- Comparison of causal filtering (`filter`) versus zero-phase filtering (`filtfilt`).

---

## 2. Theoretical Background

### 2.1 Ideal Low-Pass Filter

An ideal low-pass filter passes all frequency components below a cutoff frequency \( f_c \) with unity gain and completely rejects all components above \( f_c \). Its frequency response is defined as:

\[
H_{ideal}(e^{j\omega}) = \begin{cases} 1, & |\omega| \leq \omega_c \\ 0, & \omega_c < |\omega| \leq \pi \end{cases}
\]

where \( \omega_c = 2\pi f_c / F_s \) is the normalized cutoff frequency and \( F_s \) is the sampling rate. The corresponding impulse response is obtained via the inverse discrete-time Fourier transform:

\[
h_d[n] = \frac{\omega_c}{\pi} \cdot \text{sinc}\left(\frac{\omega_c}{\pi}(n - M)\right) = \frac{2f_c}{F_s} \cdot \text{sinc}\left(\frac{2f_c}{F_s}(n - M)\right)
\]

where \( M = N/2 \) is the center of symmetry for a filter of order \( N \). This ideal impulse response is infinite in duration and non-causal, making it unrealizable in practice. The windowing method addresses this by truncating \( h_d[n] \) to a finite length and shaping the truncation to control spectral artifacts.

### 2.2 The Windowing Method

The windowing method designs a causal, finite-length FIR filter by multiplying the ideal impulse response with a finite-length window function \( w[n] \):

\[
h[n] = h_d[n] \cdot w[n], \quad n = 0, 1, \ldots, N
\]

The choice of window function controls the trade-off between the main-lobe width (which determines the transition bandwidth) and the side-lobe level (which determines the stopband attenuation). A narrower main lobe provides a sharper transition but at the cost of higher side lobes and thus more spectral leakage.

### 2.3 Window Functions

Four window functions were used in this project:

**Rectangular Window (rectwin):**

\[
w[n] = 1, \quad 0 \leq n \leq N
\]

The simplest window. It provides the narrowest main lobe (sharpest transition) but the highest side-lobe level (-13 dB), resulting in significant spectral leakage. Its stopband attenuation is limited to approximately 21 dB.

**Hann Window:**

\[
w[n] = 0.5 - 0.5\cos\left(\frac{2\pi n}{N}\right)
\]

A raised-cosine window that reduces side lobes to approximately -31 dB. It provides a good balance between transition width and attenuation, with a theoretical minimum stopband attenuation of about 44 dB for large \( N \).

**Hamming Window:**

\[
w[n] = 0.54 - 0.46\cos\left(\frac{2\pi n}{N}\right)
\]

A modified raised-cosine window optimized to minimize the nearest side lobe. It achieves approximately -41 dB side-lobe level and a minimum stopband attenuation of about 53 dB, making it one of the most commonly used windows in FIR filter design.

**Blackman Window:**

\[
w[n] = 0.42 - 0.5\cos\left(\frac{2\pi n}{N}\right) + 0.08\cos\left(\frac{4\pi n}{N}\right)
\]

A three-term cosine window that provides excellent side-lobe suppression (-57 dB). Its minimum stopband attenuation exceeds 74 dB, at the expense of a wider main lobe and therefore a broader transition band compared to the Hamming or Hann windows.

### 2.4 FIR Filter Properties

A Type I FIR filter (odd length, even order, symmetric coefficients) guarantees a generalized linear phase response:

\[
\angle H(e^{j\omega}) = -\omega \cdot \frac{N}{2}
\]

This means every frequency component experiences the same time delay of \( N/2 \) samples (the group delay), preserving the shape of the signal in the time domain. The group delay in seconds is:

\[
\tau = \frac{N}{2F_s}
\]

### 2.5 Discrete-Time Convolution and Filtering

Applying the FIR filter to an input signal \( x[n] \) is performed via discrete-time convolution:

\[
y[n] = \sum_{k=0}^{N} h[k] \cdot x[n-k]
\]

This operation is implemented efficiently in MATLAB using the `filter` function for causal (one-pass) filtering, and the `filtfilt` function for zero-phase (forward-backward) filtering. The `filtfilt` approach eliminates the phase distortion entirely by applying the filter twice (once forward, once on the time-reversed result), effectively doubling the filter order and squaring the magnitude response.

### 2.6 Performance Metrics

The following metrics were used to evaluate filter performance:

- **Passband Ripple (dB):** The maximum deviation from unity gain within the passband (0 to \( 0.8 \cdot f_c \)).
- **Stopband Attenuation (dB):** The minimum attenuation achieved in the stopband (\( 2.0 \cdot f_c \) to \( F_s/2 \)).
- **Transition Width (Hz):** The frequency span from the -1 dB point to the -40 dB point of the magnitude response.
- **Group Delay (ms):** The constant time delay introduced by the linear-phase filter, equal to \( N/(2F_s) \).
- **Brick-Wall MSE:** The mean squared error between the filter's magnitude response and the ideal brick-wall response, quantifying how closely the filter approximates the ideal.
- **Bass Energy Retention:** The ratio of bass-band energy in the filtered signal to that in the original signal.
- **Spectral Leakage:** The ratio of above-cutoff energy in the filtered output to above-cutoff energy in the original input.

---

## 3. Methodology

### 3.1 Tools and Environment

All processing was performed in MATLAB R2025a with the Signal Processing Toolbox (v25.1). Key functions used include `fir1`, `freqz`, `grpdelay`, `pwelch`, `spectrogram`, `resample`, `filter`, `filtfilt`, `audioread`, and `audiowrite`. All figures were generated at 300 DPI resolution for publication quality.

### 3.2 Audio Material

Four audio tracks were selected to represent a diverse range of bass-heavy content:

| Clip ID | Description | Genre/Content | Original File |
|---------|-------------|---------------|---------------|
| Clip 1 | Bass Drum | Percussive low-frequency content | [bass_drum.wav](audio_original/bass_drum.wav) |
| Clip 2 | Bass Guitar | Tonal/melodic bass content | [bass_guitar.wav](audio_original/bass_guitar.wav) |
| Clip 3 | Dubstep | Synthesized sub-bass with complex layering | [dubstep.wav](audio_original/dubstep.wav) |
| Clip 4 | Funk Bass | Rhythmic bass guitar with upper harmonics | [funk_bass.wav](audio_original/funk_bass.wav) |

All four tracks were originally sampled at 44,100 Hz in stereo format.

### 3.3 Audio Preprocessing

Each raw audio file was preprocessed through the following pipeline to ensure consistency across all analyses:

1. **Mono Conversion:** Stereo tracks were summed to a single channel.
2. **DC Removal:** Any DC offset was subtracted from the signal.
3. **Peak Normalization:** The signal was scaled so that the maximum absolute amplitude equals 1.0.
4. **Resampling:** All clips were resampled from 44,100 Hz to 48,000 Hz using MATLAB's polyphase `resample` function, providing finer frequency resolution for low-frequency analysis.
5. **Duration Trimming:** Each clip was trimmed to exactly 20 seconds, yielding 960,000 samples per clip.

The preprocessed clips are available in [`audio_preprocessed/`](audio_preprocessed/) and metadata is recorded in [`clip_info.csv`](tables/clip_info.csv).

### 3.4 Original Audio Analysis

Before filtering, each preprocessed clip was analyzed in both the time and frequency domains:

- **Time-Domain Waveform:** To observe the amplitude envelope and dynamic structure.
- **FFT Magnitude Spectrum:** Computed using a full-length FFT, plotted at three zoom levels (full spectrum, 0–1000 Hz, and 0–400 Hz with cutoff frequency markers) to identify the distribution of bass content.
- **Power Spectral Density (PSD):** Estimated via Welch's method (8192-sample Hamming window, 75% overlap, 32768-point FFT) for a smooth spectral estimate, plotted at full range and 0–500 Hz.
- **Spectrogram:** Short-time Fourier transform (4096-sample periodic Hann window, 75% overlap, 16384-point FFT) plotted at full range, 0–500 Hz, and 0–2000 Hz to visualize time-frequency evolution.

These analyses informed the selection of 200 Hz as the primary cutoff frequency, as it captures the fundamental frequencies of bass instruments while excluding most mid-range and harmonic content. Representative figures for Clip 1 are shown below:

- [Original Waveform](report_assets/figures/fig01_orig_waveform.png)
- [Original FFT — Low-Frequency Detail](report_assets/figures/fig02_orig_fft_lowfreq.png)
- [Original Spectrogram](report_assets/figures/fig03_orig_spectrogram.png)

All original-audio analysis plots (9 per clip, 36 total) are available in [`figures_original/`](figures_original/).

### 3.5 Experimental Design

A full factorial experimental grid was constructed across three parameters:

| Parameter | Values | Count |
|-----------|--------|-------|
| Cutoff Frequency \( f_c \) | 150, 200, 250 Hz | 3 |
| Filter Order \( N \) | 50, 100, 200, 500, 1000, 2000 | 6 |
| Window Function | Rectangular, Hann, Hamming, Blackman | 4 |

This yields a total of **3 × 6 × 4 = 72 unique filter configurations**. All filter orders are even, ensuring a Type I (odd-length, symmetric) linear-phase FIR filter. The full grid is recorded in [`design_grid.csv`](tables/design_grid.csv).

### 3.6 Processing Pipeline

The project was organized as a sequential pipeline of eight MATLAB scripts, each performing a distinct stage:

| Stage | Script | Function |
|-------|--------|----------|
| 0 | [`m_00_check_dependencies.m`](matlab_code/m_00_check_dependencies.m) | Verify MATLAB version, toolbox, and function availability |
| 1 | [`m_01_preprocess_audio.m`](matlab_code/m_01_preprocess_audio.m) | Standardize all audio clips |
| 2 | [`m_02_analyze_original_audio.m`](matlab_code/m_02_analyze_original_audio.m) | Time/frequency analysis of original audio |
| 3 | [`m_03_design_filters.m`](matlab_code/m_03_design_filters.m) | Design all 72 FIR filters |
| 4 | [`m_04_evaluate_filters.m`](matlab_code/m_04_evaluate_filters.m) | Compute frequency-response metrics for all filters |
| 5 | [`m_05_apply_filters.m`](matlab_code/m_05_apply_filters.m) | Apply filters to audio; compute energy metrics |
| 6 | [`m_06_compare_results.m`](matlab_code/m_06_compare_results.m) | Generate before/after comparison figures |
| 7 | [`m_07_select_best_and_summarize.m`](matlab_code/m_07_select_best_and_summarize.m) | Select best design; curate report assets |
| 8 | [`m_08_review_and_validate.m`](matlab_code/m_08_review_and_validate.m) | Automated validation and quality checks |

A master runner script ([`m_00_run_all.m`](matlab_code/m_00_run_all.m)) executes the entire pipeline sequentially, and a central configuration file ([`config.m`](matlab_code/config.m)) serves as the single source of truth for all parameters.

---

## 4. Filter Design and Implementation

### 4.1 Windowed-Sinc Design Procedure

For each of the 72 filter configurations, the FIR filter coefficients were computed manually using the windowed-sinc method:

1. Compute the ideal low-pass impulse response centered at \( M = N/2 \):

\[
h_d[n] = \frac{2f_c}{F_s} \cdot \text{sinc}\left(\frac{2f_c}{F_s}(n - M)\right), \quad n = 0, 1, \ldots, N
\]

2. Generate the symmetric window vector \( w[n] \) of length \( N+1 \).

3. Apply the window:

\[
h[n] = h_d[n] \cdot w[n]
\]

4. Normalize for unity DC gain:

\[
h[n] \leftarrow \frac{h[n]}{\sum_{k=0}^{N} h[k]}
\]

This normalization ensures that a DC (0 Hz) input passes through the filter without amplitude change.

### 4.2 Cross-Verification with MATLAB's fir1

As a validation step, every filter was independently designed using MATLAB's built-in `fir1` function with the same parameters:

```matlab
b_fir1 = fir1(N, Wn, w, 'scale');
```

where `Wn = fc / (Fs/2)` is the normalized cutoff frequency. The coefficients from the manual design and from `fir1` were compared, and all 72 filters passed the cross-verification check with a maximum coefficient difference below 0.01.

### 4.3 Filter Coefficient Storage

Each filter's coefficients (both manual and `fir1` versions) along with metadata (cutoff frequency, order, window name, sampling rate) were saved as `.mat` files using the naming convention `filt_{fc}_{N}_{window}.mat`. A total of 72 `.mat` files were produced in [`filters/`](filters/) and cataloged in [`filter_bank.csv`](tables/filter_bank.csv).

### 4.4 Frequency Response Evaluation

The frequency response of each filter was computed using `freqz` with 131,072 frequency points for high resolution:

```matlab
[H, f] = freqz(b, 1, nFreqz, Fs);
```

From the complex frequency response \( H(f) \), the following were extracted:

- **Magnitude Response** \( |H(f)| \) in dB: Plotted at three zoom levels (full spectrum, 0–1000 Hz, 0–500 Hz) to observe passband, transition, and stopband behavior.
- **Phase Response** \( \angle H(f) \): Verified to be linear across the passband.
- **Group Delay** via `grpdelay`: Confirmed to be constant at \( N/2 \) samples (\( \pm 0.5 \) sample tolerance).
- **Brick-Wall Overlay:** The filter's magnitude response was plotted against the ideal step function for visual comparison.

Detailed plots for the selected design (F6) are available:
[Magnitude Response](figures_filters/fc200_N1000_blackman_mag_full.png) | [Magnitude 0–1000 Hz](figures_filters/fc200_N1000_blackman_mag_0-1000Hz.png) | [Magnitude 0–500 Hz](figures_filters/fc200_N1000_blackman_mag_0-500Hz.png) | [Phase Response](figures_filters/fc200_N1000_blackman_phase.png) | [Group Delay](figures_filters/fc200_N1000_blackman_grpdelay.png) | [Brick-Wall Overlay](figures_filters/fc200_N1000_blackman_brickwall.png) | [Impulse Response](figures_filters/fc200_N1000_blackman_impulse.png)

All filter characteristic figures (7 per finalist, plus comparison overlays) are in [`figures_filters/`](figures_filters/).

### 4.5 Finalist Selection

From the 72-filter grid, eight finalist configurations were selected for in-depth evaluation, chosen to represent key comparisons:

| Label | Cutoff (Hz) | Order \( N \) | Window | Design Intent |
|-------|-------------|---------------|--------|---------------|
| F1 | 200 | 100 | Hamming | Low-order baseline |
| F2 | 200 | 200 | Hamming | Moderate order |
| F3 | 200 | 200 | Blackman | Window comparison (vs. F2) |
| F4 | 200 | 200 | Rectangular | Window comparison (vs. F2, F3) |
| F5 | 200 | 1000 | Hamming | High-order Hamming |
| F6 | 200 | 1000 | Blackman | High-order Blackman |
| F7 | 150 | 1000 | Hamming | Lower cutoff comparison |
| F8 | 250 | 1000 | Hamming | Higher cutoff comparison |

Finalists F1–F4 allow comparison across orders and windows at a fixed cutoff. Finalists F5–F6 compare Hamming vs. Blackman at high order. Finalists F5, F7, F8 compare the effect of cutoff frequency at fixed order and window.

---

## 5. Results and Analysis

### 5.1 Frequency Response of Finalist Filters

The following table summarizes the key frequency-domain metrics for all eight finalist filters (full data: [`filter_metrics.csv`](tables/filter_metrics.csv)):

| Label | FilterID | Passband Ripple (dB) | Stopband Atten. (dB) | Trans. Width (Hz) | Group Delay (ms) | Brick-Wall MSE |
|-------|----------|----------------------|----------------------|--------------------|--------------------|----------------|
| F1 | fc200\_N100\_hamming | 0.72 | 4.7 | 795.2 | 1.04 | 0.00650 |
| F2 | fc200\_N200\_hamming | 2.29 | 15.8 | 464.9 | 2.08 | 0.00171 |
| F3 | fc200\_N200\_blackman | 1.60 | 10.5 | 587.6 | 2.08 | 0.00273 |
| F4 | fc200\_N200\_rectwin | 4.61 | 23.2 | 247.4 | 2.08 | 0.00097 |
| F5 | fc200\_N1000\_hamming | 1.14 | 59.1 | 113.0 | 10.42 | 0.00034 |
| F6 | fc200\_N1000\_blackman | 1.79 | 76.5 | 151.8 | 10.42 | 0.00044 |
| F7 | fc150\_N1000\_hamming | 1.90 | 60.8 | 113.3 | 10.42 | 0.00034 |
| F8 | fc250\_N1000\_hamming | 0.63 | 58.6 | 113.5 | 10.42 | 0.00034 |

**Key observations from the frequency-domain analysis:**

**Effect of Filter Order:** Increasing the filter order dramatically improves performance. From N=100 (F1) to N=1000 (F5), stopband attenuation increases from 4.7 dB to 59.1 dB, and transition width narrows from 795.2 Hz to 113.0 Hz. The cost is increased group delay (1.04 ms to 10.42 ms), which remains well within perceptible thresholds for audio applications. See [Order Comparison Plot](report_assets/figures/fig05_order_comparison.png).

**Effect of Window Function:** At the same order (N=200), the rectangular window (F4) achieves the narrowest transition band (247.4 Hz) and highest attenuation (23.2 dB) among the three, but at the cost of severe passband ripple (4.61 dB). The Hamming window (F2) provides a strong balance, while the Blackman window (F3) shows the lowest ripple but wider transition. At N=1000, the Blackman window (F6) achieves 76.5 dB attenuation — 17.4 dB more than Hamming (F5) — confirming that the Blackman window's superior side-lobe suppression becomes decisive at high orders. See [Window Comparison Plot](report_assets/figures/fig04_window_comparison.png).

**Effect of Cutoff Frequency:** Comparing F7 (150 Hz), F5 (200 Hz), and F8 (250 Hz), all at N=1000 with a Hamming window, the transition widths and attenuation levels are nearly identical (~113 Hz and ~59 dB). The cutoff frequency primarily affects which spectral content is retained, not the shape of the transition. See [Cutoff Comparison Plot](report_assets/figures/fig06_cutoff_comparison.png).

### 5.2 Comparison with Ideal Low-Pass Filter

The brick-wall MSE metric quantifies how closely each filter approximates the ideal step response ([Brick-Wall Overlay](report_assets/figures/fig07_brickwall_overlay.png)). The results show a clear trend: MSE decreases sharply with increasing filter order, from 0.00650 (N=100) to 0.00034 (N=1000) for the Hamming window. At N=1000, both Hamming and Blackman achieve MSE values below 0.0005, indicating an excellent approximation of the ideal filter. The rectangular window achieves the lowest MSE at each order (e.g., 0.00097 at N=200 vs. 0.00171 for Hamming), reflecting its narrower main lobe, but this comes at the cost of poor side-lobe suppression, which manifests as spectral leakage when applied to real audio signals.

For very high orders (N=2000), filters approach the ideal even more closely (MSE < 0.00023), but the additional group delay (20.83 ms) provides diminishing practical returns compared to N=1000.

### 5.3 Energy-Based Performance on Audio Signals

The following table summarizes the average bass energy retention and spectral leakage for each finalist filter across all four audio clips (full data: [`energy_retention.csv`](tables/energy_retention.csv), detailed band energies: [`band_energy_metrics.csv`](tables/band_energy_metrics.csv)):

| Label | FilterID | Avg. Retention | Avg. Leakage |
|-------|----------|----------------|--------------|
| F1 | fc200\_N100\_hamming | 0.920 | 0.512 |
| F2 | fc200\_N200\_hamming | 0.776 | 0.193 |
| F3 | fc200\_N200\_blackman | 0.835 | 0.293 |
| F4 | fc200\_N200\_rectwin | 0.628 | 0.045 |
| F5 | fc200\_N1000\_hamming | 0.921 | 0.030 |
| F6 | fc200\_N1000\_blackman | 0.877 | 0.040 |
| F7 | fc150\_N1000\_hamming | 0.812 | 0.051 |
| F8 | fc250\_N1000\_hamming | 0.972 | 0.032 |

**Key observations from the energy analysis:**

**Low-Order Filters Leak Significantly:** F1 (N=100) retains 92% of bass energy but allows 51.2% of above-cutoff energy to pass through, defeating the purpose of isolation. This is a direct consequence of its 795 Hz transition width and negligible stopband attenuation.

**High-Order Filters Achieve True Isolation:** F5 and F6 (N=1000) achieve leakage below 4%, meaning over 96% of unwanted spectral content is successfully attenuated. F5 retains slightly more bass (92.1% vs. 87.7%) than F6, reflecting the Hamming window's marginally narrower transition band.

**The Rectangular Window Paradox:** F4 (N=200, rectangular) has the lowest leakage among the N=200 group (4.5%) but also the lowest retention (62.8%). Its aggressive transition removes some bass content along with the stopband, making it a poor practical choice despite its sharp cutoff.

**Cutoff Frequency Matters for Content:** F8 (250 Hz) retains 97.2% of energy in its target band because more harmonic content of bass instruments lies below 250 Hz. F7 (150 Hz) retains only 81.2%, as it cuts into the upper fundamentals of some bass instruments. The 200 Hz cutoff (F5, F6) represents the best compromise for diverse audio material. See [Energy Retention Bar Chart](report_assets/figures/fig12_energy_retention.png).

### 5.4 Per-Clip Analysis

Performance varied across audio clips, reflecting their different spectral characteristics:

**Clip 1 (Bass Drum):** Dominated by low-frequency energy below 100 Hz. High retention across most filters; even F7 (150 Hz cutoff) achieved 68.6% retention. The best filter F6 achieved 87.8% retention and 2.2% leakage. See: [Retention Bar Chart](figures_filtered/clip1_bass_drum_retention_bar.png) | [Leakage Bar Chart](figures_filtered/clip1_bass_drum_leakage_bar.png) | [Filtered Waveform](figures_filtered/clip1_bass_drum_fc200_N1000_blackman_waveform.png) | [Filtered FFT](figures_filtered/clip1_bass_drum_fc200_N1000_blackman_fft_0-400Hz.png) | [Filtered Spectrogram](figures_filtered/clip1_bass_drum_fc200_N1000_blackman_spec_0-500Hz.png)

**Clip 2 (Bass Guitar):** Bass guitar fundamentals extend up to 200 Hz with significant harmonics above. F6 achieved 72.0% retention and 0.5% leakage — the lowest leakage of any clip, indicating effective separation of the tonal bass from its harmonics. See: [Retention Bar Chart](figures_filtered/clip2_bass_guitar_retention_bar.png) | [Leakage Bar Chart](figures_filtered/clip2_bass_guitar_leakage_bar.png)

**Clip 3 (Dubstep):** Sub-bass content is extremely strong (concentrated below 150 Hz). Nearly all N=1000 filters achieved >98% retention. F6 achieved 99.1% retention and 5.7% leakage, reflecting the dense mid-frequency content present in dubstep production. See: [Retention Bar Chart](figures_filtered/clip3_dubstep_retention_bar.png) | [Leakage Bar Chart](figures_filtered/clip3_dubstep_leakage_bar.png)

**Clip 4 (Funk Bass):** Rhythmic bass guitar with energy distributed across a wider range. F6 achieved 92.0% retention and 7.5% leakage. The higher leakage compared to other clips reflects the broader harmonic structure of funk bass. See: [Retention Bar Chart](figures_filtered/clip4_funk_bass_retention_bar.png) | [Leakage Bar Chart](figures_filtered/clip4_funk_bass_leakage_bar.png)

All before/after comparison figures (234 total) are available in [`figures_filtered/`](figures_filtered/). All filtered audio files (68 total) are in [`audio_filtered/`](audio_filtered/).

### 5.5 Zero-Phase Filtering Comparison

A `filtfilt` (zero-phase) implementation was applied using the F5 filter (N=1000, Hamming, 200 Hz) for comparison with the standard causal `filter` implementation. Filtered audio results are shown in the [Filtered FFT Overlay](report_assets/figures/fig10_filt_fft_overlay.png) and [Filtered Spectrogram](report_assets/figures/fig11_filt_spectrogram.png).

**Magnitude Response:** The `filtfilt` operation squares the magnitude response of the filter, effectively doubling the filter order. This results in steeper roll-off and approximately double the stopband attenuation in dB (from ~59 dB to ~118 dB). See [`filtfilt` vs. `filter` Magnitude Comparison](report_assets/figures/fig13_filtfilt_mag.png).

**Phase Response:** The `filtfilt` output has exactly zero phase distortion across all frequencies, whereas the causal `filter` output exhibits the expected linear phase delay of N/2 = 500 samples (10.42 ms). In the causal implementation, this delay was compensated by shifting the output by 500 samples.

**Waveform Comparison:** After delay compensation, the causal and zero-phase filtered waveforms are nearly identical in the passband. The primary difference appears at transients and near the cutoff frequency, where the zero-phase version preserves the exact temporal alignment of bass events. See [`filtfilt` vs. `filter` Waveform Comparison](report_assets/figures/fig14_filtfilt_waveform.png).

---

## 6. Discussion

### 6.1 Best Design Selection

A composite scoring function was used to rank all finalist filters:

\[
\text{Score} = \text{StopAtten} + 100 \times \text{Retention} - 1000 \times \text{Leakage} - 1000 \times \text{MSE}
\]

with a penalty applied to any design with group delay exceeding 25 ms. Based on this scoring, **F6 (fc = 200 Hz, N = 1000, Blackman window)** was selected as the best overall design (see [final_design_choice.md](notes/final_design_choice.md) for detailed justification).

F6's dominant advantage is its 76.5 dB stopband attenuation — the highest among all finalists — which translates to over 20,000× power reduction in the stopband. While F5 (Hamming) achieves slightly higher retention (92.1% vs. 87.7%), F6's superior attenuation ensures cleaner isolation with minimal high-frequency artifacts. The 10.42 ms group delay ([Group Delay Plot](report_assets/figures/fig08_group_delay.png)) is imperceptible in most audio playback scenarios and can be compensated through sample shifting. The filter's impulse response is shown in [Impulse Response](report_assets/figures/fig09_impulse_response.png).

### 6.2 Trade-Offs in Filter Design

The results clearly illustrate the fundamental trade-offs in FIR filter design using the windowing method:

1. **Order vs. Delay:** Higher filter orders provide sharper frequency selectivity but introduce proportionally more latency. For offline (non-real-time) audio processing, this trade-off favors high orders. For real-time applications, N=500 filters with ~5 ms delay may be more appropriate.

2. **Window Choice vs. Transition Width:** The Blackman window provides the best stopband suppression but at the cost of a wider transition band (151.8 Hz vs. 113.0 Hz for Hamming at N=1000). This means some content near the cutoff frequency is attenuated rather than cleanly passed or rejected.

3. **Retention vs. Leakage:** These metrics are inversely correlated through the transition band. A wider transition (Blackman) tends to slightly reduce retention of near-cutoff bass content while a narrower transition (Hamming) passes slightly more above-cutoff content.

4. **Cutoff Frequency Selection:** The choice of cutoff frequency is highly content-dependent. A 200 Hz cutoff provides good general-purpose bass isolation, but specific applications (e.g., isolating only sub-bass content below 80 Hz) would require different cutoff choices informed by the spectral characteristics of the target audio.

### 6.3 Practical Applications

The implemented bass isolation filter has direct applications in:

- **Audio Remixing and Mashups:** Extracting basslines from existing tracks to combine with new arrangements.
- **Music Transcription:** Isolating bass content to aid in identifying notes and rhythmic patterns.
- **Audio Equalization and Mastering:** Analyzing and adjusting the low-frequency balance of a mix.
- **Sound System Calibration:** Evaluating sub-bass content for speaker and room tuning.
- **Music Information Retrieval:** Feature extraction for bass-pattern classification and beat detection.

### 6.4 Limitations

- The windowing method, while intuitive and robust, does not provide independent control over passband ripple and stopband attenuation, unlike optimal methods such as the Parks-McClellan (Remez) algorithm.
- A fixed-cutoff low-pass filter cannot adapt to audio content with time-varying spectral characteristics. Adaptive or time-frequency methods would be needed for such scenarios.
- The project evaluates isolation quality through energy metrics but does not include formal perceptual listening tests with multiple evaluators.
- FIR filtering via convolution is computationally more expensive than equivalent IIR designs, though this is largely mitigated by modern hardware.

---

## 7. Conclusion

This project successfully designed, implemented, and evaluated a low-pass FIR filter for bassline isolation using the windowing method. Through systematic exploration of 72 filter configurations across three cutoff frequencies, six filter orders, and four window functions, applied to four diverse audio clips, the study demonstrated the following key findings:

1. **Filter order is the most impactful parameter.** Increasing the order from 50 to 1000 reduces the transition width from over 1500 Hz to approximately 113 Hz and increases stopband attenuation from under 2 dB to over 59 dB (Hamming) or 76.5 dB (Blackman).

2. **The Blackman window provides the best stopband attenuation** at 76.5 dB for N=1000, outperforming the Hamming window (59.1 dB), the Hann window (63.4 dB), and the rectangular window (32.9 dB) at the same order.

3. **A 200 Hz cutoff frequency is effective for general-purpose bass isolation,** providing a strong compromise between retaining fundamental bass content (87.7% average retention) and rejecting mid/high-frequency content (4.0% average leakage).

4. **The selected design (F6: fc = 200 Hz, N = 1000, Blackman window)** achieves excellent performance across all four test clips, with the highest stopband attenuation among all finalists and a group delay of only 10.42 ms.

5. **Zero-phase filtering via `filtfilt` further improves performance** by squaring the magnitude response and eliminating phase distortion, at the cost of requiring the entire signal to be available in advance (non-causal processing).

6. **Manual windowed-sinc implementation and MATLAB's `fir1` function produce equivalent results,** validating the theoretical design procedure.

The project demonstrates that the windowing method remains a powerful, well-understood, and effective approach to FIR filter design for audio signal processing applications. The comprehensive evaluation framework developed here — spanning frequency-domain metrics, energy-based audio metrics, and cross-validated filter design — provides a robust methodology that can be adapted to other filter design problems.

---

## 8. References

1. Oppenheim, A. V., Willsky, A. S., & Nawab, S. H. (1997). *Signals and Systems* (2nd ed.). Prentice Hall.
2. Oppenheim, A. V., & Schafer, R. W. (2010). *Discrete-Time Signal Processing* (3rd ed.). Pearson.
3. Proakis, J. G., & Manolakis, D. G. (2007). *Digital Signal Processing: Principles, Algorithms, and Applications* (4th ed.). Pearson.
4. Harris, F. J. (1978). On the use of windows for harmonic analysis with the discrete Fourier transform. *Proceedings of the IEEE*, 66(1), 51–83.
5. MathWorks. (2025). *Signal Processing Toolbox Documentation*. MATLAB R2025a.

---

## 9. Appendices

### Appendix A: Full Experimental Grid

A total of 72 filter configurations were designed, spanning the following parameter combinations:

- **Cutoff Frequencies:** 150, 200, 250 Hz
- **Filter Orders:** 50, 100, 200, 500, 1000, 2000
- **Window Functions:** Rectangular, Hann, Hamming, Blackman

Full metrics for all 72 filters are available in [`tables/filter_metrics.csv`](tables/filter_metrics.csv). Energy retention and leakage data for all 72 filters applied to all 4 clips (288 combinations) are available in [`tables/energy_retention.csv`](tables/energy_retention.csv).

### Appendix B: Figure Index

The following curated figures are included in [`report_assets/figures/`](report_assets/figures/):

| Figure | Description |
|--------|-------------|
| [fig01](report_assets/figures/fig01_orig_waveform.png) | Original audio waveform (Clip 1) |
| [fig02](report_assets/figures/fig02_orig_fft_lowfreq.png) | Original audio FFT — low-frequency detail with cutoff markers |
| [fig03](report_assets/figures/fig03_orig_spectrogram.png) | Original audio spectrogram |
| [fig04](report_assets/figures/fig04_window_comparison.png) | Window function comparison — magnitude response overlay |
| [fig05](report_assets/figures/fig05_order_comparison.png) | Filter order comparison — magnitude response overlay |
| [fig06](report_assets/figures/fig06_cutoff_comparison.png) | Cutoff frequency comparison — magnitude response overlay |
| [fig07](report_assets/figures/fig07_brickwall_overlay.png) | Brick-wall overlay — selected filter vs. ideal low-pass |
| [fig08](report_assets/figures/fig08_group_delay.png) | Group delay plot — constant phase delay verification |
| [fig09](report_assets/figures/fig09_impulse_response.png) | Impulse response of selected filter |
| [fig10](report_assets/figures/fig10_filt_fft_overlay.png) | Filtered vs. original FFT overlay |
| [fig11](report_assets/figures/fig11_filt_spectrogram.png) | Filtered audio spectrogram |
| [fig12](report_assets/figures/fig12_energy_retention.png) | Energy retention bar chart — all finalists |
| [fig13](report_assets/figures/fig13_filtfilt_mag.png) | `filtfilt` vs. `filter` magnitude response comparison |
| [fig14](report_assets/figures/fig14_filtfilt_waveform.png) | `filtfilt` vs. `filter` waveform comparison |

### Appendix C: Audio Deliverables

The following audio files are included in [`report_assets/audio/`](report_assets/audio/):

| File | Description |
|------|-------------|
| [`original_excerpt.wav`](report_assets/audio/original_excerpt.wav) | Preprocessed Clip 1 (bass drum, 20 s, 48 kHz mono) |
| [`best_filtered.wav`](report_assets/audio/best_filtered.wav) | Clip 1 filtered with F6 (fc200, N1000, Blackman) |
| [`best_residual.wav`](report_assets/audio/best_residual.wav) | Residual signal (original minus filtered) from F6 on Clip 1 |
| [`baseline_N100.wav`](report_assets/audio/baseline_N100.wav) | Clip 1 filtered with F1 (fc200, N100, Hamming) for comparison |
| [`best_filtfilt.wav`](report_assets/audio/best_filtfilt.wav) | Clip 1 with zero-phase filtering (filtfilt, F5 parameters) |

### Appendix D: MATLAB Code

All source code is available in the [`matlab_code/`](matlab_code/) directory:

| File | Purpose |
|------|---------|
| [`config.m`](matlab_code/config.m) | Central configuration (parameters, paths, finalist definitions) |
| [`m_00_run_all.m`](matlab_code/m_00_run_all.m) | Master pipeline runner |
| [`m_00_check_dependencies.m`](matlab_code/m_00_check_dependencies.m) | Dependency and environment verification |
| [`m_01_preprocess_audio.m`](matlab_code/m_01_preprocess_audio.m) | Audio standardization pipeline |
| [`m_02_analyze_original_audio.m`](matlab_code/m_02_analyze_original_audio.m) | Original audio time/frequency analysis |
| [`m_03_design_filters.m`](matlab_code/m_03_design_filters.m) | Windowed-sinc and fir1 filter design |
| [`m_04_evaluate_filters.m`](matlab_code/m_04_evaluate_filters.m) | Frequency-response metric computation |
| [`m_05_apply_filters.m`](matlab_code/m_05_apply_filters.m) | Filter application and energy metric computation |
| [`m_06_compare_results.m`](matlab_code/m_06_compare_results.m) | Before/after comparison figure generation |
| [`m_07_select_best_and_summarize.m`](matlab_code/m_07_select_best_and_summarize.m) | Best design selection and report asset curation |
| [`m_08_review_and_validate.m`](matlab_code/m_08_review_and_validate.m) | Automated validation and quality gate |

### Appendix E: Validation Summary

Automated validation ([`m_08_review_and_validate.m`](matlab_code/m_08_review_and_validate.m)) confirmed the following (see also: [dependency_check.txt](notes/dependency_check.txt)):

- All 72 filter `.mat` files, 343 figures, 68 filtered audio files, and 6 CSV tables were generated successfully.
- Stopband attenuation values are consistent with theoretical window limits (Blackman > 74 dB, Hamming > 53 dB for large N).
- Manual windowed-sinc coefficients match `fir1` coefficients within a tolerance of 0.01 for all 72 filters.
- Group delay equals exactly N/2 samples (± 0.5 sample tolerance) for all filters.
- Transition width decreases monotonically with increasing filter order for all window types.
- Energy retention values fall within [0, 1.1] and leakage values within [0, 1] for all clip-filter combinations.

