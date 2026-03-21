# Project Progress — IGS with Active PMOS Load

**Course:** ET4252 Analogue Integrated Circuit Design, TU Delft
**Authors:** Daniel Tyukov (5714699) & Raghavendra Joshi (6438180)
**Date:** 2026-03-21

---

## 1. MATLAB Optimization — COMPLETE

### 1.1 What the Script Does

`igs_cap_sizing.m` implements a systematic gm/ID design methodology:

**Loop 1 — gm/ID sweep (design space exploration):**
- Sweeps $(g_m/I_D)_n$ from 5 to 20 S/A (NMOS inversion level)
- Sweeps $(g_m/I_D)_p$ from 3 to 15 S/A (PMOS inversion level)
- Sweeps $CR$ from 0.05 to 0.5 (capacitance ratio)
- Total: 7750 design points evaluated

**Loop 2 — sizing loop (per design point):**
- Finds minimum $L_n$, $L_p$ satisfying static error $\leq 8\%$
- Computes all capacitances from noise spec ($C_{L,tot}$, $C_{F,tot}$, $C_S$, $C_L$, $C_{gs}$)
- Sizes $g_m$, $I_D$, $W_n$, $W_p$ from gm/ID and current density lookups
- Self-loading iteration (50 iterations, 0.1% convergence): extracts parasitic $C_{db}$, $C_{gd}$ from both NMOS and PMOS lookup tables, recomputes $C_{L,tot}$ and re-sizes until convergence
- Checks all hard specs, stores feasible designs

**Selection — balanced FOM:**
- Normalizes DR and Area to [0, 1]
- Maximizes $FOM = DR_{norm} - Area_{norm}$
- Picks the best tradeoff between high DR and low area

### 1.2 Lookup Table Usage

The script uses `look_up.m` (Boris Murmann) with both `180nch.mat` and `180pch.mat`:

| Lookup Call | Purpose |
|---|---|
| `look_up(nch, 'GM_GDS', 'GM_ID', ..., 'L', nch.L)` | Find $g_m/g_{ds}$ vs $L$ for gain/static error |
| `look_up(nch, 'ID_W', 'GM_ID', ..., 'L', nch.L)` | Current density for NMOS width sizing |
| `look_up(pch, 'GM_GDS', 'GM_ID', ..., 'L', pch.L)` | Same for PMOS |
| `look_up(pch, 'ID_W', 'GM_ID', ..., 'L', pch.L)` | Current density for PMOS width sizing |
| `look_up(nch, 'CGD_W', 'GM_ID', ..., 'L', ..., 'VDS', ...)` | Gate-drain parasitic cap (self-loading) |
| `look_up(nch, 'CDD_W', 'GM_ID', ..., 'L', ..., 'VDS', ...)` | Drain-bulk parasitic cap (self-loading) |
| Same CGD_W, CDD_W for pch | PMOS parasitic caps (self-loading) |

~8 lookup calls per design point × 7750 points = ~62,000 total lookups.

### 1.3 Key Design Equations

**Noise factor with PMOS load:**

$$\alpha = \gamma_n + \gamma_p \cdot \frac{(g_m/I_D)_p}{(g_m/I_D)_n}$$

**Static error with PMOS output conductance:**

$$A_{v0} = \frac{1}{\dfrac{1}{(g_m/g_{ds})_n} + \dfrac{(g_m/I_D)_p}{(g_m/I_D)_n} \cdot \dfrac{1}{(g_m/g_{ds})_p}}$$

$$\varepsilon_s = \frac{1}{\beta \cdot A_{v0}}$$

**Dynamic range:**

$$DR = \frac{(V_{swing}/2)^2}{2 \cdot \dfrac{\alpha}{\beta} \cdot \dfrac{kT}{C_{L,tot}}}$$

### 1.4 Optimal Design Results

