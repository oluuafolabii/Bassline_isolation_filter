# Rigorous Step-by-Step Project Plan
## Design and Implementation of a Windowed Low-Pass FIR Filter for Bass-Frequency Isolation in Music Audio

## 1. Project purpose

This project will design, implement, and evaluate a **windowed low-pass FIR filter** for isolating the **low-frequency content** of music audio, especially bass and kick components. The work will be carried out in MATLAB and will include theoretical analysis, filter design, signal analysis, listening evaluation, and final documentation.

This project is **not** framed as perfect bass-source separation. It is framed as **low-frequency component isolation** using frequency-selective FIR filtering.

## 2. Core project objectives

The project must accomplish the following:

1. Select suitable music excerpts that contain strong low-frequency content.
2. Analyze the original signals in the time and frequency domains.
3. Design practical FIR low-pass filters using the **windowing method**.
4. Compare multiple cutoffs, filter orders, and window types.
5. Apply the filters to the music excerpts.
6. Evaluate filter performance objectively and subjectively.
7. Compare the practical FIR response to the ideal low-pass response.
8. Export figures, tables, processed audio, and final results for the report and presentation.

## 3. Final deliverables

At the end of the project, you should have:

- MATLAB scripts for preprocessing, analysis, design, filtering, and evaluation
- Original and filtered `.wav` files
- Frequency-response plots
- Phase-response plots
- Group-delay values
- Time-domain waveform plots
- FFT or PSD plots
- Spectrogram plots
- Comparison tables for filter performance
- Listening evaluation notes
- A final report and presentation based on the collected evidence

---

# 4. Project folder structure

Create one main project folder and keep everything organized from the start.

```text
FIR_Bass_Isolation_Project/
│
├── audio_original/
├── audio_preprocessed/
├── audio_filtered/
├── figures_original/
├── figures_filters/
├── figures_filtered/
├── filters/
├── tables/
├── matlab_code/
├── notes/
└── report_assets/
```

## Folder purposes

- `audio_original/`: raw source clips
- `audio_preprocessed/`: trimmed, normalized, mono or resampled versions
- `audio_filtered/`: outputs after filtering
- `figures_original/`: baseline waveform, FFT, PSD, and spectrogram figures
- `figures_filters/`: filter impulse, magnitude, phase, and ideal comparison figures
- `figures_filtered/`: after-filter signal-analysis figures
- `filters/`: saved coefficient files and filter metadata
- `tables/`: CSV or Excel summary tables
- `matlab_code/`: all scripts and functions
- `notes/`: design decisions, observations, listening notes
- `report_assets/`: final selected figures and tables for the paper

---

# 5. Phase 1: define the experimental scope

## Step 1.1: Write the working problem statement

Write the working problem statement in your notes exactly like this:

> This project investigates the design and implementation of a windowed low-pass FIR filter for isolating low-frequency musical content in full-mix audio. The study compares different cutoff frequencies, filter orders, and window types, and evaluates performance using frequency-response metrics, time-frequency analysis, and listening tests.

Save this in:
- `notes/problem_statement.md`

## Step 1.2: Define the independent variables

These are the design variables that will change during the experiment.

### Sampling rates
Use:
- 44.1 kHz
- 48 kHz

If your source files have mixed rates, choose one common target rate for controlled comparison. Recommended:
- 48 kHz

### Cutoff frequencies
Use:
- 150 Hz
- 200 Hz
- 250 Hz

### Filter orders
Required baseline:
- 50
- 100
- 200

Recommended extended orders:
- 500
- 1000
- 2000

### Window types
Use:
- Rectangular
- Hann
- Hamming
- Blackman

## Step 1.3: Define the dependent variables

These are the outputs you will measure.

- passband ripple
- stopband attenuation
- transition width
- group delay
- low-frequency energy retained
- high-frequency leakage remaining
- spectrogram change
- listening quality ratings

---

# 6. Phase 2: dataset selection

