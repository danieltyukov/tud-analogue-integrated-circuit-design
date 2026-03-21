# IGS with Active PMOS Load — Project Plan

**Course:** ET4252 Analogue Integrated Circuit Design, TU Delft
**Authors:** Daniel Tyukov (5714699) & Raghavendra Joshi (6438180)
**Technology:** 180nm CMOS (BSIM3v3 Level 49)

---

## 1. Problem Statement

Design an Intrinsic Gain Stage (IGS) with capacitive feedback, replacing the ideal current source with an **active PMOS load** ($M_2$), and optimize for:

1. **Minimum total area** ($M_1 + M_2$) under a drain current budget of $I_D \leq 500\,\mu A$
2. **Maximum dynamic range** $DR = P_{out} / P_{n,out}$ via $g_{mp}/g_{mn}$ optimization
3. Meet all hard specs (settling, noise, static error)

### 1.1 Hard Specifications

| Specification | Target |
|---|---|
| Static Error $\varepsilon_s$ [%] | $\leq 8$ |
| Settling Time $t_s$ [ns] (@ $0.1\%\,\varepsilon_d$) | $\leq 5.5$ |
| Max Drain Current $I_D$ [$\mu$A] | $\leq 500$ |
| Total integrated output noise [$\mu$Vrms] (10 Hz – 10 GHz) | $\leq 100$ |
| Closed-loop gain $G = C_S / C_{F,tot}$ | $2$ |
| Fan-out $FO = C_L / C_S$ | $1$ |

### 1.2 Optimization Objectives (Soft Specs)

| Objective | Priority | Rationale |
|---|---|---|
| Minimize Area ($M_1 + M_2$) | High | Directly graded, cost in silicon |
| Maximize $DR$ | High | Directly graded, system-level performance |
| Minimize $I_D$ | Medium | Stay well under $500\,\mu A$ budget |
| MATLAB vs SPICE $\leq 10\%$ | High | Validates methodology, 30% of grade |

---

## 2. Circuit Architecture

```
         VDD
          │
     ┌────┤
     │  ┌─┴─┐
     │  │ M3 │  (diode-connected PMOS, bias mirror)
     │  └─┬─┘
     │    │←── I_bias (ideal current source)
     │    │
     │  ┌─┴─┐
     │  │ M2 │  (PMOS active load)
     │  └─┬─┘
     │    ├──────────┬──── V_out ────┬── C_L ── GND
     │    │     ┌────┴────┐         │
     │    │     │   C_F   │         │
     │    │     └────┬────┘         │
     │    │          │              │
     │  ┌─┴──────────┴─┐            │
     │  │     M1       │            │
     │  │   (NMOS)     │            │
     │  └──────┬───────┘            │
     │         │                    │
     │    V_in ┤                    │
     │         │                    │
     │    C_S ─┘                    │
     │                              │
    GND                            GND
```

**Key differences from starter code:**

- Ideal current source replaced by PMOS active load $M_2$
- Must size both $M_1$ (NMOS) and $M_2$ (PMOS)
- $M_2$ contributes noise, increasing noise factor $\alpha$
- $M_2$ adds output capacitance $C_{db,p}$, increasing self-loading
- $M_3$ (diode-connected PMOS) mirrors bias current to $M_2$

---

## 3. Theory & Key Equations

### 3.1 Feedback Network Analysis

**Feedback factor:**

$$\beta = \frac{C_{F,tot}}{C_{F,tot} + C_S + C_{gs}}$$

where $C_{F,tot} = C_F + C_{gd}$ (physical feedback cap + gate-drain overlap).

**Capacitance ratio:**

$$CR = \frac{C_{gs}}{C_S + C_{F,tot}}$$

Expressing $\beta$ in terms of $G$ and $CR$:

$$\beta = \frac{1}{(1+G)(1+CR)}$$

### 3.2 Noise with Active PMOS Load

**Noise factor (replacing ideal current source):**

$$\alpha = \gamma_n \left(1 + \frac{\gamma_p \cdot g_{mp}}{\gamma_n \cdot g_{mn}}\right)$$

For 180nm: $\gamma_n \approx 2/3$ (strong inversion), $\gamma_n \approx n/2 \approx 0.73$ (weak inversion). $\gamma_p$ is similar.

Since $I_D$ is the same through both devices:

$$\frac{g_{mp}}{g_{mn}} = \frac{(g_m/I_D)_p}{(g_m/I_D)_n}$$