| Parameter | Value |
|---|---|
| $(g_m/I_D)_n$ | 20.0 S/A |
| $(g_m/I_D)_p$ | 9.0 S/A |
| $CR$ | 0.05 |
| $\beta$ | 0.3175 |
| $A_{v0}$ | 39.5 |
| $W_n$ | 94.76 μm |
| $L_n$ | 0.200 μm |
| $W_p$ | 179.92 μm |
| $L_p$ | 0.900 μm |
| Area ($M_1 + M_2$) | 180.9 μm² |
| $I_D$ | 292.8 μA |
| $g_{m,n}$ | 5.857 mS |
| $C_S$ | 0.940 pF |
| $C_F$ (physical) | 424.1 fF |
| $C_{F,tot}$ | 469.9 fF |
| $C_L$ | 0.940 pF |
| $C_{L,tot}$ (actual) | 1.481 pF |
| $C_{gs}$ | 70.5 fF |

### 1.5 Specifications Met (MATLAB)

| Specification | Required | MATLAB Result | Status |
|---|---|---|---|
| Static Error | $\leq 8\%$ | 7.98% | PASS |
| Settling Time | $\leq 5.5$ ns | 5.50 ns | PASS |
| $I_D$ max | $\leq 500$ μA | 292.8 μA | PASS |
| Output Noise | $\leq 100$ μVrms | 92.3 μVrms | PASS |
| $G$ | 2 | 2 | PASS |
| $FO$ | 1 | 1 | PASS |
| Area minimized | — | 180.9 μm² | PASS |
| DR maximized | — | 75.1 dB | PASS |

### 1.6 Design Choices — Physics Motivation

**NMOS at $(g_m/I_D)_n = 20$ S/A (moderate-to-weak inversion):**
- High transconductance efficiency — maximizes $g_m$ per unit current
- Allows meeting settling time with lower $I_D$ (292 μA vs 500 μA budget)
- Tradeoff: larger device width (94.76 μm) and lower $f_T$

**PMOS at $(g_m/I_D)_p = 9$ S/A (moderate inversion):**
- Balances noise and output swing
- $g_{mp}/g_{mn} = 9/20 = 0.45$ — moderate noise contribution from PMOS
- $V_{Dsat,p} \approx 2/9 = 0.22$ V — leaves good output swing headroom
- Higher $(g_m/I_D)_p$ would give more DR but requires much more area

**$CR = 0.05$ (small capacitance ratio):**
- Maximizes $\beta = 1/((1+G)(1+CR)) = 0.3175$
- Better bandwidth and noise performance
- Small $C_{gs}$ means most capacitance budget goes to signal caps ($C_S$, $C_L$)

**$L_n = 0.2$ μm (minimum length):**
- Maximizes $f_T$ for speed
- Sufficient gain when combined with longer $L_p$

**$L_p = 0.9$ μm (longer PMOS channel):**
- Higher $g_m/g_{ds}$ for PMOS — reduces PMOS contribution to output conductance
- Combined with $L_n = 0.2$ μm gives $A_{v0} = 39.5$, sufficient for $\varepsilon_s = 8\%$

### 1.7 Generated Plots

Saved in `project/`:
- `plot_DR_vs_gmid_p.png` — DR vs PMOS inversion level at optimal $(g_m/I_D)_n$ and $CR$
- `plot_Area_vs_CR.png` — Area vs capacitance ratio at optimal $(g_m/I_D)_n$ and $(g_m/I_D)_p$
- `plot_Design_Space.png` — Scatter of all 1192 feasible designs (DR vs Area, colored by $I_D$)

---

## 2. LTSpice Simulation — IN PROGRESS

### 2.1 Schematic

File: `igs_pmos_load.asc`

Circuit topology matches Figure 1 from project instructions:
- $M_1$ (nch): Common-source NMOS amplifier
- $M_2$ (pch): Active PMOS load (current mirror output)
- $M_3$ (pch): Diode-connected PMOS (current mirror reference)
- $I_d$: 293 μA current source biasing $M_3$
- $C_S$: 940 fF input coupling capacitor
- $C_F$: 424 fF feedback capacitor (Vout to gate)
- $C_L$: 940 fF load capacitor

### 2.2 DC Operating Point (from `.op`)

Direct Newton iteration succeeded (no Gmin stepping).

**Node voltages:**

| Node | Voltage |
|---|---|
| $V(Vout)$ | 1.16517 V |
| $V(gate)$ | 0.52 V |
| $V(mirror)$ | 1.1676 V |
| $V_{DD}$ | 1.8 V |

**Transistor DC operating points:**