## Step 2.1: Choose music excerpts

Choose **2 to 4 music excerpts**.

Recommended structure:
- 1 or 2 EDM excerpts
- 1 or 2 Alternative Rock excerpts

Each excerpt should:
- be 10 to 20 seconds long
- contain audible bass and kick activity
- come from a dense mix
- preferably have permission for academic use

## Step 2.2: Record metadata for each clip

Create a table called `clip_info.csv` in `tables/`.

Use these columns:

| Clip ID | File Name | Genre | Original Fs | Channels | Duration | Notes |
|---|---|---|---:|---:|---:|---|

Populate it as soon as files are selected.

## Step 2.3: Store original files

Put all raw audio files in:
- `audio_original/`

---

# 7. Phase 3: preprocessing

## Step 3.1: Read each audio file in MATLAB

Use `audioread`.

Tasks:
- load samples
- load original sampling rate
- inspect dimensions
- determine mono or stereo

## Step 3.2: Convert stereo to mono if needed

For analysis simplicity, use mono unless you are explicitly asked to preserve stereo throughout the analysis.

MATLAB operation:
```matlab
x = mean(x,2);
```

Document in your notes whether mono conversion was used.

## Step 3.3: Remove DC offset

Subtract the signal mean:

```matlab
x = x - mean(x);
```

## Step 3.4: Normalize amplitude

Normalize by peak amplitude:

```matlab
x = x / max(abs(x));
```

## Step 3.5: Resample if needed

If files do not all share the same sampling rate, resample them to the same target rate.

Recommended target:
- 48000 Hz

MATLAB operation:
```matlab
x = resample(x,48000,FsIn);
Fs = 48000;
```

## Step 3.6: Trim excerpts to consistent length

Choose one consistent excerpt duration. Recommended:
- 15 seconds
- or 20 seconds

Use the same duration for all clips.

## Step 3.7: Save preprocessed clips

Write the processed audio to:
- `audio_preprocessed/`

Also update the metadata table with:
- final sample rate
- final duration
- mono/stereo state

---

# 8. Phase 4: baseline analysis of the original audio

This phase happens **before** filter design.

## Step 4.1: Plot the original waveform

For each clip:

- plot amplitude vs time
- label axes clearly
- save as PNG

Use full-length waveform plots.

Save in:
- `figures_original/`

Suggested title:
- `Original Waveform - Clip 01`

## Step 4.2: Compute the FFT magnitude spectrum

For each clip:

1. compute FFT
2. compute magnitude
3. plot full spectrum
4. plot zoomed low-frequency region

Create at least these views:
- full range
- 0 to 1000 Hz
- 0 to 400 Hz

Why:
- the 0 to 400 Hz region is where you will justify cutoff selection

Save all plots in:
- `figures_original/`

## Step 4.3: Compute Welch PSD

Use `pwelch` to estimate PSD for more stable band-energy analysis.

Recommended settings:
- window length: 8192
- overlap: 6144
- nfft: 32768

Create:
- PSD full view
- PSD low-frequency zoom

Save in:
- `figures_original/`

## Step 4.4: Generate spectrograms

Use spectrograms because music is time-varying.

Recommended settings:
- window length: 4096
- overlap: 3072
- FFT length: 16384
- window type: Hann periodic

For each clip, create:
- full spectrogram
- low-frequency zoom from 0 to 500 Hz
- optional 0 to 2 kHz version for report readability

Save in:
- `figures_original/`

## Step 4.5: Decide which cutoff frequencies make most sense

Inspect the low-frequency FFT/PSD/spectrogram views and write a cutoff rationale note for each clip.

Answer:
- Is most bass energy below 150 Hz?
- Does 200 Hz preserve more musically useful bass?
- Does 250 Hz let too much leakage through?

Save rationale in:
- `notes/cutoff_decisions.md`

---

# 9. Phase 5: filter design setup

## Step 5.1: Create the design grid