**Total integrated output noise:**

$$\overline{v_{n,out}^2} = \frac{\alpha}{\beta} \cdot \frac{kT}{C_{L,tot}}$$

**Noise optimization insight:** Want $g_{mp}/g_{mn}$ small, so push PMOS to stronger inversion (lower $(g_m/I_D)_p$). But this increases $V_{Dsat,p}$, reducing output swing — a DR tradeoff.

### 3.3 Dynamic Range

$$DR = \frac{P_{out}}{P_{n,out}} = \frac{V_{out,max}^2 / 2}{\alpha / \beta \cdot kT / C_{L,tot}}$$

For sinusoidal output with amplitude $V_{out,max}$:

$$V_{out,max} \approx V_{DD} - V_{Dsat,p} - V_{Dsat,n}$$

where $V_{Dsat} \approx 2/(g_m/I_D)$.

**Maximizing $DR$ requires:**

1. Large $C_{L,tot}$ (reduces noise floor — but costs area and current)
2. Small $\alpha$ (minimize $g_{mp}/g_{mn}$ ratio)
3. Large output swing (moderate $V_{Dsat}$ for both devices)
4. The optimum $g_{mp}/g_{mn}$ balances noise reduction vs. swing loss

### 3.4 Static Error

With a PMOS active load, the effective output resistance becomes:

$$r_{out} = \frac{1}{g_{ds,n} + g_{ds,p}}$$

Effective voltage gain:

$$A_{v0} = \frac{g_{mn}}{g_{ds,n} + g_{ds,p}}$$

Rewritten using lookup ratios:

$$A_{v0} = \frac{1}{\dfrac{1}{(g_m/g_{ds})_n} + \dfrac{(g_m/I_D)_p}{(g_m/I_D)_n} \cdot \dfrac{1}{(g_m/g_{ds})_p}}$$

**Static error constraint:** $\varepsilon_s = 1/(\beta \cdot A_{v0}) \leq 8\%$, therefore:

$$\beta \cdot A_{v0} \geq 12.5$$

### 3.5 Settling Time with Self-Loading

$$\tau = \frac{C_{L,tot}}{\beta \cdot g_m}$$

where:

$$C_{L,tot} = C_L + C_{db,n} + C_{db,p} + (1-\beta) \cdot C_{F,tot}$$

$$t_s = \tau \cdot \ln\!\left(\frac{1}{\varepsilon_d}\right) = \tau \cdot \ln(1000) = 6.908\,\tau \quad \text{(for } 0.1\% \text{ error)}$$

Self-loading from PMOS adds $C_{db,p}$, increasing $\tau$ — must be accounted for via iteration.

### 3.6 Area

$$\text{Area} = W_n \cdot L_n + W_p \cdot L_p$$

Width is set by $W = I_D / J_D$, where $J_D = I_D/W$ is looked up at the chosen $g_m/I_D$ and $L$.

---

## 4. Design Strategy — Senior Analog Designer Approach

### 4.1 Outer Optimization Loop (Sweep Design Space)

The key insight is that **three free variables** control the design:

1. $(g_m/I_D)_n$ — NMOS inversion level (affects speed, noise, area)
2. $(g_m/I_D)_p$ — PMOS inversion level (affects noise, swing, area)
3. $CR$ — Capacitance ratio (affects $\beta$, bandwidth, noise)

$L_n$ is constrained by the static error requirement (need sufficient $g_m/g_{ds}$). $L_p$ is a secondary optimization variable (longer $L_p$ gives higher $g_m/g_{ds}$ for PMOS, but more area).

### 4.2 Design Flow (Per Iteration)