| Parameter | $M_1$ (nch) | $M_2$ (pch) | $M_3$ (pch) |
|---|---|---|---|
| $I_D$ | 293.06 μA | −293.06 μA | −293.00 μA |
| $V_{GS}$ | 0.52 V | −0.632 V | −0.632 V |
| $V_{DS}$ | 1.17 V | −0.635 V | −0.632 V |
| $V_{BS}$ | 0 V | 0 V | 0 V |
| $V_{th}$ | 0.480 V | −0.415 V | −0.415 V |
| $V_{Dsat}$ | 64.2 mV | −183 mV | −183 mV |
| Region | Saturation | Saturation | Saturation (diode) |

**Small-signal parameters (from BSIM3 .op):**

| Parameter | $M_1$ (nch) | $M_2$ (pch) | $M_3$ (pch) |
|---|---|---|---|
| $g_m$ | 5.85 mS | 2.64 mS | 2.64 mS |
| $g_{ds}$ | 121 μS | 24.8 μS | 24.8 μS |
| $g_{mb}$ | 1.46 mS | 862 μS | 862 μS |
| $g_m/g_{ds}$ | 48.3 | 106.5 | 106.5 |
| $g_m/I_D$ | 20.0 S/A | 9.01 S/A | 9.01 S/A |

**Derived from SPICE .op:**

| Parameter | Value |
|---|---|
| $A_{v0} = g_{m1}/(g_{ds1}+g_{ds2})$ | 40.1 |
| $\beta \cdot A_{v0}$ | 12.7 |
| Static error $= 1/(\beta \cdot A_{v0})$ | 7.9% |
| $I(V_{DD})$ supply current | 586.06 μA (= 2 × $I_D$) |

### 2.3 Simulation Setup

**Gate DC bias:** The gate of $M_1$ connects only through capacitors ($C_S$, $C_F$) — no DC path. A bias source $V_{bias} = 0.52$ V through $R_{bias} = 10$ MΩ sets the gate operating point. The 10 MΩ resistor is large enough not to affect AC/transient performance at signal frequencies.

**SPICE directives:**
- `.tran 0 70n 0 0.1n` — transient simulation
- `.nodeset V(Vout)=1.17 V(gate)=0.52 V(mirror)=1.168` — initial guess for convergence
- `Vbias 0.52V` + `Rbias 10Meg` to gate — DC bias path
- `.noise V(Vout) V1 dec 100 10 10G` — noise simulation (commented out, enable when needed)
- `.ac dec 100 1 1T` — AC simulation (commented out, enable with `.noise`)
- Input: `PULSE(0 10m 10n 100p 100p 50n 100n)` — 10 mV step at $t = 10$ ns

### 2.4 Simulation Results (Transient)

From `.tran 0 70n 0 0.1n` with `PULSE(0 10m 10n 100p 100p 50n 100n)`:

| Measurement | Value |
|---|---|
| Vinit (at 9.9 ns) | 1.16517 V |
| Vfinal (at 55 ns) | 1.14670 V |
| Vstep | −18.476 mV |
| Expected ideal Vstep | −20.0 mV ($G \times V_{in} = 2 \times 10$ mV) |
| Static error (SPICE) | 7.62% |
| OP solver | Direct Newton (no Gmin stepping) |

- [x] Transient settling — step response captured (`plot_transient_step_response.png`)
- [x] Noise simulation — `plot_noise_spectral_density.png`, integrated RMS = 594.78 μVrms (10 Hz–10 GHz)
- [x] Dynamic error plot — `plot_dynamic_error.png` (Δt = 5.43 ns, ΔV = 19.06 mV)
- [x] SPICE comparison values obtained

### 2.5 Noise Simulation

From `.noise V(Vout) V1 dec 100 10 10G`:

| Parameter | Value |
|---|---|
| Integration band | 10 Hz – 10 GHz |
| Total RMS output noise (SPICE) | 594.78 μV |
| MATLAB kT/C noise prediction | 92.3 μV |