Create a design grid table with all combinations of:

- cutoff frequencies: 150, 200, 250 Hz
- orders: 50, 100, 200, 500, 1000, 2000
- windows: Rectangular, Hann, Hamming, Blackman
- sampling rate(s)

Save this as:
- `tables/design_grid.csv`

## Step 5.2: Calculate normalized cutoff values

For each design condition, compute:

\[
W_n = \frac{f_c}{F_s/2}
\]

Store these values in the design grid.

This is the cutoff format used by `fir1`.

## Step 5.3: Decide design method

Use both if possible:

### Method A: `fir1`
Good for fast implementation.

### Method B: manual windowed-sinc
Better for theory transparency and showing the true window method.

The final report can say:
- filters were designed both analytically and with MATLAB’s built-in FIR tools for verification

---

# 10. Phase 6: implement the FIR filter designs

## Step 6.1: Design filters using `fir1`

For each condition:
```matlab
b = fir1(N, Wn, 'low', windowVector, 'scale');
```

Store:
- coefficients
- cutoff
- order
- window
- sample rate

## Step 6.2: Design filters manually using windowed-sinc

For each condition:

1. define sample index
2. center around \(N/2\)
3. compute ideal LPF sinc kernel
4. apply the window
5. normalize DC gain

Use:
```matlab
n = 0:N;
m = n - N/2;
hd = 2*fc/Fs * sinc(2*fc/Fs * m);
b = hd(:) .* w(:);
b = b / sum(b);
```

## Step 6.3: Save all filter coefficients

Save filters as `.mat` files in:
- `filters/`

Also create a filter summary table:
- `tables/filter_bank.csv`

Columns:
| Filter ID | Fs | fc | N | Window | Method | File Name |
|---|---:|---:|---:|---|---|---|

---

# 11. Phase 7: evaluate the filters before applying them to audio

Do this for every filter.

## Step 7.1: Plot impulse response

Use `stem` to plot `h[n]`.

Save in:
- `figures_filters/`

## Step 7.2: Compute frequency response

Use `freqz` with a high-resolution grid.

Recommended:
- 131072 points or similar high-resolution grid

Plot:
- linear magnitude
- dB magnitude

Create zooms:
- 0 to 1000 Hz
- 0 to 500 Hz
- full Nyquist view if needed

## Step 7.3: Plot phase response

Use:
- wrapped phase
- or unwrapped phase if cleaner

Save in:
- `figures_filters/`

## Step 7.4: Compute group delay

Use `grpdelay`.

Record:
- average group delay in passband
- expected delay in samples
- delay in milliseconds

Use table:
| Filter ID | Delay Samples | Delay ms |
|---|---:|---:|

Save in:
- `tables/group_delay.csv`

## Step 7.5: Compare practical response to ideal brick-wall response

For each filter:

1. define ideal LPF magnitude
2. overlay practical and ideal responses
3. compute a simple error metric like magnitude-response MSE

Save figures in:
- `figures_filters/`

Save numeric values in:
- `tables/ideal_comparison.csv`

## Step 7.6: Measure objective filter metrics

For every filter, compute:

### Passband ripple
Measure peak-to-peak variation in a defined passband.
Recommended passband:
- 0 to 0.8fc

### Stopband attenuation
Measure highest stopband level.
Recommended stopband start:
- 2fc

### Transition width
You may define it by:
- designer band edge difference
- or measured threshold crossings like -1 dB to -40 dB

Save everything in:
- `tables/filter_metrics.csv`

Columns:
| Filter ID | fc | N | Window | Passband Ripple dB | Stopband Attenuation dB | Transition Width Hz | Group Delay Samples | Group Delay ms |
|---|---:|---:|---|---:|---:|---:|---:|---:|

---

# 12. Phase 8: apply filters to the audio

## Step 8.1: Filter each clip

Use:
```matlab
y = filter(b,1,x);
```

Do this for every filter and every clip.

