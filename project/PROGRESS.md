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

### 2.2 DC Operating Point (from LTSpice test netlist)

Found by sweeping gate voltage with fixed bias in `igs_test.cir`:

| Node | Voltage |
|---|---|
| $V(Vout)$ | 1.17 V |
| $V(gate)$ | 0.52 V |
| $V(mirror)$ | 1.168 V |
| $V_{DD}$ | 1.8 V |

| Transistor | $I_D$ | $V_{GS}$ | $V_{DS}$ | $V_{th}$ | Region |
|---|---|---|---|---|---|
| $M_1$ (nch) | 293 μA | 0.52 V | 1.17 V | 0.488 V | Saturation |
| $M_2$ (pch) | −293 μA | −0.632 V | −0.635 V | −0.415 V | Saturation |
| $M_3$ (pch) | −293 μA | −0.632 V | −0.632 V | −0.415 V | Saturation (diode) |

### 2.3 Simulation Setup

**Gate bias issue:** The gate of $M_1$ connects only through capacitors ($C_S$, $C_F$) — no DC path. For simulation, a bias voltage source ($V_{bias} = 0.52$ V) is connected through a 1 GΩ resistor to the gate. This provides the DC operating point without affecting AC performance (1 GΩ is $>10^5\times$ larger than $C_F$ impedance at signal frequencies).

**SPICE directives:**
- `.tran 0 70n 0 0.1n` — transient simulation
- `.nodeset V(Vout)=1.17 V(gate)=0.52 V(mirror)=1.168` — helps .op convergence
- `Vbias nbias 0 0.52` + `Rbias nbias gate 1G` — gate DC bias
- `.noise V(Vout) V1 dec 100 10 10G` — noise simulation (commented, enable when needed)
- Input: `PULSE(0 10m 10n 100p 100p 50n 100n)` — 10 mV step at $t = 10$ ns

### 2.4 Simulations Still Needed

- [ ] Transient settling — verify settling time $\leq 5.5$ ns
- [ ] Dynamic error plot — annotate settling time at 0.1%
- [ ] Noise simulation — verify integrated noise $\leq 100$ μVrms
- [ ] Fill SPICE column in comparison table

---

## 3. Comparison Table (MATLAB vs SPICE)

| Parameter | MATLAB | SPICE | Error (%) |
|---|---|---|---|
| $W_n$ [μm] | 94.76 | — | — |
| $L_n$ [μm] | 0.200 | — | — |
| $W_p$ [μm] | 179.92 | — | — |
| $L_p$ [μm] | 0.900 | — | — |
| Total Area [μm²] | 180.9 | — | — |
| $CR$ | 0.05 | — | — |
| $DR$ [dB] | 75.1 | — | — |
| $(g_m/I_D)_n$ [S/A] | 20.0 | — | — |
| $(g_m/I_D)_p$ [S/A] | 9.0 | — | — |
| Noise [μVrms] | 92.3 | — | — |
| Settling Time [ns] | 5.50 | — | — |
| Static Error [%] | 7.98 | — | — |
| $I_D$ [μA] | 292.8 | — | — |

SPICE column to be filled after successful transient and noise simulations.

---

## 4. Remaining Deliverables

- [ ] Working LTSpice transient simulation → settling transient plot
- [ ] Dynamic error plot with annotated settling time
- [ ] Noise simulation → running noise integral plot
- [ ] Complete comparison table (MATLAB vs SPICE)
- [ ] IEEE report (4 pages max, Transactions format)
- [ ] Flowchart of MATLAB code
- [ ] Final schematic with component values

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
| `igs_test.cir` | Test netlist for finding DC bias | Complete |
| `plot_DR_vs_gmid_p.png` | DR vs PMOS inversion plot | Generated |
| `plot_Area_vs_CR.png` | Area vs CR plot | Generated |
| `plot_Design_Space.png` | Feasible design space scatter | Generated |
| `PROJECT_PLAN.md` | Full design plan with equations | Complete |
| `PROGRESS.md` | This file | Current |