```
┌─────────────────────────────────────────────────────┐
│  FOR each (gm/ID)_n in sweep range [5 ... 20]      │
│    FOR each (gm/ID)_p in sweep range [3 ... 15]    │
│      FOR each CR in sweep range [0.1 ... 0.5]      │
│                                                     │
│  ┌─ STEP 1: Determine L_n ───────────────────────┐  │
│  │  Look up gm/gds vs L at chosen (gm/ID)_n     │  │
│  │  Find minimum L_n satisfying static error     │  │
│  │  (also account for gds_p contribution)        │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 2: Determine L_p ───────────────────────┐  │
│  │  Want gm_p/gds_p high to not degrade gain     │  │
│  │  Sweep L_p or pick L_p = L_n as starting pt   │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 3: Compute beta and capacitances ───────┐  │
│  │  beta = 1/((1+G)(1+CR))                       │  │
│  │  Compute alpha from (gm/ID)_n, (gm/ID)_p     │  │
│  │  C_Ltot = (alpha/beta) * kT / Noise^2         │  │
│  │  C_Ftot, C_S, C_L, C_gs from ratios           │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 4: Compute gm and size M1 (NMOS) ──────┐  │
│  │  wu = ln(1/ed) / ts                            │  │
│  │  gm_n = C_Ltot * wu / beta                     │  │
│  │  I_D = gm_n / (gm/ID)_n                       │  │
│  │  Check: I_D <= 500 uA?                         │  │
│  │  W_n = I_D / look_up(nch, 'ID_W', ...)        │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 5: Size M2 (PMOS) ─────────────────────┐  │
│  │  Same I_D flows through M2                    │  │
│  │  W_p = I_D / look_up(pch, 'ID_W', ...)       │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 6: Self-loading iteration ──────────────┐  │
│  │  Extract C_gd, C_db from both nch and pch     │  │
│  │  C_Ltot_actual = C_L + C_db,n + C_db,p       │  │
│  │                  + (1-beta) * C_Ftot           │  │
│  │  Recompute gm, I_D, W with updated C_Ltot    │  │
│  │  Iterate until convergence (1-2 rounds)       │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─ STEP 7: Verify all specs ────────────────────┐  │
│  │  Check ts <= 5.5 ns, eps_s <= 8%              │  │
│  │  Check noise <= 100 uVrms, I_D <= 500 uA     │  │
│  │  Compute Area = W_n*L_n + W_p*L_p             │  │
│  │  Compute DR                                   │  │
│  │  Store if all specs met                       │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│      END FOR (CR)                                   │
│    END FOR ((gm/ID)_p)                              │
│  END FOR ((gm/ID)_n)                                │
│                                                     │
│  Select design point: min Area with max DR          │
│  among all feasible solutions                       │
└─────────────────────────────────────────────────────┘
```

### 4.3 Design Insight: Where to Operate Each Transistor

**$M_1$ (NMOS, input device):**

- Moderate inversion ($(g_m/I_D)_n \approx 10$–$15\,\text{S/A}$) is typically optimal
- Balances the $(g_m/I_D) \cdot f_T$ product (speed-power FOM)
- $(g_m/I_D)_n$ too high: huge device, slow ($f_T$ drops), but low current
- $(g_m/I_D)_n$ too low: small device, fast, but high current and low gain

**$M_2$ (PMOS, active load):**

- Stronger inversion ($(g_m/I_D)_p \approx 5$–$10\,\text{S/A}$) preferred for noise
- Lower $g_{mp}/g_{mn}$ ratio gives lower $\alpha$ and less noise
- But stronger inversion gives larger $V_{Dsat,p}$, reducing output swing
- PMOS has $\sim 2.5\times$ lower mobility, so for same $g_m/I_D$ the PMOS is $\sim 2.5\times$ wider

**$M_3$ (PMOS, diode-connected mirror):**

- Same $L_p$ and $(g_m/I_D)_p$ as $M_2$ for accurate current mirroring
- Size $W_{M3} = W_{M2}$ for 1:1 mirror ratio
- $M_3$ area is NOT counted in the optimization target

---

## 5. Detailed MATLAB Implementation Plan

### 5.1 Required Files (in `project/` folder)

| File | Source | Purpose |
|---|---|---|
| `180nch.mat` | `tools/` | NMOS 4D lookup table |
| `180pch.mat` | `tools/` | PMOS 4D lookup table |
| `look_up.m` | `tools/` | Core lookup function (3 modes) |
| `look_upVGS.m` | `tools/` | VGS inverse lookup |
| `igs_cap_sizing.m` | `project/` | Starter code, to be extended |
| `et4252_hspice.sp` | `tools/` | SPICE models for LTSpice netlists |

### 5.2 MATLAB Script Structure