## Step 8.2: Delay-align the output for visual comparison

Because linear-phase FIR filters introduce about \(N/2\) samples of delay, shift the output left for comparison plots.

Use:
```matlab
d = round(N/2);
y_aligned = [y(d+1:end); zeros(d,1)];
```

## Step 8.3: Save filtered outputs

Export to:
- `audio_filtered/`

Naming convention example:
- `clip01_fs48000_fc200_N1000_hamming.wav`

---

# 13. Phase 9: post-filter signal analysis

Now compare original and filtered signals.

## Step 9.1: Plot original vs filtered waveforms

For each selected result:
- overlay waveform plots
- use same axis scaling
- if the full signal is too cluttered, also create a short zoomed segment

Save in:
- `figures_filtered/`

## Step 9.2: Plot original vs filtered FFT magnitude

For each selected result:
- plot original and filtered spectra on one graph
- include low-frequency zooms

Required zoom ranges:
- 0 to 1000 Hz
- 0 to 400 Hz

These are among your most important result figures.

## Step 9.3: Plot original vs filtered PSD

Use `pwelch` and compare:
- original PSD
- filtered PSD
- overlay
- low-frequency zoom

## Step 9.4: Generate original vs filtered spectrogram comparisons

Create:
- side-by-side figures
- or stacked subplots

At minimum include:
- original spectrogram
- filtered spectrogram
- bass-focused zoom

Save in:
- `figures_filtered/`

## Step 9.5: Compute band-energy metrics

For each clip and filter, compute energy in these bands:

- 0 to 150 Hz
- 0 to 200 Hz
- 0 to 250 Hz
- 250 to 1000 Hz
- 1000 Hz and above if desired

Use PSD integration.

Store in:
- `tables/band_energy_metrics.csv`

Columns:
| Clip ID | Filter ID | E_0_150 | E_0_200 | E_0_250 | E_250_1000 | Notes |
|---|---|---:|---:|---:|---:|---|

## Step 9.6: Compute retained low-frequency energy ratio

For each filter:
\[
\text{Energy Retained} = \frac{E_{\text{out below } f_c}}{E_{\text{in below } f_c}}
\]

Store in:
- `tables/energy_retention.csv`

---

# 14. Phase 10: listening evaluation

## Step 10.1: Select finalist filter outputs

Do not listen to every single condition in the full grid if there are too many.

Reduce to finalists based on objective metrics.

Recommended finalists:
- one short filter
- one medium filter
- one long filter
- one or two window types that performed best
- one or two cutoff values that seem most promising

## Step 10.2: Create listening evaluation sheets

Use a structured table:

| Clip ID | Filter ID | Bass Isolation /10 | Clarity /10 | Leakage /10 | Naturalness /10 | Notes |
|---|---|---:|---:|---:|---:|---|

## Step 10.3: Listen systematically

For each finalist:
- listen to original
- listen to filtered
- note whether bass is still recognizable
- note whether kick dominates
- note whether too much midrange remains
- note whether the output sounds too muffled

Save all notes in:
- `notes/listening_test_notes.md`

---

# 15. Phase 11: choose the best design

## Step 11.1: Combine objective and subjective results

You should not choose the best filter from listening alone or metrics alone.

Choose the final design based on:
- sufficient stopband attenuation
- manageable transition width
- acceptable delay
- retained bass energy
- good perceptual result

## Step 11.2: Write the final design rationale

Create:
- `notes/final_design_choice.md`

Include:
- selected sample rate
- selected cutoff
- selected order
- selected window
- why it was chosen over alternatives

---

# 16. Phase 12: prepare report and presentation assets

## Step 12.1: Select final figures

Choose only the strongest figures for the paper.

Recommended final figure set:

1. Original waveform
2. Original FFT or PSD
3. Original spectrogram
4. Filter impulse response comparison
5. Filter magnitude response comparison
6. Ideal vs practical LPF comparison
7. Phase response or group delay plot
8. Original vs filtered FFT overlay
9. Original vs filtered spectrogram comparison
10. Optional waveform zoom of filtered output

