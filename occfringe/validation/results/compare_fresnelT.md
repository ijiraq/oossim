# fresnelT.c vs occfringe.legacy.fresnelT

Maximum |delta I_disk| over each profile. 'C vs port' compares the C binary with the Python port
running every legacy quirk; the 'fix' columns show how far the profile moves when one quirk is
corrected (table: exact Fresnel integrals; planck: photon-weighted Planck instead of the
exp(x-1) Wien form; interp: correct linear interpolation in the stellar-disk average;
AU: 1.496e11 m instead of 1.5e11 m).

| aa (m) | AU | R/F | R*/F | N_lam | C vs port | fix table | fix planck | fix interp | fix AU | all fixed |
|---|---|---|---|---|---|---|---|---|---|---|
| 200 | 40 | 0.16 | 0.00 | 1 | 5.0e-09 | 3.2e-04 | 0.0e+00 | 0.0e+00 | 3.3e-03 | 3.6e-03 |
| 800 | 40 | 0.60 | 0.22 | 5 | 5.0e-09 | 9.4e-04 | 1.4e-02 | 5.1e-02 | 2.2e-03 | 4.2e-02 |
| 1500 | 40 | 1.12 | 0.07 | 20 | 5.3e-09 | 3.4e-03 | 2.2e-02 | 6.3e-02 | 2.0e-03 | 5.2e-02 |
| 3000 | 40 | 2.24 | 0.60 | 20 | 5.0e-09 | 6.4e-04 | 1.5e-02 | 4.2e-02 | 2.2e-03 | 3.2e-02 |
| 5000 | 300 | 1.42 | 0.00 | 10 | 5.0e-09 | 2.4e-03 | 2.6e-02 | 0.0e+00 | 2.4e-03 | 2.4e-02 |
| 1200 | 40 | 0.94 | 0.16 | 10 | 5.0e-09 | 1.2e-03 | 1.2e-02 | 2.9e-02 | 1.1e-03 | 1.9e-02 |

Worst C vs port difference: 5.3e-09

## Rectangle tiling vs exact disk

Same bandpass, stellar disk and sampling (all quirks fixed); the only difference is the
occulter: fresnelT's order-5 rectangle mosaic versus the exact circular-disk solution
(occfringe.fresnel.circle_obstacle_field).

| aa (m) | AU | R/F | R*/F | max abs(order-5 boxes - exact disk) |
|---|---|---|---|---|
| 200 | 40 | 0.16 | 0.00 | 1.1e-03 |
| 800 | 40 | 0.60 | 0.22 | 5.9e-03 |
| 1500 | 40 | 1.12 | 0.07 | 1.4e-02 |
| 3000 | 40 | 2.24 | 0.60 | 8.7e-03 |
| 5000 | 300 | 1.42 | 0.00 | 1.1e-02 |
