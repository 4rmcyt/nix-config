# MSI MAG B650 TOMAHAWK WIFI — BIOS Setup Recovery Checklist

Standard BIOS/UEFI setup-screen values for the `desktop` host, to be
re-entered by hand after a firmware update/reset wipes NVRAM (or when the
board's built-in profile backup is unavailable). For **hidden/suppressed**
`AmdSetupRPL` settings reachable only via `setup_var.efi`/UEFI shell, see
[`efi.md`](efi.md) instead — this doc covers only the settings visible in the
normal BIOS setup UI.

## Hardware summary

| Component | Model |
|---|---|
| Board | MSI MAG B650 TOMAHAWK WIFI (`E7D75AMS`), AM5 |
| CPU | AMD Ryzen 5 7600X (Zen 4) |
| RAM | Corsair Vengeance `CMK64GX5M2B5200C40` — 2×32GB DDR5, rated **5200 MT/s CL40**, EXPO-certified |
| GPU | NVIDIA RTX 3050 8GB (dGPU, primary) + AMD iGPU |
| Boot drive | Samsung 970 EVO Plus 1TB NVMe (GPT, EFI partition mounted at `/boot`) |
| Sensors | `nct6687` SuperIO hwmon; OS-level fan control via `corectrl` |

**Before starting:** check the current BIOS version against MSI's live
support page — https://www.msi.com/Motherboard/MAG-B650-TOMAHAWK-WIFI/support
— rather than trusting any version number written here. This board has
received multiple AGESA updates (ComboPI lineage progressing through the
1.2.0.3x/1.3.0.1x range) with recent revisions specifically calling out AMD
EXPO stability/latency improvements, so flashing to the latest version before
re-tuning settings is worthwhile. Confirm the installed version after boot
with `cat /sys/class/dmi/id/bios_version`.

## BIOS menu map (Click BIOS 5, Advanced Mode)

Press **Delete** during POST to enter setup. The interface (Click BIOS 5) has
two modes toggled with **F7**: **EZ Mode** (flat dashboard, no menu tree —
quick toggles like GAME BOOST/EXPO/fTPM/ErP live here, and MSI's own manual
warns not to touch the OC menu after using GAME BOOST/CREATOR GENIE) and
**Advanced Mode** (full menu tree — use this for everything below).

Top-level tabs in Advanced Mode: **SETTINGS**, **OC**, **M-FLASH**,
**OC PROFILE**, **HARDWARE MONITOR**, **Beta Runner**.

Function keys (same everywhere in setup): **F1** help, **F2** add/remove
favorite, **F3** Favorites menu, **F4** CPU Specifications, **F5** Memory-Z,
**F6** load optimized defaults, **F7** toggle EZ/Advanced mode, **F8** load OC
profile, **F9** save OC profile, **F10** save & reset, **F12** screenshot to
USB, **Ctrl+F** search.

Every menu path below (`Settings > ...`, `OC > ...`) is taken from MSI's
official AM5-series Click BIOS 5 manual (generic across AM5 boards, not a
TOMAHAWK-specific dump) — item availability/wording can still shift slightly
per BIOS version; if a path doesn't match what's on screen, use **Ctrl+F**
search for the setting name rather than hunting by hand.

## 0. Prevent this from happening again

**Confirmed by hands-on testing on this board: OC Profiles (F8/F9) are tied
to a specific BIOS version/build and will not load across a firmware
update.** A profile saved on `1.R1` was refused when attempting to load it
after flashing `1.R2` ("created for a different BIOS version"). So the F9
profile save recommended in earlier drafts of this doc is **not** the fix
for "the next BIOS update wipes settings again" — it only protects against
a CMOS clear or dying CMOS battery *on the same firmware version*, which is
a real but narrower problem than the one that started all this.

**This document is the actual defense against the original problem.**
Unlike a binary OC profile, the settings recorded here (EXPO enabled, SVM
enabled, Global C-state Enabled, etc.) are concepts, not a version-locked
blob — they survive any firmware version because they're re-entered by
hand from a written checklist rather than replayed from a snapshot. Keep
it current:

- After finishing a tuning pass, **update the Curve Optimizer value and
  fan curves recorded in this file** (sections 4 and 8) so the next
  BIOS-update recovery starts from a known-good number instead of from
  scratch.
- Still worth doing on **every individual BIOS version**, since it's free
  and does help within that version's lifetime: press **F9** ("Save
  Overclocking Profile") once settings are dialed in, and export a copy to
  USB too. Just don't expect it to survive the *next* flash — re-save it
  fresh after every future update instead of relying on an old one.
- If a saved profile is ever refused after a flash with a "different BIOS
  version" style error, that's expected per the above, not a sign
  something else is broken — fall back to this checklist and redo the
  settings by hand.

## 1. Boot / Boot Mode

- **Menu path:** `Settings > Advanced > Power Management Setup > BIOS UEFI/CSM
  Mode`, and `Settings > Boot` for ordering.
- **Boot Mode:** UEFI only — CSM **disabled** (`BIOS UEFI/CSM Mode` = UEFI).
  The NixOS Limine config has `biosSupport = false`, so legacy boot isn't
  usable anyway.
- **Boot order:** `Settings > Boot > Boot Option Priorities` — NVMe (Samsung
  970 EVO Plus) first. `FIXED BOOT ORDER Priorities` on the same page pins
  device *classes* (e.g. always try USB before HDD) independent of the
  per-slot list above it.
- **Fast Boot:** no item by this exact name is documented in MSI's generic
  AM5 manual for this menu — if the on-screen `Settings > Boot` page shows a
  "Fast Boot" toggle (board/BIOS-version dependent), leave it **Off** while
  re-tuning (so POST/BIOS screen stays reachable), re-enable once settings
  are confirmed stable. Otherwise `Full Screen Logo Display` and
  `AUTO CLR_CMOS` on the same page are the closest generic equivalents
  affecting POST speed/behavior.

## 2. Memory (OC menu)

- **Menu path:** `OC > EXPO` (top-level item, not nested — pick **Profile 1**
  from the dropdown). `OC > Memory Try It !` is the adjacent quick-preset
  picker if EXPO's own profile misbehaves. `OC > Memory Context Restore` and
  `OC > FCH Spread Spectrum` are also top-level `OC` items, referenced below.
  "DRAM Performance Mode" is not a literal item name in MSI's generic AM5
  manual — on this board it likely lives inside the EXPO/Advanced DRAM
  Configuration submenu under a slightly different label; treat the name
  below as descriptive, verify the actual wording on screen.
- **Enable EXPO Profile 1.** The installed kit (`CMK64GX5M2B5200C40`) is
  rated **DDR5-5200 CL40-40-40-77**. Before the reset, `facter.json` showed
  the board training at JEDEC 4800 — meaning EXPO was never actually enabled
  on this system. Turning it on now is a net improvement, not just a
  reversion to a prior state.
- **DRAM Performance Mode:** leave at **AMD AGESA Default** (not
  Competitive/Aggressive) on the first boot. Those modes tighten sub-timings
  automatically for a bit more performance but add instability risk — only
  worth trying after EXPO itself is confirmed stable.
- **Memory Context Restore:** leave **Enabled** (board default) — it caches
  training results so subsequent boots are fast. Only disable it if you hit
  intermittent cold-boot failures after the system has been idle/off for a
  while; that's a known (if uncommon) AM5 quirk traded off against boot speed.
- **First boot after enabling EXPO will be slow (up to a few minutes)** —
  the board is running full memory training. This is normal, not a hang;
  don't power off mid-training.
- **If EXPO 5200 fails to POST:**
  1. Clear CMOS and retry once — a bad training pass can wedge the board.
  2. Confirm both DIMMs are in the recommended slots (A2/B2 — check the
     manual silkscreen, usually the two slots second/fourth from the CPU).
  3. Try manually setting **VSOC (CPU SoC voltage) to 1.20–1.25V**, and stay
     **at or below 1.30V** — MSI issued a BIOS-level VSOC cap for exactly
     this board (`E7D75AMS.162`) after early Ryzen 7000/7000X3D BIOSes let
     VSOC run too high and degraded CPUs; the currently-installed `1.R1`
     firmware already enforces this, so manual VSOC shouldn't need to exceed
     it in normal use.
  4. If still unstable, step the memory frequency down (5200 is already the
     kit's rated speed, so this shouldn't be needed here — it mainly matters
     for people running higher-than-rated kits).
- 5200 MT/s is comfortably inside 1:1 Fclk:Mclk territory for this platform
  (the AM5 "sweet spot" issues mostly start above ~6000 MT/s where the
  memory controller can be forced to a slower 1:2 ratio) — no special
  Infinity Fabric tuning needed for this kit; leave IF Frequency at **Auto**.
- **Spread Spectrum (`OC > FCH Spread Spectrum`):** set to **Disabled** while
  tuning EXPO/PBO/Curve Optimizer. It slightly modulates clock signals to
  reduce EMI, at the cost
  of tiny timing jitter — a common source of marginal instability during
  overclocking/undervolting that's easy to misattribute to the RAM or CPU
  settings themselves. Re-enabling it afterward is optional and mostly
  irrelevant unless EMI/RF interference is an actual concern in this room.

## 3. CPU (OC menu)

- **Menu path:** all items below live under
  `OC > Advanced CPU Configuration`, mostly nested further under
  `> AMD Overclocking`. PBO and its sub-items are inside
  `AMD Overclocking > Precision Boost Overdrive (PBO)`; Global C-state
  Control and CPPC live one level over in `AMD Overclocking > AMD CBS`.
  `Advanced CPU Configuration > SMT Control` is a sibling, not nested under
  either.
- **Core Performance Boost / PBO:** Auto (matches the hidden-setting default
  `0x28=Auto` documented in `efi.md`). Set via `AMD CBS > Core Performance
  Boost`.
- **PBO Limits (`... > Precision Boost Overdrive (PBO) > PBO Limits`):** if
  left at **Auto/Motherboard**, the board applies its own
  (higher-than-AMD-stock) PPT/TDC/EDC limits — this is the common
  recommendation for boards with adequate VRMs (this board's VRM is fine for
  a 7600X) and pairs naturally with a negative Curve Optimizer offset
  (section 4). No action needed if Auto already resolves to Motherboard.
  The submenu exposes `PPT Limit [W]` / `TDC Limit [A]` / `EDC Limit [A]`
  individually if manual values are ever needed.
- **PBO Scalar (`... > Precision Boost Overdrive Scalar Ctrl > Precision
  Boost Overdrive Scalar`):** leave at default (**1x/Auto**). Raising it
  removes safety margin for sustained high clocks and shortens chip lifespan
  for negligible real-world gain — not recommended for a general-use
  desktop.
- **Platform Thermal Throttle Control (`... > Precision Boost Overdrive
  (PBO) > Platform Thermal Throttle Limit`):** Auto (95°C stock target) is
  fine. Optional: switching to **Manual** and capping at e.g. **85°C**
  trades a small amount of peak boost for meaningfully lower temps/noise —
  worth trying after Curve Optimizer tuning if thermals/fan noise bother
  you, not required.
- **SMT (`Advanced CPU Configuration > SMT Control`):** Enabled.
- **Global C-state Control (`... > AMD Overclocking > AMD CBS > Global
  C-state Control`): set explicitly to Enabled, not Auto** — this
  contradicts the "leave on Auto" default listed in `efi.md` (hidden offset
  `0x29`, default `0x03=Auto`), and it's worth the exception. Multiple
  independent reports (r/AMDHelp, Tom's Hardware, Windows Forum) converge
  on the same finding across various AM5 boards: **Auto frequently behaves
  like Disabled in practice**, causing stutter, downclocking, and FPS drops
  in games, while explicitly forcing **Enabled** restores expected boost
  behavior and smooths out latency. Fully **Disabled** is worse than either
  — it kills turbo boost on non-K-equivalent parts and raises temps for no
  benefit. This is exposed directly in `AMD CBS` (not just the hidden
  offset), so no `setup_var.efi` should be needed to set it.
- **CPPC / CPPC Preferred Cores:** leave **Enabled** (should already be the
  board default). No dedicated CPPC item turned up in MSI's generic AM5
  menu listing — it's most likely folded into `AMD CBS` under a related
  P-state/PSS entry (`PSS Support`) rather than a standalone toggle;
  confirm the exact label on screen before assuming it's missing. For
  non-X3D Ryzen 7000 like the 7600X, this lets the OS scheduler favor the
  highest-boosting cores for lightly-threaded work — no reason to disable
  it on a general-use desktop.
- No other manual voltage overrides — leave AMD defaults unless previously
  hand-tuned and you have a record of those values (this repo doesn't track
  BIOS-level CPU OC state). Manual voltage entry points, if ever needed,
  live under the separate `OC > DigitALL Power` submenu (`CPU Core Voltage`,
  `CPU NB/SoC Voltage`, etc.), not under `AMD Overclocking`.

## 4. CPU Undervolt — Curve Optimizer

No prior Curve Optimizer values are recorded anywhere in this repo (it's a
BIOS-only setting, not exposed to NixOS) — the previous tuning is lost with
the rest of NVRAM and needs to be re-derived from scratch. **Menu path:**
`OC > Advanced CPU Configuration > AMD Overclocking > Precision Boost
Overdrive (PBO) > Curve Optimizer` — sets **Curve Optimizer** to
All Cores/Per Core, then **All Core Curve Optimizer Sign** and
**All Core Curve Optimizer Magnitude** (or the per-core equivalents).

**Community consensus for the 7600X** (overclock.net, oc-corner.com,
r/overclocking, LTT forums — not authoritative, silicon/cooling-dependent,
verify yourself):

- **All Core, not per-core.** The 7600X has a single CCD/CCX (6 cores) — the
  usual per-core CO strategy on higher-core-count Ryzen parts buys little
  here.
- **Do not trust Ryzen Master's auto-tune** — multiple reports of it
  suggesting aggressive values (e.g. `-26` to `-30`) that boot-loop in
  practice; users had to fall back to `-20` manually after CMOS clear.
- **`-15` to `-25` all-core** is the range most users land on stably with
  decent air/AIO cooling. One detailed review found `-25` gave the best
  stability/performance balance, with `-30` starting to show instability on
  weaker coolers (Wraith Prism-class); some users report `-30` stable for a
  year but only with strong cooling — treat as an upper bound, not a target.
- **`-20` all-core** is the single value cited most often as a practical
  "just works" landing point for the 7600X specifically across multiple
  independent reports (an overclock.net user's board-forced floor after
  Ryzen Master's suggested `-26` boot-looped; an LTT forum user's stable
  daily setting). With an AIO already installed here, that's a reasonable
  target to validate toward rather than a from-scratch guess at `-10`.
- Undervolting mainly helps single-threaded boost clocks/temps; multi-thread
  performance gain is marginal.

Re-tuning procedure:

1. Set **PBO** to Advanced (or Enabled), leave PBO Limits at Motherboard/Auto.
2. Set **Curve Optimizer** to **All Core**, sign **Negative**, start at a
   conservative magnitude (e.g. `-10`).
3. Stress-test for stability at each step (e.g. `stress-ng --cpu $(nproc) --timeout 30m`
   plus a mixed AVX load, since integer-only stress tests won't catch all
   instabilities) and check for WHEA errors / crashes.
4. If stable, step down in increments of 5 (`-15`, `-20`, `-25`...) and
   re-test each time. Treat `-25` as the point to slow down and test longer;
   don't push past `-30` without strong cooling and extended validation.
5. Back off one step at the first sign of instability (crash, WHEA log
   entries, black screen).
6. **Record the final value here once found**, so it survives the next BIOS
   reset:

   > All-Core Curve Optimizer offset: `<fill in after retesting>`

## 5. Virtualization / Security

Required for the `virtualisation.libvirtd` + VFIO setup already in the flake
(`amd_iommu=on iommu=pt` kernel params, `pci-stub.ids=1022:15e3`):

- **SVM Mode (AMD-V) — `OC > Advanced CPU Configuration > AMD Overclocking >
  AMD CBS > SVM Mode`:** Enabled
- **IOMMU — same `AMD CBS` submenu, `IOMMU` item:** Enabled
- **Above 4G Decoding — `Settings > Advanced > PCIe/PCI Sub-system Settings >
  Above 4G memory/Crypto Currency mining`: Enabled — required for Resizable
  BAR to actually work**, not just a nice-to-have alongside it. ReBAR exposes
  the RTX
  3050's full VRAM as one CPU-addressable window, which needs 64-bit MMIO
  addressing above the 4GB boundary; without Above 4G Decoding, ReBAR either
  silently fails to enable or the GPU falls back to a small legacy BAR with
  no error shown. It also matters for the IOMMU/VFIO setup already in the
  flake (`pci-stub.ids=1022:15e3`) — with IOMMU on and multiple
  large-BAR devices (GPU + NVMe), leaving MMIO mapping confined below 4GB
  risks running out of address space for PCI BARs.
- **Resizable BAR / Smart Access Memory — same `PCIe/PCI Sub-system
  Settings` submenu, `Re-Size BAR Support` item:** Enabled (RTX 3050 supports
  it)
- **Hidden setting worth forcing explicitly (via `efi.md`, not reachable from
  the visible menu tree above): Local APIC
  Mode → x2APIC.** Offset `0x2D` in `AmdSetupRPL` defaults to `0xFF=Auto`;
  `efi.md`'s own unlock recipes call out forcing `0x02=x2APIC` as
  "improves multi-CPU/VM performance," which applies directly to the
  libvirtd/VFIO setup here. Modern kernels with IOMMU on usually resolve
  Auto to x2APIC anyway, but forcing it explicitly removes one more
  Auto-resolution unknown after a fresh reset:
  ```
  setup_var.efi 0x2D 0x02 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
  ```
- Everything else in the hidden `AmdSetupRPL` NBIO/Security table already
  defaults to what this setup needs and doesn't require touching:
  `IOMMU` (`0x3D`) defaults to `0x01=Enabled` (not Auto), `SCPC attribute
  control` (`0x40`) — the gate for these advanced options — defaults to
  `0xFF=Customized` (already unlocked), and `TPM` (`0x37A`) defaults to
  `0x01=ASP fTPM`. See [`efi.md`](efi.md) for the full offset reference.
  **Caveat:** `efi.md`'s offset table was extracted against BIOS `1P8`;
  this board is now on `1.R1` and the offsets haven't been re-verified
  against that firmware (see the staleness warning at the top of
  `efi.md`). Read a value with `setup_var.efi` before writing it and
  confirm it looks sane for that setting — don't write blind.

## 6. Secure Boot

- **Menu path:** `Settings > Security > Secure Boot`. Key management
  (`Provision Factory Default keys`, `Platform Key(PK)`, `Key Exchange
  Keys`, `Authorized/Forbidden Signatures`, etc.) is one level deeper under
  `Secure Boot > Key Management`.
- Set **Secure Boot** to **Disabled** (or Setup Mode with keys cleared) —
  this matches the current flake state:
  `boot.loader.limine.secureBoot.enable = false` in the desktop host config,
  with a TODO to re-enable once `sbctl` keys are generated and enrolled.
- Once that TODO is done: switch **Secure Boot Mode** to **Custom**, then use
  `Key Management` to enroll only your own `sbctl`-generated keys (not
  **Enroll all Factory Default keys**, which loads Microsoft's — `efi.md`'s
  BIOS flash procedure signs its own EFI tools with `sbctl`), and flip the
  flake option in the same change.

## 7. TPM

- **Menu path:** `Settings > Security > Trusted Computing` (also reachable
  as the **fTPM 2.0** quick toggle in EZ Mode's function-control row).
- **AMD fTPM switch:** Enabled (default). Not currently used for disk
  encryption on this host — harmless to leave on for future use.

## 8. Fan / Smart Fan curves

BIOS-level fan curves are **not tracked anywhere in this repo** — they live
only in board NVRAM and were wiped along with everything else. OS-level
`corectrl` config is separate and unaffected — though note `corectrl` is
primarily a GPU/CPU power control GUI, not a fan-curve tool for the
`nct6687` headers; it wasn't actually running by default (`programs.corectrl.enable`
only installs the package + polkit rule, it doesn't autostart the GUI) until
an entry was added to `spawn-at-startup` in
`modules/WM/niri/startup.nix` (`corectrl --minimize-systray`) on 2026-07-16.
Verify it's actually running with `pgrep -a corectrl` after a session
restart if fan/power control from it seems to be doing nothing. **Menu path:**
top-level
**HARDWARE MONITOR** tab (not nested under `Settings`) — pick **Smart Fan
Mode** per header, then drag points on the duty-vs-temperature curve editor.
`All Full Speed` / `All Set Default` / `All Set Cancel` buttons on the same
page apply/reset every header at once. Recreate them by hand per header.
Community-sourced
starting points below (AIO cooling, since that's what's installed) — treat
as a reasonable default, not gospel; adjust for actual noise/thermal
preference once retested.

**PUMP_FAN1 (AIO pump):** run it at a **constant high speed, not a curve.**
This is the near-universal recommendation across AIO vendors and
enthusiast forums — pumps are designed for continuous operation, and
modulating pump speed with load adds no meaningful cooling benefit while
adding wear/noise variation. Set **Pump Control: PWM, fixed ~80–100%**
(drop toward 80% only if the pump is audibly whining at full speed; most
modern AIO pumps are quiet even at 100%).

**CPU_FAN1 (radiator fans):** a 4-point PWM curve, temperature source =
CPU:

| Point | Temp | Duty |
|---|---|---|
| 1 | 30°C | 25% |
| 2 | 50°C | 50% |
| 3 | 70°C | 65–80% |
| 4 | 90°C | 100% |

This is a widely-circulated MSI baseline curve (used as-is by several AIO
system builders for MSI boards) — gentle at idle/light load, ramping hard
before the 95°C stock thermal target. If Platform Thermal Throttle Control
was set to 85°C manual (section 3), consider pulling point 4 in to 85°C
instead of 90°C so full fan speed arrives before the throttle point rather
than after it.

**SYS_FAN1–6 (case fans):** similar shape, lower ceiling since case fans
matter less for thermals than for airflow/acoustics:

| Point | Temp | Duty |
|---|---|---|
| 1 | 30°C | 25–35% |
| 2 | 50°C | 30–40% |
| 3 | 70°C | 40–50% |
| 4 | 80°C | 50–60% |

Set **Fan Step Up ≈ 0.7s / Fan Step Down ≈ 0.2s** (or similar — faster to
ramp up than down) if the board exposes those, to avoid audible fan-speed
"hunting" around a threshold.

Optional: since `nct6687` hwmon already exposes full sensor/fan control to
the OS, consider moving fan curves fully into OS-level control (e.g. via
`corectrl` or `fancontrol`) so a future BIOS reset can't affect them again.
Not required — just an option worth considering given this is the second
time BIOS state was lost.

## 9. iGPU

- **Menu path:** `Settings > Advanced > Integrated Peripherals >
  Integrated Graphics Configuration` for the items below;
  `Integrated Peripherals` itself (one level up) also holds `VGA Detection`.
- **Integrated Graphics:** Enabled. **UMA Frame Buffer Size:** Auto —
  matches the hidden-setting UMA_AUTO default in `efi.md`.
- **Keep the iGPU enabled, not disabled.** The NixOS config loads the
  `amdgpu` kernel module alongside `nvidia`/`nvidia_drm` — `services.xserver.videoDrivers`
  is `["nvidia"]` only (the RTX 3050 drives the actual display output), but
  `amdgpu` stays loaded so the iGPU is available for VAAPI hardware
  video encode/decode offload. Disabling the iGPU in BIOS would remove that
  device entirely and `amdgpu` would have nothing to bind to.
- **dGPU Only Mode:** no item by this exact name turned up in MSI's generic
  AM5 menu listing for this submenu — if present on screen (naming can vary
  by board/BIOS revision) leave it **Disabled**; this is the setting that
  would force the iGPU off entirely, don't enable it.
- **Initiate Graphic Adapter (same submenu):** leave **Auto** — this is the
  boot-GOP/primary-display selector. **No manual override needed.** MSI AM5
  boards auto-select the discrete GPU in the primary PCIe x16 slot for
  POST/boot display when one is installed — matches the existing
  hardware-config comment
  `PCI probe order is fixed: 01:00.1=NVIDIA(0), 10:00.1=AMD-HDMI(1)`, i.e.
  the NVIDIA card is already first in enumeration order. Only relevant if
  the monitor is plugged into the iGPU's video output by mistake — it
  should be connected to the RTX 3050's outputs.

## 10. Storage Mode

- **Menu path:** `Settings > Advanced > Integrated Peripherals > SATA Mode`.
- **SATA Mode:** AHCI (default) — not RAID. There's a single NVMe boot
  drive (Samsung 970 EVO Plus), no RAID array in use; RAID mode would just
  add an unnecessary driver dependency for Limine/Linux.

## 11. USB Configuration

- **Menu path:** `Settings > Advanced > Integrated Peripherals > USB
  Configuration`.
- **XHCI Hand-off:** Enabled (default) — needed for USB to work correctly
  before/without full OS driver support (e.g. install media, early boot).
- **Legacy USB Support:** Enabled (default) — keeps USB keyboard/mouse
  working in BIOS and non-UEFI-aware boot stages.

## 12. Power Management

- **Menu path:** `Settings > Advanced > Integrated Peripherals > Power
  Management Setup`.
- **ErP Ready: Disabled — required for Wake on LAN.** (Also toggleable as a
  quick button in EZ Mode's function-control row, in addition to this
  Advanced-mode location — the two write the same setting.) ErP/EuP power
  regulation cuts standby power to the LAN port in Shutdown (S5), which
  breaks WoL from a fully powered-off state regardless of any other WoL
  setting. This is not just a "nice to have" default here — it's a hard
  requirement given the WoL setup below.
- **Restore after AC Power Loss:** personal preference — **Power Off** if
  you'd rather the machine stay off after an outage (avoids surprise
  boots), or **Power On/Last State** if you want it to come back up
  unattended (useful if this box runs anything remotely-accessed). Neither
  is required by the NixOS config.
- **System Power Fault Protection:** optional; only useful if household
  power is unstable/"ropey" — leave Disabled otherwise.

## 13. Wake on LAN

The NixOS config already expects this to work:
`hosts/nixos/desktop/default.nix` sets
`networking.interfaces.enp12s0.wakeOnLan.enable = true`, and
`hardware-configuration.nix` sets `"ethernet.wake-on-lan" = "magic"` for the
NetworkManager connection. Both are OS-side and do nothing if the BIOS/board
doesn't pass wake signals through — the following BIOS-side settings are
required to actually make it work:

- **`Settings > Advanced > Integrated Peripherals > Power Management Setup >
  Wake Up Event Setup`:** enable **Resume By PCI/PCI-E Device**. MSI's
  generic AM5 manual only documents this one item (no separate "Resume By
  LAN" string) — the onboard LAN controller enumerates as a PCIe device, so
  this is almost certainly the setting that arms it; if the on-screen BIOS
  additionally shows a distinct "Resume By LAN" (naming can vary by board
  revision), enable that too. This is what lets a magic packet on the
  onboard LAN controller actually power the board back on.
- **ErP Ready must be Disabled** (section 12 above) — otherwise the LAN
  port loses standby power in S5 and no magic packet can reach it at all,
  even with Resume By LAN enabled.
- This wakes the board from **Shutdown (S5)** — full power-off, which is
  what `systemctl poweroff` leaves the machine in. Sleep/S3 WoL is a
  separate, less relevant case for a NixOS box that's normally fully off
  or fully on.

**Verify after saving BIOS settings and booting:**

```bash
# Confirm WoL is actually armed on the interface (look for "g" in Wake-on)
ethtool enp12s0 | grep -i wake-on
```

If it doesn't show `g` (magic packet), the NetworkManager/systemd-networkd
side isn't applying `wake-on-lan = magic` — that's a config-side issue, not
BIOS. If it does show `g` but a magic packet still doesn't wake the machine
from a full shutdown, the BIOS-side Wake Up Event settings above are the
next thing to check.

## If settings keep resetting on *every* boot (not just after this flash)

That's a different symptom from a one-time post-flash wipe and usually
means the **CMOS battery (CR2032) is dying** — it's what holds NVRAM state
when the PSU is off. Cheap to replace, easy to overlook after blaming the
firmware update. Worth checking if this happens again shortly after
finishing this checklist.

Also worth knowing for next time: this board has a **Safe Boot jumper
(`JOCFS1`)** — enabling it forces boot with default settings and a lower
PCIe mode, useful for recovering from a bad OC/CO setting without a full
CMOS clear — and a dedicated **Clear CMOS button on the rear I/O panel**, in
addition to the onboard jumper.

## Verification after saving and booting

```bash
# RAM actually training at rated EXPO speed
sudo dmidecode --type 17 | grep -i speed

# IOMMU groups active
dmesg | grep -i iommu

# Virtualization stack healthy
sudo systemctl status libvirtd

# Confirm flashed firmware version
cat /sys/class/dmi/id/bios_version
```

Once the system is stable, regenerate the hardware snapshot (it's currently
stale relative to the reflashed board) and commit it:

```bash
nix run github:numtide/nixos-facter -- --output hosts/nixos/desktop/facter.json
```
