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

## 0. Prevent this from happening again — save an OC Profile

Once every setting below is dialed in and the system has been stable for a
while, **save it as an OC Profile inside the BIOS itself** — this is a
different mechanism from whatever "backup" failed to restore this time
(that was likely a Windows/MSI Center-side snapshot or just NVRAM that got
wiped along with everything else by the flash):

- In BIOS, press **F9** ("Save Overclocking Profile") to save the current
  full settings state to one of the board's internal profile slots
  (independent of NVRAM/CMOS — survives a CMOS clear).
- Also export it to a **USB drive** from the same profile menu, and keep a
  copy of that file outside the machine (e.g. in this repo's scratch area
  or a personal backup location — it's a small binary blob, not secret).
- **F8** ("Load Overclocking Profile") restores from either location later.
- Redo this save whenever you meaningfully change tuning (new Curve
  Optimizer value, EXPO adjustments, etc.) — an out-of-date profile is
  only marginally better than none.

This is the actual fix for "restoring from backup didn't work" — a
BIOS-native profile slot/USB export, not relying on some other backup path.

## 1. Boot / Boot Mode

- **Boot Mode:** UEFI only — CSM **disabled**. The NixOS Limine config has
  `biosSupport = false`, so legacy boot isn't usable anyway.
- **Boot order:** NVMe (Samsung 970 EVO Plus) first.
- **Fast Boot:** Off while re-tuning (so POST/BIOS screen is reachable),
  can be re-enabled once settings are confirmed stable.

## 2. Memory (OC menu)

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
- **Spread Spectrum:** set to **Disabled** while tuning EXPO/PBO/Curve
  Optimizer. It slightly modulates clock signals to reduce EMI, at the cost
  of tiny timing jitter — a common source of marginal instability during
  overclocking/undervolting that's easy to misattribute to the RAM or CPU
  settings themselves. Re-enabling it afterward is optional and mostly
  irrelevant unless EMI/RF interference is an actual concern in this room.

## 3. CPU (OC menu)

- **Core Performance Boost / PBO:** Auto (matches the hidden-setting default
  `0x28=Auto` documented in `efi.md`).
- **PBO Limits:** if left at **Auto/Motherboard**, the board applies its own
  (higher-than-AMD-stock) PPT/TDC/EDC limits — this is the common
  recommendation for boards with adequate VRMs (this board's VRM is fine for
  a 7600X) and pairs naturally with a negative Curve Optimizer offset
  (section 4). No action needed if Auto already resolves to Motherboard.
- **PBO Scalar:** leave at default (**1x/Auto**). Raising it removes safety
  margin for sustained high clocks and shortens chip lifespan for
  negligible real-world gain — not recommended for a general-use desktop.
- **Platform Thermal Throttle Control:** Auto (95°C stock target) is fine.
  Optional: switching to **Manual** and capping at e.g. **85°C** trades a
  small amount of peak boost for meaningfully lower temps/noise — worth
  trying after Curve Optimizer tuning if thermals/fan noise bother you, not
  required.
- **SMT:** Enabled.
- No other manual voltage overrides — leave AMD defaults unless previously
  hand-tuned and you have a record of those values (this repo doesn't track
  BIOS-level CPU OC state).

## 4. CPU Undervolt — Curve Optimizer

No prior Curve Optimizer values are recorded anywhere in this repo (it's a
BIOS-only setting, not exposed to NixOS) — the previous tuning is lost with
the rest of NVRAM and needs to be re-derived from scratch. Location:
**AMD Overclocking → Precision Boost Overdrive → Curve Optimizer**.

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

- **SVM Mode (AMD-V):** Enabled
- **IOMMU:** Enabled
- **Above 4G Decoding: Enabled — required for Resizable BAR to actually
  work**, not just a nice-to-have alongside it. ReBAR exposes the RTX
  3050's full VRAM as one CPU-addressable window, which needs 64-bit MMIO
  addressing above the 4GB boundary; without Above 4G Decoding, ReBAR either
  silently fails to enable or the GPU falls back to a small legacy BAR with
  no error shown. It also matters for the IOMMU/VFIO setup already in the
  flake (`pci-stub.ids=1022:15e3`) — with IOMMU on and multiple
  large-BAR devices (GPU + NVMe), leaving MMIO mapping confined below 4GB
  risks running out of address space for PCI BARs.
- **Resizable BAR / Smart Access Memory:** Enabled (RTX 3050 supports it)

## 6. Secure Boot

- Set to **Disabled** (or Setup Mode with keys cleared) — this matches the
  current flake state: `boot.loader.limine.secureBoot.enable = false` in the
  desktop host config, with a TODO to re-enable once `sbctl` keys are
  generated and enrolled.
- Once that TODO is done: switch BIOS Secure Boot to **Custom mode using
  only your own enrolled keys** (not the Standard/Microsoft default keys —
  `efi.md`'s BIOS flash procedure signs its own EFI tools with `sbctl`), and
  flip the flake option in the same change.

## 7. TPM

- **fTPM (AMD PSP):** Enabled (default). Not currently used for disk
  encryption on this host — harmless to leave on for future use.

## 8. Fan / Smart Fan curves

BIOS-level fan curves are **not tracked anywhere in this repo** — they live
only in board NVRAM and were wiped along with everything else. OS-level
`corectrl` config is separate and unaffected. Recreate them by hand in
**Hardware Monitor** (main BIOS screen) per header. Community-sourced
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

- **iGPU Configuration:** UMA_AUTO (default) — matches the hidden-setting
  default in `efi.md`.
- **Keep the iGPU enabled, not disabled.** The NixOS config loads the
  `amdgpu` kernel module alongside `nvidia`/`nvidia_drm` — `services.xserver.videoDrivers`
  is `["nvidia"]` only (the RTX 3050 drives the actual display output), but
  `amdgpu` stays loaded so the iGPU is available for VAAPI hardware
  video encode/decode offload. Disabling the iGPU in BIOS would remove that
  device entirely and `amdgpu` would have nothing to bind to.
- **dGPU Only Mode:** leave **Disabled** (board default) — this is the
  setting that would force the iGPU off entirely; don't enable it.
- **No manual "Primary Display"/boot-GOP override needed.** MSI AM5 boards
  auto-select the discrete GPU in the primary PCIe x16 slot for POST/boot
  display when one is installed — matches the existing hardware-config
  comment `PCI probe order is fixed: 01:00.1=NVIDIA(0), 10:00.1=AMD-HDMI(1)`,
  i.e. the NVIDIA card is already first in enumeration order. Only relevant
  if the monitor is plugged into the iGPU's video output by mistake — it
  should be connected to the RTX 3050's outputs.

## 10. Storage Mode

- **SATA/NVMe Mode:** AHCI (default) — not RAID. There's a single NVMe boot
  drive (Samsung 970 EVO Plus), no RAID array in use; RAID mode would just
  add an unnecessary driver dependency for Limine/Linux.

## 11. USB Configuration

- **XHCI Hand-off:** Enabled (default) — needed for USB to work correctly
  before/without full OS driver support (e.g. install media, early boot).
- **Legacy USB Support:** Enabled (default) — keeps USB keyboard/mouse
  working in BIOS and non-UEFI-aware boot stages.

## 12. Power Management

- **ErP Ready: Disabled — required for Wake on LAN.** ErP/EuP power
  regulation cuts standby power to the LAN port in Shutdown (S5), which
  breaks WoL from a fully powered-off state regardless of any other WoL
  setting. This is not just a "nice to have" default here — it's a hard
  requirement given the WoL setup below.
- **Restore AC Power Loss:** personal preference — **Power Off** if you'd
  rather the machine stay off after an outage (avoids surprise boots), or
  **Power On/Last State** if you want it to come back up unattended (useful
  if this box runs anything remotely-accessed). Neither is required by the
  NixOS config.
- **System Power Failure Protection:** optional; only useful if household
  power is unstable/"ropey" — leave Disabled otherwise.

## 13. Wake on LAN

The NixOS config already expects this to work:
`hosts/nixos/desktop/default.nix` sets
`networking.interfaces.enp12s0.wakeOnLan.enable = true`, and
`hardware-configuration.nix` sets `"ethernet.wake-on-lan" = "magic"` for the
NetworkManager connection. Both are OS-side and do nothing if the BIOS/board
doesn't pass wake signals through — the following BIOS-side settings are
required to actually make it work:

- **Settings → Advanced → Wake Up Event Setup** (menu path/exact naming
  varies by BIOS revision): enable **Resume By PCI-E Device** and/or
  **Resume By LAN** — whichever appears for this board/revision, enable
  both if both are present. This is what lets a magic packet on the
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