Copy final versions into:
- `report_assets/figures/`

## Step 12.2: Select final tables

Recommended final tables:

1. clip info
2. design grid summary
3. filter metrics table
4. group delay table
5. energy retention table
6. listening summary table

Copy final versions into:
- `report_assets/tables/`

## Step 12.3: Select final audio clips

Put:
- one original excerpt
- one best filtered output
- optional comparison outputs from different windows or orders

in:
- `report_assets/audio/`

---

# 17. Required MATLAB scripts

Create these scripts in this exact order.

## `01_preprocess_audio.m`
Tasks:
- load files
- convert to mono if needed
- remove DC
- normalize
- trim
- resample
- save processed files

## `02_analyze_original_audio.m`
Tasks:
- waveform
- FFT
- PSD
- spectrogram
- save original figures

## `03_design_filters.m`
Tasks:
- define grid
- compute normalized cutoffs
- design filters with `fir1`
- design filters manually
- save coefficients

## `04_evaluate_filters.m`
Tasks:
- impulse response
- `freqz`
- phase response
- `grpdelay`
- ideal overlay
- ripple, attenuation, transition-width calculations
- save filter metrics

## `05_apply_filters.m`
Tasks:
- load processed clips
- apply filter
- delay-align for comparison
- export WAV files

## `06_compare_results.m`
Tasks:
- original vs filtered waveform
- FFT comparisons
- PSD comparisons
- spectrogram comparisons
- energy retention calculations
- save summary figures and tables

## `07_listening_summary.m`
Tasks:
- organize shortlisted outputs
- summarize listening notes
- create final comparison summary

---

# 18. Final experimental sequence

If you want the shortest execution checklist, follow this exact order:

1. Create folders
2. Choose audio clips
3. Fill out `clip_info.csv`
4. Preprocess the clips
5. Save preprocessed audio
6. Generate original waveform plots
7. Generate original FFT/PSD plots
8. Generate original spectrograms
9. Choose candidate cutoffs
10. Build design grid
11. Design FIR filters
12. Save filter coefficients
13. Generate impulse-response plots
14. Generate magnitude/phase/group-delay plots
15. Compare practical vs ideal responses
16. Compute filter metrics
17. Apply filters to all clips
18. Delay-align filtered outputs
19. Save filtered WAV files
20. Generate original vs filtered waveform comparisons
21. Generate original vs filtered FFT/PSD comparisons
22. Generate original vs filtered spectrograms
23. Compute band-energy metrics
24. Compute low-frequency energy-retention ratios
25. Select finalists
26. Perform structured listening evaluation
27. Choose best design
28. Gather final figures, tables, and audio
29. Write report and build presentation

---

# 19. Minimum required evidence for a strong project

At minimum, you must have:

- at least one original waveform
- at least one original low-frequency FFT or PSD
- at least one original spectrogram
- at least two different window comparisons
- at least two different filter-order comparisons
- at least two different cutoff comparisons
- practical vs ideal LPF comparison
- measured passband ripple, stopband attenuation, transition width, and group delay
- one original vs filtered spectrum comparison
- one original vs filtered spectrogram comparison
- filtered audio examples
- a final design choice with justification

---

# 20. Final note on interpretation

When you write the final report, use language like:

> The designed FIR filter successfully isolated low-frequency content associated with bass and kick components in the music signal.

Do **not** say:

- the bass instrument was perfectly separated
- the bassline was exactly extracted
- the filter achieved complete source separation

That would overstate what a low-pass FIR filter can do.

---

# 21. Suggested next action

The next best action after this plan is:

1. create the folder structure
2. gather the audio excerpts
3. start `01_preprocess_audio.m`
4. then move immediately to baseline analysis of the original signals

Once those baseline figures exist, the rest of the project becomes much easier and more defensible.