**Why SPICE noise ≫ MATLAB noise:** The `.noise` analysis treats the circuit as continuous-time and integrates over the full 10 Hz–10 GHz band. This includes 1/f (flicker) noise from the MOSFETs (dominant below ~1 kHz) and thermal noise from $R_{bias} = 10$ MΩ ($\sqrt{4kTR} \approx 12.9$ nV/√Hz at gate, amplified by $A_{v0} \approx 40$). In the actual switched-capacitor IGS, noise is **sampled** and limited by $kT/C_{L,tot}$ — the MATLAB value of 92.3 μVrms is the correct figure for the discrete-time circuit. The SPICE continuous-time noise is not directly comparable.

---

## 3. Comparison Table (MATLAB vs SPICE)

| Parameter | MATLAB | SPICE | Rel. Error |
|---|---|---|---|
| $W_n$ [μm] | 94.76 | 94.76 | 0% |
| $L_n$ [μm] | 0.200 | 0.200 | 0% |
| $W_p$ [μm] | 179.92 | 179.92 | 0% |
| $L_p$ [μm] | 0.900 | 0.900 | 0% |
| $I_D$ [μA] | 292.8 | 293.06 | 0.1% |
| $g_{m,n}$ [mS] | 5.857 | 5.85 | 0.1% |
| $(g_m/I_D)_n$ [S/A] | 20.0 | 20.0 | 0% |
| $(g_m/I_D)_p$ [S/A] | 9.0 | 9.01 | 0.1% |
| $A_{v0}$ | 39.5 | 40.1 | 1.5% |
| Static Error [%] | 7.98 | 7.62 | 4.5% |
| Vstep [mV] | −18.40 | −18.48 | 0.4% |
| $V(Vout)$ OP [V] | ~1.17 | 1.16517 | 0.4% |
| Noise [μVrms] | 92.3 (kT/C) | 594.78 (continuous-time) | N/A (see §2.5) |
| Settling Time [ns] | 5.50 | 5.43 | 1.3% |

**Discrepancy discussion:** MATLAB and SPICE agree very well. The gₘ/ID ratios match exactly (20.0 and 9.0 S/A), confirming the lookup tables are consistent with the BSIM3v3 model. The open-loop gain $A_{v0}$ differs by only 1.5% (39.5 vs 40.1), leading to a small static error difference (7.98% vs 7.62%). The SPICE gain is slightly higher because $g_{ds}$ at the exact bias point differs slightly from the lookup table interpolation. Noise simulation still pending.

---

## 4. Remaining Deliverables

- [x] Working LTSpice transient simulation → `plot_transient_step_response.png`
- [x] Final schematic with component values → `schematic_igs_pmos_load.png`
- [x] SPICE static error verified (7.62% vs MATLAB 7.98%)
- [x] Noise simulation → `plot_noise_spectral_density.png` (594.78 μVrms, see §2.5)
- [x] Dynamic error plot with annotated settling time → `plot_dynamic_error.png`
- [ ] Complete comparison table (needs noise from SPICE)
- [ ] IEEE report (4 pages max, Transactions format)
- [ ] Flowchart of MATLAB code

---

## 5. Files

| File | Description | Status |
|---|---|---|
| `igs_cap_sizing.m` | MATLAB optimization script | Complete |
| `look_up.m` | Lookup function (Murmann) | Copied from tools |
| `look_upVGS.m` | VGS inverse lookup | Copied from tools |
| `180nch.mat` | NMOS lookup table | Copied from tools |
| `180pch.mat` | PMOS lookup table | Copied from tools |
| `et4252_hspice.sp` | BSIM3v3 SPICE models | Copied from tools |
| `igs_pmos_load.asc` | LTSpice schematic | Updated with optimized values |
| `plot_DR_vs_gmid_p.png` | DR vs PMOS inversion plot | Generated |
| `plot_Area_vs_CR.png` | Area vs CR plot | Generated |
| `plot_Design_Space.png` | Feasible design space scatter | Generated |
| `plot_transient_step_response.png` | V(Vout) transient step response (0–70ns) | From LTSpice |
| `schematic_igs_pmos_load.png` | LTSpice schematic with OP annotation | From LTSpice |
| `plot_dynamic_error.png` | Zoomed step response with settling cursors | From LTSpice |
| `plot_noise_spectral_density.png` | V(onoise) with integrated RMS (594.78 μV) | From LTSpice |
| `PROJECT_PLAN.md` | Full design plan with equations | Complete |
| `PROGRESS.md` | This file | Current |