```matlab
%% igs_cap_sizing.m — Extended for PMOS active load optimization
%
% LOOP 1 (gm/ID loop): Sweep (gm/ID)_n, (gm/ID)_p, CR
% LOOP 2 (sizing loop): Self-loading iteration per design point
% OUTPUT: Optimal W_n, L_n, W_p, L_p, all capacitances, performance

% 1. Load both NMOS and PMOS lookup tables
% 2. Define specs (ts, ed, Noise, G, FO)
% 3. Define sweep ranges for (gm/ID)_n, (gm/ID)_p, CR
% 4. Nested loops with:
%    a. L_n selection from gain requirement
%    b. L_p selection (sweep or heuristic)
%    c. Capacitance sizing from noise spec
%    d. gm and transistor sizing
%    e. Self-loading iteration (inner while loop)
%    f. Spec checking and storage
% 5. Pareto-optimal selection (min area, max DR)
% 6. Print final design table
% 7. Generate optimization plots
```

### 5.3 Key Lookup Calls Needed

```matlab
% NMOS lookups
gm_gds_n = look_up(nch, 'GM_GDS', 'GM_ID', gmid_n, 'L', nch.L);
JD_n     = look_up(nch, 'ID_W',   'GM_ID', gmid_n, 'L', L_n);
CGD_W_n  = look_up(nch, 'CGD_W',  'GM_ID', gmid_n, 'L', L_n, 'VDS', VDS_n);
CDD_W_n  = look_up(nch, 'CDD_W',  'GM_ID', gmid_n, 'L', L_n, 'VDS', VDS_n);

% PMOS lookups
gm_gds_p = look_up(pch, 'GM_GDS', 'GM_ID', gmid_p, 'L', pch.L);
JD_p     = look_up(pch, 'ID_W',   'GM_ID', gmid_p, 'L', L_p);
CGD_W_p  = look_up(pch, 'CGD_W',  'GM_ID', gmid_p, 'L', L_p, 'VDS', VDS_p);
CDD_W_p  = look_up(pch, 'CDD_W',  'GM_ID', gmid_p, 'L', L_p, 'VDS', VDS_p);
```

### 5.4 Noise Factor Computation

```matlab
gamma_n = 2/3;
gamma_p = 2/3;

% gm_p/gm_n = (gm/ID)_p / (gm/ID)_n  (same I_D)
gm_ratio = gmid_p / gmid_n;

% alpha = gamma_n + gamma_p * gm_ratio
alpha = gamma_n * (1 + (gamma_p * gm_ratio) / gamma_n);
```

### 5.5 Static Error with PMOS Load

```matlab
gm_gds_n_val = look_up(nch, 'GM_GDS', 'GM_ID', gmid_n, 'L', L_n);
gm_gds_p_val = look_up(pch, 'GM_GDS', 'GM_ID', gmid_p, 'L', L_p);

% A_v0 = 1 / (1/gm_gds_n + gm_ratio/gm_gds_p)
A_v0 = 1 / (1/gm_gds_n_val + gm_ratio/gm_gds_p_val);

% eps_s = 1 / (beta * A_v0), must be <= 0.08
eps_s = 1 / (beta * A_v0);
```

### 5.6 Dynamic Range Computation

```matlab
VDD = 1.8;
Vdsat_n = 2 / gmid_n;
Vdsat_p = 2 / gmid_p;
Vswing = VDD - Vdsat_n - Vdsat_p;
Vamp = Vswing / 2;

P_out = Vamp^2 / 2;
P_noise = (alpha / beta) * (kB * T / CLtot);

DR = P_out / P_noise;
DR_dB = 10 * log10(DR);
```

---

## 6. LTSpice Simulation Plan

### 6.1 Required Simulations

| Simulation | Type | Purpose |
|---|---|---|
| DC Operating Point | `.op` | Verify bias, check saturation |
| Transient | `.tran` | Settling transient, dynamic error |
| AC Noise | `.noise` | Integrated output noise vs frequency |

### 6.2 LTSpice Netlist Structure

```spice
* IGS with PMOS active load — ET4252 Project
.include et4252_hspice.sp

* Supply
VDD vdd 0 1.8

* Input step
Vin vin_ac 0 PULSE(0 10m 1n 0.1n 0.1n 20n 40n)

* Feedback network
CS vin_ac gate {CS_value}
CF out gate {CF_value}
CL out 0 {CL_value}

* NMOS (M1)
M1 out gate 0 0 nch W={Wn} L={Ln}

* PMOS active load (M2)
M2 out bias vdd vdd pch W={Wp} L={Lp}

* PMOS mirror (M3, diode-connected)
M3 bias bias vdd vdd pch W={Wp} L={Lp}
Ibias bias 0 {ID_value}

* Analysis
.op
.tran 0 20n 0 0.01n
.noise V(out) Vin_ac 1000 10 10G
```

