# Final Design Selection

## Finalist Metrics Summary

| Label | FilterID | StopAtten (dB) | TransWidth (Hz) | GD (ms) | Retention | Leakage | BW-MSE |
|-------|----------|---------------|-----------------|---------|-----------|---------|--------|
| F1 | fc200_N100_hamming | 4.7 | 795.2 | 1.04 | 0.9196 | 0.511868 | 0.006499 |
| F2 | fc200_N200_hamming | 15.8 | 464.9 | 2.08 | 0.7764 | 0.193463 | 0.001708 |
| F3 | fc200_N200_blackman | 10.5 | 587.6 | 2.08 | 0.8347 | 0.293494 | 0.002731 |
| F4 | fc200_N200_rectwin | 23.2 | 247.4 | 2.08 | 0.6283 | 0.044609 | 0.000967 |
| F5 | fc200_N1000_hamming | 59.1 | 113.0 | 10.42 | 0.9209 | 0.030433 | 0.000339 |
| F6 | fc200_N1000_blackman | 76.5 | 151.8 | 10.42 | 0.8774 | 0.039886 | 0.000439 |
| F7 | fc150_N1000_hamming | 60.8 | 113.3 | 10.42 | 0.8123 | 0.050964 | 0.000341 |
| F8 | fc250_N1000_hamming | 58.6 | 113.5 | 10.42 | 0.9719 | 0.032173 | 0.000341 |

## Selected Design

- **Label:** F6
- **FilterID:** fc200_N1000_blackman
- **fc:** 200 Hz
- **N:** 1000
- **Window:** blackman
- **Fs:** 48000 Hz

## Justification

Selected based on highest composite score combining stopband attenuation,
energy retention, minimal leakage, and brick-wall approximation error.
Group delay remains within acceptable bounds (< 25 ms).

**Note:** Update this section after the personal listening evaluation to
incorporate subjective impressions and confirm or override the objective selection.
