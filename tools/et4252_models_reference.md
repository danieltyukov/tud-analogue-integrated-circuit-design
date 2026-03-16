# ET4252 HSPICE Model Reference — `et4252_hspice.sp`

**Source:** Boris Murmann, EE214B, December 2016 (updated MOSflicker noise to noimod=6)

This file is included in simulations via `.include "et4252_hspice.sp"` and provides all device models for the ET4252 course.

---

## Models Overview

| Model | Type | Description |
|-------|------|-------------|
| `nch` | NMOS (BSIM3v3) | 180nm NMOS, nominal process |
| `pch` | PMOS (BSIM3v3) | 180nm PMOS, nominal process |
| `npn214` | NPN BJT | SiGe npn, emitter area = 0.7 μm² |
| `npnideal` | NPN BJT | Idealized npn (I_S = 0.032 fA, β = 300) |
| `pnpideal` | PNP BJT | Idealized pnp (I_S = 0.032 fA, β = 300) |
| `dwell` | Diode | Well-to-substrate junction (for PMOS n-well) |
| `balun` | Subcircuit | Ideal balun for differential ↔ single-ended conversion |

---

## NMOS (`nch`) — Key Parameters

BSIM3v3 (LEVEL=49), ~100 parameters. The most relevant ones grouped by category:

### Basic

| Parameter | Value | Description |
|-----------|-------|-------------|
| `LEVEL` | 49 | BSIM3v3 model |
| `VERSION` | 3.3 | BSIM3 version |
| `TNOM` | 27 °C | Nominal temperature |
| `TOX` | 4.1 nm | Gate oxide thickness |
| `VTH0` | 0.3618 V | Long-channel threshold voltage |
| `NCH` | 2.3549×10¹⁷ cm⁻³ | Channel doping concentration |
| `XJ` | 100 nm | Junction depth |

### Mobility & Transport

| Parameter | Value | Description |
|-----------|-------|-------------|
| `U0` | 256.74 cm²/Vs | Low-field mobility |
| `UA` | −1.586×10⁻⁹ | First-order mobility degradation coefficient |
| `UB` | 2.528×10⁻¹⁸ | Second-order mobility degradation coefficient |
| `UC` | 5.182×10⁻¹¹ | Body-bias mobility degradation |
| `VSAT` | 1.003×10⁵ cm/s | Saturation velocity |

### Threshold Voltage Modifiers

| Parameter | Value | Description |
|-----------|-------|-------------|
| `K1` | 0.5916 | First-order body effect coefficient |
| `K2` | 3.225×10⁻³ | Second-order body effect coefficient |
| `DVT0` | 1.313 | Short-channel threshold voltage shift |
| `DVT1` | 0.388 | SCE coefficient |
| `DVT2` | 0.024 | SCE body-bias coefficient |
| `PVTH0` | −7.714×10⁻⁴ | VTH0 length dependence |

### Output Conductance (CLM, DIBL, SCBE)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `PCLM` | 0.7246 | Channel length modulation |
| `PDIBLC1` | 0.1568 | DIBL coefficient 1 |
| `PDIBLC2` | 2.543×10⁻³ | DIBL coefficient 2 |
| `ETA0` | 2.981×10⁻³ | DIBL parameter |
| `PSCBE1` | 8×10¹⁰ | Substrate current body effect 1 |
| `PSCBE2` | 1.876×10⁻⁹ | Substrate current body effect 2 |
| `DROUT` | 0.7445 | DIBL Rout parameter |

### Geometry Corrections

| Parameter | Value | Description |
|-----------|-------|-------------|
| `LINT` | 16.17 nm | Length offset (effective L = drawn L − 2×LINT) |
| `WINT` | 0 | Width offset |
| `DWG` | −5.383×10⁻⁹ | Width offset gate-voltage dependence |
| `DWB` | 9.112×10⁻⁹ | Width offset body-bias dependence |

### Subthreshold

| Parameter | Value | Description |
|-----------|-------|-------------|
| `VOFF` | −0.0855 V | Subthreshold offset voltage |
| `NFACTOR` | 2.242 | Subthreshold swing factor |

### Capacitances