### 6.3 What to Verify in LTSpice

1. **All transistors in saturation:** $V_{DS} > V_{Dsat}$ for each device
2. **Settling transient:** Plot $V_{out}$ vs time, annotate final value
3. **Dynamic error:** $|V_{out}(t) - V_{out,\infty}| / |V_{out,\infty}|$ on log scale, find $t$ where it crosses $0.1\%$
4. **Output noise:** Running integral $\sqrt{\int S_{out}\,df}$ from $10\,\text{Hz}$ to $10\,\text{GHz}$, annotate final $\mu\text{Vrms}$
5. **Match MATLAB values within $\sim 10\%$** for settling time, static error, noise

### 6.4 Fine-Tuning in LTSpice

After initial MATLAB sizing:

- Adjust $V_{DS}$ operating points (may differ from lookup default)
- Tweak $W$ slightly to hit exact specs
- Verify that bias point is stable ($M_3$ mirror works correctly)

---

## 7. Key Design Tradeoffs to Discuss in Report

### 7.1 Selection of $(g_m/I_D)_n$

- Higher: more efficient, lower current, but slower (lower $f_T$) and larger device
- Lower: faster, smaller, but wastes current
- Sweet spot: where $(g_m/I_D) \cdot f_T$ peaks (moderate inversion, $(g_m/I_D) \approx 10$–$15$)

### 7.2 Selection of $(g_m/I_D)_p$ and DR Optimization

- Want low $g_{mp}/g_{mn}$, so push PMOS to strong inversion (low $(g_m/I_D)_p$)
- But strong inversion PMOS gives large $V_{Dsat,p}$, reduced output swing, and DR drops
- There is a **shallow optimum** in $(g_m/I_D)_p$ that maximizes $DR$
- This is a key result to present with a plot

### 7.3 Selection of $CR$

- $CR = 1/3$ is the square-law optimum for long channels
- For short channels, optimum shifts to smaller $CR$ (saves area)
- Smaller $CR$ gives larger $\beta$, better noise and bandwidth, but needs more current
- The optimum is shallow — plot Area vs $CR$ to show this

### 7.4 Channel Length Selection

- $L_n$: minimum $L$ that gives sufficient gain for static error spec
- Longer $L$ gives higher $g_m/g_{ds}$ and lower static error, but slower ($f_T$ lower) and more area
- $L_p$: longer $L_p$ gives higher $g_{mp}/g_{ds,p}$ which helps overall gain, but adds area
- RSCE effect: $V_t$ vs $L$ is non-monotonic in 180nm — check with lookup tables

### 7.5 MATLAB vs SPICE Discrepancies

Expected sources of error:

- Lookup table $V_{DS}$ default vs actual circuit $V_{DS}$
- Large-signal vs small-signal behavior during settling
- Finite mirror accuracy ($M_3$ vs $M_2$ mismatch if $W$ differs)
- Parasitic capacitances not fully captured in 1st-order model
- Gate leakage (negligible at 180nm)

---

## 8. Deliverables Checklist

### 8.1 PDF Report (max 4 pages, IEEE Transactions format)

- [ ] Final design schematic (circuit diagram with component values)
- [ ] Optimization approach description with flowchart
- [ ] MATLAB vs SPICE comparison table:

| Parameter | MATLAB | SPICE | Error (%) |
|---|---|---|---|
| $W_n$ [$\mu$m] | | | |
| $L_n$ [$\mu$m] | | | |
| $W_p$ [$\mu$m] | | | |
| $L_p$ [$\mu$m] | | | |
| Total Area [$\mu\text{m}^2$] | | | |
| $CR$ | | | |
| $DR$ [dB] | | | |
| $(g_m/I_D)_n$ [S/A] | | | |
| $(g_m/I_D)_p$ [S/A] | | | |
| Total integrated noise [$\mu$Vrms] | | | |
| Settling Time [ns] | | | |
| Static Error [%] | | | |
| $I_D$ [$\mu$A] | | | |

- [ ] Required plots:
  1. Settling transient (annotated with final value)
  2. Dynamic error vs time (annotated with settling time)
  3. Running noise integral vs frequency (annotated $\mu\text{Vrms}$)
  4. Optimization plots ($DR$ vs $g_{mp}/g_{mn}$, Area vs $CR$, etc.)
- [ ] Discussion of MATLAB vs SPICE discrepancies

### 8.2 MATLAB Script