| Parameter | Value | Description |
|-----------|-------|-------------|
| `CGDO` | 0.491 fF/μm | Gate-drain overlap capacitance per width |
| `CGSO` | 0.491 fF/μm | Gate-source overlap capacitance per width |
| `CJ` | 965.2 aF/μm² | Bottom junction capacitance (zero-bias) |
| `CJSW` | 0.2326 fF/μm | Sidewall junction capacitance |
| `PB` | 0.8 V | Junction built-in potential |
| `MJ` | 0.384 | Junction grading coefficient |

### Noise

| Parameter | Value | Description |
|-----------|-------|-------------|
| `noimod` | 6 | Flicker noise model (HSPICE-style) |
| `noia` | 10¹⁹ | Flicker noise parameter A |
| `noib` | 3×10⁴ | Flicker noise parameter B |
| `noic` | 10⁻¹³ | Flicker noise parameter C |

### Parasitic Resistance

| Parameter | Value | Description |
|-----------|-------|-------------|
| `RDSW` | 0 | Source/drain resistance per width |
| `RSH` | 0 Ω/sq | Sheet resistance |

---

## PMOS (`pch`) — Key Differences from NMOS

| Parameter | NMOS (`nch`) | PMOS (`pch`) |
|-----------|-------------|-------------|
| `VTH0` | +0.362 V | −0.375 V |
| `U0` | 256.7 cm²/Vs | 103.6 cm²/Vs |
| `VSAT` | 1.003×10⁵ cm/s | 1.291×10⁵ cm/s |
| `RDSW` | 0 | 293.8 Ω·μm |
| `RSH` | 0 | 7.5 Ω/sq |
| `CGDO` | 0.491 fF/μm | 0.657 fF/μm |
| `CGSO` | 0.491 fF/μm | 0.657 fF/μm |
| `LINT` | 16.2 nm | 31.1 nm |

PMOS has ~2.5× lower mobility than NMOS and non-zero parasitic resistance.

---

## SiGe NPN BJT (`npn214`)

Gummel-Poon model (LEVEL=1), emitter area = 0.7 μm².

| Parameter | Value | Description |
|-----------|-------|-------------|
| `is` | 0.032 fA | Saturation current |
| `bf` | 300 | Forward current gain (β) |
| `br` | 2 | Reverse current gain |
| `vaf` | 90 V | Forward Early voltage |
| `rb` | 25 Ω | Base resistance |
| `re` | 2.5 Ω | Emitter resistance |
| `rc` | 60 Ω | Collector resistance |
| `tf` | 563 fs | Forward transit time |
| `cje` | 6.26 fF | B-E junction capacitance |
| `cjc` | 3.42 fF | B-C junction capacitance |

---

## Ideal BJTs (`npnideal`, `pnpideal`)

Minimal models with only `is = 0.032 fA` and `bf = 300`. No parasitic resistances, no Early effect, no capacitances. Used for conceptual/ideal circuit analysis.

---

## Well Diode (`dwell`)

Models the n-well to p-substrate junction (relevant for PMOS body connection).

| Parameter | Value | Description |
|-----------|-------|-------------|
| `cj0` | 200 fF/μm² | Zero-bias junction capacitance |
| `is` | 10 μA | Saturation current |
| `m` | 0.5 | Grading coefficient |
| `pb` | 0.8 V | Built-in potential |

**Instantiation:** `d1 sub_node well_node dwell 100p` (area in m², e.g. 100p = 10μm × 10μm)

---

## Balun Subcircuit

Ideal differential ↔ single-ended converter using two VCVS sources with gain of 2.

**Instantiation:** `x1 vdm vcm vp vm balun`

- `vdm` — differential mode voltage
- `vcm` — common mode voltage
- `vp`, `vm` — positive/negative single-ended outputs

---

## LTSpice Compatibility Notes

When using this file in LTSpice (via `.include`), the following warnings are expected and harmless:

| Warning | Reason |
|---------|--------|
| `Ignoring BSIM parameter ACM` | HSPICE area calculation method, not used by LTSpice |
| `Ignoring BSIM parameter HDIF` | HSPICE half-diffusion length |
| `Ignoring BSIM parameter XL` | HSPICE channel length offset |
| `Ignoring BSIM parameter XW` | HSPICE channel width offset |
| `Unrecognized parameter "cjgate"` | HSPICE gate-edge junction cap, ignored |
| `Pd = 0 is less than W` | No drain/source perimeter specified; set `ad`, `as`, `pd`, `ps` on the instance for accurate junction caps |

These do not affect DC or small-signal accuracy.