- [ ] Self-contained, error-free
- [ ] $g_m/I_D$ optimization loop (sweeps inversion levels)
- [ ] Sizing loop (self-loading iteration)
- [ ] Both NMOS and PMOS sizing
- [ ] Flowchart in report matching code structure

### 8.3 LTSpice Files

- [ ] Schematic with correct component values from MATLAB
- [ ] Transient simulation (`.tran`) — settling behavior
- [ ] Noise simulation (`.noise`) — integrated output noise
- [ ] Operating point verification (`.op`) — all devices in saturation
- [ ] SPICE model file (`et4252_hspice.sp`) included

---

## 9. Grading Alignment

| Rubric Item | Weight | Our Strategy |
|---|---|---|
| Design Specs met | 20% | Systematic sweep ensures all specs met; area + DR optimized |
| MATLAB $g_m/I_D$ loop | 20% | Nested sweep over $(g_m/I_D)_n$, $(g_m/I_D)_p$, $CR$ |
| MATLAB sizing loop | 20% | Self-loading iteration with convergence check |
| LTSpice Simulations | 10% | Fine-tuned $W/L$, all 3 sim types, annotated plots |
| Design Methodology | 30% | Physics-motivated choices, thorough comparison |

---

## 10. File Organization

```
project/
├── PROJECT_PLAN.md              ← This file
├── igs_cap_sizing.m             ← Main MATLAB design script (to be extended)
├── look_up.m                    ← Lookup function (copied from tools/)
├── look_upVGS.m                 ← VGS lookup (copied from tools/)
├── 180nch.mat                   ← NMOS lookup table (copied from tools/)
├── 180pch.mat                   ← PMOS lookup table (copied from tools/)
├── et4252_hspice.sp             ← SPICE models (copied from tools/)
├── test_lookup.m                ← Lookup test/examples (copied from tools/)
├── Gm_Id Project Instructions.pdf
├── gmid_slides_83-87.pdf
└── Alternate-Transactions-...doc  ← IEEE report template
```

---

## 11. Execution Timeline

| Step | Task | Status |
|---|---|---|
| 1 | Copy tools to project folder | Done |
| 2 | Extend MATLAB script with PMOS + optimization | Pending |
| 3 | Run MATLAB optimization, select design point | Pending |
| 4 | Build LTSpice netlist with MATLAB results | Pending |
| 5 | Run LTSpice simulations, extract results | Pending |
| 6 | Compare MATLAB vs SPICE, iterate if needed | Pending |
| 7 | Generate all plots (MATLAB + LTSpice) | Pending |
| 8 | Write IEEE report (4 pages max) | Pending |
| 9 | Final review, package deliverables | Pending |

---

## 12. Reference Equations Summary

$$\beta = \frac{1}{(1+G)(1+CR)}$$

$$\alpha = \gamma_n + \gamma_p \cdot \frac{(g_m/I_D)_p}{(g_m/I_D)_n}$$

$$C_{L,tot} = \frac{\alpha}{\beta} \cdot \frac{kT}{\text{Noise}^2}$$

$$C_{F,tot} = \frac{C_{L,tot}}{FO \cdot G + 1 - \beta}$$

$$C_S = G \cdot C_{F,tot}, \quad C_L = FO \cdot C_S, \quad C_{gs} = CR \cdot (C_S + C_{F,tot})$$

$$\omega_u = \frac{\ln(1/\varepsilon_d)}{t_s}$$

$$g_m = \frac{C_{L,tot} \cdot \omega_u}{\beta}$$

$$I_D = \frac{g_m}{(g_m/I_D)_n}$$

$$W_n = \frac{I_D}{J_{D,n}}, \quad W_p = \frac{I_D}{J_{D,p}}$$

$$A_{v0} = \frac{1}{\dfrac{1}{(g_m/g_{ds})_n} + \dfrac{(g_m/I_D)_p}{(g_m/I_D)_n} \cdot \dfrac{1}{(g_m/g_{ds})_p}}$$

$$\varepsilon_s = \frac{1}{\beta \cdot A_{v0}}$$

$$V_{Dsat} \approx \frac{2}{g_m/I_D}$$

$$V_{swing} = V_{DD} - V_{Dsat,n} - V_{Dsat,p}$$

$$DR = \frac{(V_{swing}/2)^2}{2 \cdot \dfrac{\alpha}{\beta} \cdot \dfrac{kT}{C_{L,tot}}}$$
