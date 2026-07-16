# MSI MAG B650 TOMAHAWK WIFI (E7D75AMS) — UEFI Shell Hidden Settings Guide

## Board Info
- **Board**: MSI MAG B650 TOMAHAWK WIFI
- **Platform**: AMD AM5 — Ryzen 7000 / 9000 series (DDR5)
- **Offsets below extracted from BIOS `E7D75AMS.1P8`** (via `ifrextractor-rs`)
- Main VarStore: `AmdSetupRPL`
  - GUID: `3A997502-647A-4C82-998E-52EF9486A247`
  - VarStoreId: `0x5000`
  - Size: `0x888`

> ⚠️ **Offset staleness warning:** the table below was captured against
> BIOS `1P8`. The board has since been updated to `1.R1` (per
> `hosts/nixos/desktop/facter.json`, `smbios.bios.version`), several AGESA
> revisions later. MSI/AMI can reshuffle IFR form layouts between BIOS
> revisions, which shifts `setup_var` offsets — a table built for one
> version is not guaranteed accurate on another. **Before writing any
> offset with `setup_var.efi`, read it first** and sanity-check the
> returned value against this table's documented default/options; if it
> doesn't look plausible for that setting, stop and re-extract against the
> current firmware (`ifrextractor` against the currently loaded `1.R1`
> image — see "Re-verifying offsets after a BIOS update" below for the exact
> procedure) rather than trust this table blind. Re-dumping and refreshing
> this file after any future BIOS update is the correct long-term fix — this
> hasn't been done yet for `1.R1`.

---

## Re-verifying offsets after a BIOS update (`ifrextractor`)

The NixOS package is `ifrextractor-rs`, but the installed binary is named
**`ifrextractor`** (confirmed via `nix-config`'s `home/desktop/default.nix` +
upstream source — the package name and binary name differ). It's already in
`home/desktop/default.nix`, `hosts/nixos/desktop/hardware-configuration.nix`,
and `hosts/nixos/matebook/default.nix`.

**CLI usage** (from upstream `src/main.rs`, not guessed):

```
ifrextractor file.bin list
    — list all string and form packages in the input file
ifrextractor file.bin single <form_package_number> <string_package_number>
    — extract one form package using one string package (numbers from `list`)
ifrextractor file.bin lang <language>
    — extract all form packages using all string packages in a given language
ifrextractor file.bin all
    — extract all form packages using all string packages
ifrextractor file.bin verbose
    — extract all form packages using English string packages, with raw
      opcode bytes included — this is the mode to use for rebuilding an
      offset table, since it gives byte-level detail to cross-check
ifrextractor file.bin
    — default: English string packages only, no raw bytes
```

It writes its extracted output as text file(s) next to the input file (exact
naming wasn't traced from source — check the working directory / the tool's
own console output after running to find them, rather than guessing a
pattern here).

**Procedure to refresh this document against the currently installed BIOS
(`1.R1`, or whatever `cat /sys/class/dmi/id/bios_version` reports at the
time):**

1. Get the exact BIOS image currently running. Either:
   - Reuse the `E7D75AMS.1R1` file downloaded from
     https://www.msi.com/Motherboard/MAG-B650-TOMAHAWK-WIFI/support that was
     used to perform the actual flash (see the update procedure below), or
   - Dump the live SPI flash directly with `flashrom` for a byte-exact
     match to what's actually running (more authoritative, but needs
     `flashrom` support for this chipset/programmer — verify before relying
     on it).
2. Run `ifrextractor E7D75AMS.1R1 list` first. Confirm a form package
   referencing AMD CBS/Overclocking is present, and note its form/string
   package numbers.
3. Run `ifrextractor E7D75AMS.1R1 verbose` for the full byte-level dump.
4. Isolate the `AmdSetupRPL` section in the output: grep for the known GUID
   or VarStoreId —
   `grep -n -A2 -B2 "3A997502-647A-4C82-998E-52EF9486A247\|VarStoreId: 0x5000"`.
5. For each setting in the tables below, find its `Prompt` string in the
   new dump and compare the `VarOffset` value shown against the `Offset`
   column here. If they match, the table is still accurate for that
   setting. If a `Prompt` maps to a different `VarOffset`, or a setting
   disappears/moves to a different `VarStoreId`, the table entry is stale —
   correct it.
6. Update the `**Offsets below extracted from BIOS ...**` line at the top
   of this file to the new version, and remove or update the staleness
   warning once the pass is done.

This hasn't been run yet for `1.R1` — the table below still reflects `1P8`
and should be treated per the staleness warning until this procedure has
been carried out at least once on the current firmware.

---

## BIOS Update via UEFI Shell (no USB needed)

Tools source: MSI Forum — [Svet's UEFI Shell Flash & Patch Tool](https://forum-en.msi.com/index.php?threads/forum-uefi-shell-flash-patch-tool-v2-51-update-4-for-msi-boards.343010/) (`MSI_UEFI_FlashTool.rar`)

### EFI partition layout

EFI partition (`/dev/nvme0n1p1`) is mounted at **`/boot`** (not `/boot/EFI`).  
In UEFI shell this is **`fs0:`** (NVMe, alias `HDB0`).

```
/boot/                        = fs0:\
├── E7D75AMS.1XX              ← BIOS file (root of EFI partition = fs0:\)
├── efi/                      = fs0:\efi\
│   ├── BOOT/                 ← svet.efi MUST be here (fs0:\efi\BOOT\)
│   │   ├── svet.efi          ← manually copied, NOT NixOS-managed — see caveat below
│   │   ├── AFUE51605s.efi    ← manually copied
│   │   ├── AFUE592.efi       ← manually copied
│   │   ├── Bootx64.efi       ← manually copied (bundled with MSI_UEFI_FlashTool)
│   │   ├── shell.efi         ← NixOS-managed! `boot.loader.limine.additionalFiles` in
│   │   │                        hosts/nixos/desktop/hardware-configuration.nix, sourced
│   │   │                        from `pkgs.edk2-uefi-shell` — survives nixos-rebuild
│   │   ├── STARTUP.NSH       ← manually copied
│   │   └── ME_FW/
│   │       ├── FWUpdLcl.efi       ← manually copied
│   │       ├── FWUpdLcl_RL.efi    ← manually copied
│   │       └── ME*.bin             ← manually copied, not EFI executables
│   ├── limine/
│   │   └── BOOTX64.EFI       ← managed by NixOS's `boot.loader.limine`
│   └── tools/                ← extra tools (setup_var.efi etc.) — separate download,
│                                 not yet provisioned as of 2026-07-15, see below
└── limine/                   ← kernel + initrd, managed by `boot.loader.limine`
```

**Caveat on the manually-copied files above:** unlike `shell.efi`, they are
plain files sitting on the ESP outside of Nix's control. It's unconfirmed
whether they survive `nixos-rebuild switch` (the Limine installer might
prune unmanaged files from `/boot` when it reinstalls — this is the leading
theory for why this whole toolset went missing once already before this
was written). If they disappear again after a rebuild, the fix is the same
pattern used for `shell.efi`: vendor them into the repo (e.g. under
`hosts/nixos/desktop/boot/msi-flash-tool/`, alongside the existing
`./boot/background.jpg` wallpaper reference) and add them to
`additionalFiles` too, rather than re-copying by hand again.

### Secure Boot

**Currently disabled on this host** (`boot.loader.limine.secureBoot.enable = false`
in `hosts/nixos/desktop/hardware-configuration.nix`, `sbctl status` confirms no
keys are enrolled: `Installed: ✗`, `Secure Boot: ✗ Disabled`). The `db`/`dbx`/
`KEK`/`PK` files referenced in older revisions of this doc **do not exist**
on this system — that line described an aspirational future state, not
reality, and caused confusion when the tooling below turned out to be
missing entirely (it had never actually been deployed, not wiped by
anything). **Do not trust "signed"/"present" claims in this file as fact —
verify against the live filesystem first.**

While Secure Boot stays disabled, **`sbctl sign` is not required** — unsigned
EFI binaries execute fine from the UEFI Shell. Only sign them once Secure
Boot is actually being turned on (matches the pre-existing TODO in the host
config), at which point run this once for every `.efi` (not the `ME*.bin`
payloads — those aren't PE executables and `sbctl sign` doesn't apply to
them):
```bash
sudo sbctl create-keys      # only if sbctl status shows no keys yet
sudo sbctl enroll-keys
sudo sbctl sign /boot/efi/BOOT/svet.efi
sudo sbctl sign /boot/efi/BOOT/AFUE51605s.efi
sudo sbctl sign /boot/efi/BOOT/AFUE592.efi
sudo sbctl sign /boot/efi/BOOT/Bootx64.efi
sudo sbctl sign /boot/efi/BOOT/ME_FW/FWUpdLcl.efi
sudo sbctl sign /boot/efi/BOOT/ME_FW/FWUpdLcl_RL.efi
sudo sbctl verify  # check all signed
```

### Update procedure

1. Download new BIOS from https://www.msi.com/Motherboard/MAG-B650-TOMAHAWK-WIFI/support
2. Extract and copy BIOS file to EFI root:
   ```bash
   sudo cp ~/Downloads/7D75vXXX/E7D75AMS.XXX /boot/
   sudo rm /boot/E7D75AMS.OLD  # remove previous version
   ```
3. Update tools if new `MSI_UEFI_FlashTool.rar` available:
   ```bash
   sudo cp ~/Downloads/MSI_UEFI_FlashTool/EFI/BOOT/svet.efi /boot/efi/BOOT/
   sudo cp ~/Downloads/MSI_UEFI_FlashTool/EFI/BOOT/AFUE51605s.efi /boot/efi/BOOT/
   sudo cp ~/Downloads/MSI_UEFI_FlashTool/EFI/BOOT/AFUE592.efi /boot/efi/BOOT/
   sudo cp ~/Downloads/MSI_UEFI_FlashTool/EFI/BOOT/STARTUP.NSH /boot/efi/BOOT/
   sudo cp ~/Downloads/MSI_UEFI_FlashTool/EFI/BOOT/ME_FW/* /boot/efi/BOOT/ME_FW/
   # Re-sign after updating tools
   sudo sbctl sign /boot/efi/BOOT/svet.efi
   sudo sbctl sign /boot/efi/BOOT/AFUE51605s.efi
   sudo sbctl sign /boot/efi/BOOT/AFUE592.efi
   sudo sbctl sign /boot/efi/BOOT/ME_FW/FWUpdLcl.efi
   sudo sbctl sign /boot/efi/BOOT/ME_FW/FWUpdLcl_RL.efi
   ```
4. Reboot → **Limine menu → "UEFI Shell"** entry (chainloads
   `efi/BOOT/shell.efi`, the full Tianocore EDK2 shell, via
   `boot.loader.limine.extraEntries` in
   `hosts/nixos/desktop/hardware-configuration.nix`).

   The Limine menu entry is still preferable to MSI BIOS → Boot Override →
   "UEFI Shell" (the firmware's own stripped-down build is missing
   commands like `mode`), but **the shell choice was not the real bug** —
   see the STARTUP.NSH fix note below. The `mode`-missing error is
   harmless/cosmetic either way.
5. In shell:
   ```
   fs0:\efi\BOOT\STARTUP.NSH
   ```
6. Script auto-detects BIOS file, flashes with `/B /K` (preserves settings), reboots automatically.

### Notes
- `STARTUP.NSH` (v2.58) searches for `svet.efi` at `fsN:\efi\BOOT\svet.efi` (case-insensitive on FAT32)
- BIOS file must be in **`fs0:\`** (= `/boot/`) — the root of the EFI partition
- `/B /K` flags: `/B` = BIOS block only (not ME), `/K` = keep NVRAM settings
- Settings survive update — NVRAM preserved by `/K` flag, AMD crypto-32 path

**`STARTUP.NSH` bug fixed on 2026-07-15:** the stock script fails on any
modern/strict EDK2 Shell (reproduced identically on both the firmware's
built-in shell *and* a freshly-built official `pkgs.edk2-uefi-shell`
202602 — ruling out "wrong shell" as the cause) with `The script's
Indexvar '0' is incorrect / Script Error Status: Aborted (line number
32)`. Root cause: the drive-detection loop (`FOR %A RUN (0 20 1)` ...
`goto proceed`) exits via `goto` without reaching its own `endfor`,
leaving `%A`'s loop state unresolved in the shell's loop stack. The BIOS
file-detection loop later in the script (`FOR %A in E????%P%V?*.???*`)
then reuses `%A` and collides with that unresolved state. **Fix:** rename
that second loop's variable to an unused letter (`%D`), both in the `FOR`
header and its one body reference (`set -v bios %A` → `set -v bios %D`).
`%A` is never referenced again after that point in the script, so this is
a complete, minimal fix — no other loop in the script needs the same
treatment (the other early-`goto`-exited loops, `%B` and `%P`/`%V`, are
also never reused afterward). If re-downloading a fresh
`MSI_UEFI_FlashTool` package in the future, re-apply this same edit before
trusting the bundled `STARTUP.NSH`.
- After flash: verify with `cat /sys/class/dmi/id/bios_version` and update `facter.json`:
  ```bash
  nix run github:numtide/nixos-facter -- --output hosts/nixos/desktop/facter.json
  ```

---

## Tools Needed (for setup_var / hidden settings)

### Option A: setup_var.efi (datasone) — RECOMMENDED
Download from: https://github.com/datasone/setup_var.efi/releases

Syntax:
```
setup_var.efi <offset> [<value>] [-s <size>] [-n <VarName>] [-guid <GUID>]
```
- Read:  `setup_var.efi 0x28 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247`
- Write: `setup_var.efi 0x28 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247`

**Note:** The `setup_var.efi` in `/boot/efi/tools/` is the datasone build. The old MSI-bundled version does NOT support `-n`/`-guid` flags.

### Option B: RU.efi (Universal UEFI variable editor)
Navigate to the GUID `3A997502-647A-4C82-998E-52EF9486A247` → `AmdSetupRPL`
Then edit the byte at the desired offset.

### Option C: modGRUBShell.efi
```
setup_var 0x28 0x00
```
(Uses the last accessed variable, navigate to AMD CBS first)

---

## UEFI Shell Quick-Start (setup_var)

1. Boot into UEFI Shell via the **Limine menu → "UEFI Shell"** entry (not
   MSI BIOS Boot Override — see the note in the update procedure above for
   why). This loads `fs0:\efi\BOOT\shell.efi`.
2. Switch to NVMe: `fs0:` (check mapping table — NVMe path contains `NVMe(0x1,...)`)
3. Run `\EFI\tools\setup_var.efi <offset> -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247`
   — **note:** `EFI\tools\setup_var.efi` is not currently provisioned on
   this system (only `EFI\BOOT\*` from the flash tool package exists as of
   2026-07-15 — see the file-layout table above). This step needs
   `setup_var.efi` (datasone build) downloaded and placed there first; see
   "Tools Needed" below for the source.

---

## All Hidden/Suppressed/GrayedOut Settings

### VarStore: AmdSetupRPL | GUID: 3A997502-647A-4C82-998E-52EF9486A247

---

### 🔧 CPU SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| Core Performance Boost | 0x28 | 1 | 0x01 | 0x00=Off, **0x01=Auto** |
| Global C-state Control | 0x29 | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |
| Opcache grayout flag | 0x2A | 1 | 0x00 | 0x00=hidden, 0x01=shown, **0x02=Display** |
| Opcache Control | 0x2B | 1 | 0xFF | 0x01=Disabled, 0x00=Enabled, **0xFF=Auto** |
| Streaming Stores | 0x2C | 1 | 0xFF | 0x01=Disabled, 0x00=Enabled, **0xFF=Auto** |
| Local APIC Mode | 0x2D | 1 | 0xFF | 0x00=Compat, 0x01=xAPIC, **0x02=x2APIC**, 0xFF=Auto |
| ACPI C1 Declaration | 0x2E | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |
| SMT Control | 0x35 | 1 | 0x01 | 0x00=Disable SMT, **0x01=Auto** |
| Platform First Error Handling | 0x27 | 1 | 0x03 | 0x01=Enabled, 0x00=Disabled, **0x03=Auto** |
| MCA error thresh enable | 0x2F | 1 | 0xFF | 0x00=False, 0x01=True, **0xFF=Auto** |
| SMU and PSP Debug Mode | 0x32 | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |
| PPIN Opt-in | 0x33 | 1 | 0xFF | 0x00=Disabled, 0x01=Enabled, **0xFF=Auto** |
| Enhanced REP MOVSB | 0x34 | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |
| Fast Short REP MOVSB (FSRM) | 0x371 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| AVX512 | 0x373 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| MONITOR/MWAIT disable | 0x374 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| Corrector Branch Predictor | 0x375 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| CPU Speculative Store Modes | 0x376 | 1 | 0xFF | **0xFF=Auto**, 0x00=Balanced, 0x01=More Spec, 0x02=Less Spec |
| SVM Lock | 0x377 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| SVM Enable | 0x378 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| PAUSE Delay | 0x2D3 | 1 | 0xFF | **0xFF=Auto**, 0x00=Disabled, 0x01=16cyc, 0x02=32cyc, 0x03=64cyc, 0x04=128cyc |
| Latency Under Load (LUL) | 0x3DE | 1 | 0xFF | 0x00=Enabled, 0x01=Disabled, **0xFF=Auto** |
| RedirectForReturnDis | 0x36A | 1 | 0xFF | 0x01=1, 0x00=0, **0xFF=Auto** |
| REP-MOV/STOS Streaming | 0xAE | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |

---

### 🔧 PREFETCHER SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| L1 Stream HW Prefetcher | 0x21 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| L2 Stream HW Prefetcher | 0x22 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| L1 Stride Prefetcher | 0xAF | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| L1 Region Prefetcher | 0xB0 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| L1 Burst Prefetch Mode | 0x369 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| L2 Up/Down Prefetcher | 0xB1 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |

---

### 🔧 MEMORY SETTINGS (DDR5)

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| Active Memory Timing Settings | 0x116 | 1 | 0xFF | **0xFF=Auto**, 0x01=Enabled |
| Memory Target Speed (MT/s) | 0x117 | 2 | 3200 | Decimal: 3200-11200 in steps of 200 |
| CA Timing Mode | 0x487 | 1 | 0xFF | **0xFF=Auto**, 0x01=1N, 0x02=2N, 0x03=1N-DDR2000only |
| Power Down Enable | 0x16F | 1 | 0xFF | 0x00=Disabled, 0x01=Enabled, **0xFF=Auto** |
| ECC | 0x171 | 1 | 0xFF | 0x00=Disabled, 0x01=Enabled, **0xFF=Auto** |
| Data Scramble | 0x173 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| Chipselect Interleaving | 0x174 | 1 | 0xFF | 0x00=Disabled, **0xFF=Auto** |
| DFE Read Training | 0x178 | 1 | 0xFF | **0xFF=Auto**, 0x01=Enable, 0x00=Disable |
| Memory Context Restore | 0x26C | 1 | 0xFF | **0xFF=Auto**, 0x01=Enabled, 0x00=Disabled |
| Memory P-state | 0x3E0 | 1 | 0xFF | **0xFF=Auto**, 0x01=Enabled, 0x00=Disabled |
| TX DFE Taps | 0x2CF | 1 | 0xFF | **0xFF=Auto**, 0x01-0x04=1-4 Taps |
| RX DFE Taps | 0x368 | 1 | 0xFF | **0xFF=Auto**, 0x01-0x04=1-4 Taps |

**DDR SPD Timings (enable Active Memory Timing first → 0x116=0x01):**
| Setting | Offset | Size | Default |
|---------|--------|------|---------|
| Tcl Ctrl (0=Auto,1=Manual) | 0x119 | 1 | 0x00 |
| Tcl value | 0x11A | 2 | 22 |
| Trcd Ctrl | 0x11C | 1 | 0x00 |
| Trcd value | 0x11D | 2 | 8 |
| Trp Ctrl | 0x11F | 1 | 0x00 |
| Trp value | 0x120 | 2 | 8 |
| Tras Ctrl | 0x122 | 1 | 0x00 |
| Tras value | 0x123 | 2 | 30 |
| Trc Ctrl | 0x125 | 1 | 0x00 |
| Trc value | 0x126 | 2 | 32 |
| Twr Ctrl | 0x128 | 1 | 0x00 |
| Twr value | 0x129 | 2 | 48 |
| Trfc1 Ctrl | 0x12B | 1 | 0x00 |
| Trfc1 value | 0x12C | 2 | 50 |
| Trfc2 Ctrl | 0x12E | 1 | 0x00 |
| Trfc2 value | 0x12F | 2 | 50 |
| TrfcSb Ctrl | 0x131 | 1 | 0x00 |
| TrfcSb value | 0x132 | 2 | 50 |

**DDR Non-SPD Timings:**
| Setting | Offset | Size |
|---------|--------|------|
| Trtp Ctrl | 0x134 | 1 |
| Trtp value | 0x135 | 2 |
| TrrdL Ctrl | 0x137 | 1 |
| TrrdL value | 0x138 | 2 |
| TrrdS Ctrl | 0x13A | 1 |
| TrrdS value | 0x13B | 2 |
| Tfaw Ctrl | 0x13D | 1 |
| Tfaw value | 0x13E | 2 |
| TwtrL Ctrl | 0x140 | 1 |
| TwtrL value | 0x141 | 2 |
| TwtrS Ctrl | 0x143 | 1 |
| TwtrS value | 0x144 | 2 |
| Twrrd Ctrl | 0x15E | 1 |
| Twrrd value | 0x15F | 2 |
| Trdwr Ctrl | 0x161 | 1 |
| Trdwr value | 0x162 | 2 |

---

### 🔧 SMU / POWER SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| TDP Control | 0x64 | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| TDP value (mW, 32-bit) | 0x65 | 4 | 0 | e.g. 0x0000EA60=60000mW=60W |
| PPT Control | 0x69 | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| PPT value (mW, 32-bit) | 0x1BD | 4 | 0 | |
| Thermal Control | 0x6A | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| TjMax (°C, 32-bit) | 0x6B | 4 | 0 | |
| TDC Control | 0x6F | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| TDC_VDDCR_VDD (mA) | 0x1C1 | 4 | 0 | |
| EDC Control | 0x70 | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| EDC_VDDCR_VDD (mA) | 0x71 | 4 | 0 | |
| ECO Mode | 0x2D8 | 1 | 0x00 | **0x00=Disable**, 0x01=65W, 0x02=105W |
| Infinity Fabric Freq | 0x269 | 1 | 0xFF | **0xFF=Auto**, see table below |
| CPPC Dynamic Preferred Cores | 0x2D9 | 1 | 0xFF | 0x00=Freq, 0x01=Cache, 0x02=Driver, **0xFF=Auto** |
| Power Supply 1 Control | 0x2DE | 1 | 0xFF | 0x01=LCI, 0x00=TCI, **0xFF=Auto** |
| GFXOFF | 0x2DB | 1 | 0x0F | 0x00=Disable, 0x01=Enable, **0x0F=Auto** |
| VDDP Voltage Control | 0x9E | 1 | 0x00 | 0x01=Manual, **0x00=Auto** |
| VDDP Voltage (mV) | 0x3EE | 2 | 0 | 0-2000mV |
| Sustained PowerLimit (mW) | 0x2C3 | 4 | 0 | |
| Fast PPT Limit (mW) | 0x2C7 | 4 | 0 | |
| Slow PPT Limit (mW) | 0x2CB | 4 | 0 | |

**Infinity Fabric Frequency Values (0x269):**
```
0x00=100MHz, 0x01=200MHz, 0x02=400MHz, 0x03=500MHz,
0x04=667MHz, 0x05=800MHz, 0x1D=1900MHz, 0x1E=1933MHz,
0x1F=1950MHz, 0x20=1960MHz, 0x21=1967MHz, 0x22=2000MHz,
0x24=2067MHz, 0x26=2133MHz, 0x28=2200MHz, 0x2A=2267MHz,
0x2C=2333MHz, 0x2E=2400MHz, 0x30=2467MHz, 0x32=2533MHz,
... 0xFF=Auto
```

---

### 🔧 DF (DATA FABRIC) SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| DF Cstates | 0x3C | 1 | 0xFF | 0x00=Disabled, 0x01=Enabled, **0xFF=Auto** |
| Memory interleaving | 0x36 | 1 | 0x07 | 0x00=Disabled, 0x01=Enabled, **0x07=Auto** |
| Memory interleaving size | 0x37 | 1 | 0x07 | 0x00=256B, 0x01=512B, 0x02=1KB, 0x03=2KB, **0x07=Auto** |
| DRAM map inversion | 0x38 | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |
| Disable DF sync flood ext | 0x39 | 1 | 0xFF | 0x01=Disabled, 0x00=Enabled, **0xFF=Auto** |
| Disable DF sync flood | 0x3A | 1 | 0x03 | 0x01=Disabled, 0x00=Enabled, **0x03=Auto** |
| Freeze DF queues on error | 0x3B | 1 | 0x03 | 0x00=Disabled, 0x01=Enabled, **0x03=Auto** |

---

### 🔧 NBIO / SECURITY SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| IOMMU | 0x3D | 1 | 0x01 | 0x00=Disabled, **0x01=Enabled**, 0x0F=Auto |
| Pre-boot DMA Protection | 0x3E | 1 | 0x01 | **0x01=Enabled**, 0x00=Disabled, 0x0F=Auto |
| Kernel DMA Protection | 0x3F | 1 | 0x01 | **0x01=Enabled**, 0x00=Disabled, 0x0F=Auto |
| SCPC attribute control | 0x40 | 1 | 0xFF | 0x00=0, 0x01=1, 0x02=2, 0x03=3, **0xFF=Customized** |
| PCIe ARI Support | 0x41 | 1 | 0x0F | 0x00=Disabled, 0x01=Enabled, **0x0F=Auto** |
| SMEE | 0xB8 | 1 | 0x03 | 0x00=Disable, 0x01=Enable, **0x03=Auto** |
| SEV Control | 0x36B | 1 | 0xFF | 0x01=Disable, 0x00=Enable, **0xFF=Auto** |
| Trusted Platform Module | 0x37A | 1 | 0x01 | 0xFE=Auto, 0xFF=Disabled, 0x00=dTPM, **0x01=ASP fTPM**, 0x02=Pluton fTPM |
| Microsoft Security Levels | 0x37C | 1 | 0xFF | **0xFF=Customized**, 1-9=levels |
| SMM Isolation Support | 0x37E | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| DRTM Support | 0x37D | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |
| Pro Part attribute (TSME) | 0x37F | 1 | 0x00 | **0x00=0**, 0x01=1 |
| SNP Memory Coverage | 0xB3 | 1 | 0xFF | 0x00=Disabled, 0x01=Enabled, 0x02=Custom, **0xFF=Auto** |
| FAR Switch | 0x192 | 1 | 0xFF | 0x01=Enabled, 0x00=Disabled, **0xFF=Auto** |

---

### 🔧 GFX / DISPLAY SETTINGS

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| iGPU Configuration | 0x44 | 1 | 0x02 | 0x0F=Auto, 0x00=iGPU Off, 0x01=UMA_SPEC, **0x02=UMA_AUTO**, 0x03=UMA_GAME |
| UMA Version | 0x45 | 1 | 0x0F | 0x00=Legacy, 0x01=Non-Legacy, **0x0F=Auto** |
| UMA Frame buffer Size (MB) | 0x46 | 4 | 0xFFFFFFFF | 512/768/1024/2048/3072/4096/8192/16384 |
| dGPU Only Mode | 0x3D9 | 1 | 0x00 | 0x0F=Auto, **0x00=Disabled**, 0x01=Enabled |
| NB Azalia (HDMI Audio) | 0x4B | 1 | 0x0F | 0x00=Disabled, 0x01=Enabled, **0x0F=Auto** |

---

### 🔧 FCH / USB / MISC

| Setting | Offset | Size | Default | Options |
|---------|--------|------|---------|---------|
| FCH Spread Spectrum | 0x63 | 1 | 0x0F | 0x00=Disabled, 0x01=Enabled, **0x0F=Auto** |
| Ac Loss Control | 0x61 | 1 | 0x03 | 0x00=Off, 0x01=On, **0x03=Previous**, 0x0F=Auto |
| ESPI Enable | 0x62 | 1 | 0x0F | 0x00=Disabled, 0x01=Enabled, **0x0F=Auto** |
| ABL Console Out Control | 0xA9 | 1 | 0x02 | 0x01=Enable, 0x00=Disable, **0x02=Auto** |
| Pluton Support | 0x486 | 1 | 0x0F | **0x0F=Auto**, 0x00=Disabled, 0x01=Enabled |
| NPU Deep Sleep Enable | 0x359 | 1 | 0x01 | 0x00=Disabled, **0x01=Enabled**, 0xFF=Auto |
| SyncFifo Mode Override | 0x26D | 1 | 0xFF | 0x01=Disable, 0x00=Enable, **0xFF=Auto** |

---

## Common Unlock Recipes

### 🔓 Expose AMD CBS Advanced Options (required first step)
The `SCPC attribute control` at offset `0x40` gates many options.
```
# Read current value
setup_var.efi 0x40 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247

# Set to Customized (unlocks IOMMU/SVM/DMA controls)
setup_var.efi 0x40 0xFF -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Disable IOMMU (for GPU passthrough or debugging)
```
setup_var.efi 0x3D 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Enable x2APIC (improves multi-CPU/VM performance)
```
setup_var.efi 0x2D 0x02 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Disable Global C-states (better latency, worse power)
```
setup_var.efi 0x29 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Enable Memory Overclocking (unlock DDR5 timings)
```
# Enable Active Memory Timing Settings
setup_var.efi 0x116 0x01 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247

# Set Memory Speed to 6000 MT/s (0x1770 = 6000 decimal)
setup_var.efi 0x117 0x70 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x118 0x17 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
# (0x117 = low byte, 0x118 = high byte of 16-bit value)
```

### 🔓 Set Infinity Fabric to 2000 MHz
```
# 2000MHz = value 0x22 = 34 decimal
setup_var.efi 0x269 0x22 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Disable Core Performance Boost (CPB)
```
setup_var.efi 0x28 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Set Custom TDP (e.g., 65W = 65000mW = 0x0000FDE8)
```
# First enable Manual TDP Control
setup_var.efi 0x64 0x01 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
# Set TDP value (little-endian 32-bit)
# 65000mW = 0xFDE8 → bytes: E8 FD 00 00
setup_var.efi 0x65 0xE8 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x66 0xFD -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x67 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x68 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Disable AMD Prefetchers (low latency tuning)
```
setup_var.efi 0x21 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x22 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0xAF 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0xB0 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0xB1 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Enable UMA_GAME_OPTIMIZED (for iGPU gaming on Ryzen AI/780M)
```
setup_var.efi 0x44 0x03 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Set UMA Frame buffer to 4GB (iGPU VRAM)
```
# First set iGPU to UMA_SPECIFIED (0x01)
setup_var.efi 0x44 0x01 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
# Set UMA FB to 4096MB (0x1000 in little-endian 32-bit)
setup_var.efi 0x46 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x47 0x10 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x48 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
setup_var.efi 0x49 0x00 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

### 🔓 Disable SEV (Secure Encrypted Virtualization)
```
# First ensure SMEE=0 (offset 0xB8)
setup_var.efi 0x36B 0x01 -s 0x01 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

---

## Reading ALL Current Values (Diagnostic Script)

Save this as `read_all.nsh` on your USB:

```
echo "=== AMD CBS AmdSetupRPL Key Settings ==="
echo "--- CPU ---"
echo -n "Core Performance Boost (0x28): "
setup_var.efi 0x28 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "Global C-state (0x29): "
setup_var.efi 0x29 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "SMT Control (0x35): "
setup_var.efi 0x35 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "Local APIC Mode (0x2D): "
setup_var.efi 0x2D -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "AVX512 (0x373): "
setup_var.efi 0x373 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo "--- Power ---"
echo -n "TDP Control (0x64): "
setup_var.efi 0x64 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "Infinity Fabric Freq (0x269): "
setup_var.efi 0x269 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "ECO Mode (0x2D8): "
setup_var.efi 0x2D8 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo "--- Memory ---"
echo -n "Active Memory Timing (0x116): "
setup_var.efi 0x116 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo "--- NBIO/Security ---"
echo -n "IOMMU (0x3D): "
setup_var.efi 0x3D -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "SCPC attribute (0x40): "
setup_var.efi 0x40 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo -n "TPM (0x37A): "
setup_var.efi 0x37A -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
echo "--- GFX ---"
echo -n "iGPU Config (0x44): "
setup_var.efi 0x44 -n AmdSetupRPL -guid 3A997502-647A-4C82-998E-52EF9486A247
```

---

## ⚠️ Important Notes

1. **Always backup** current values before changing: `setup_var.efi 0xXX -n AmdSetupRPL -guid ...`
2. **Size matters**: Most settings are 1-byte (`-s 0x01`), memory timings are 2-byte (`-s 0x02`), power values are 4-byte (`-s 0x04`)
3. **After changing**: Power cycle (not just reboot) for some settings (SMT, SEV)
4. **Recovery**: MSI boards support BIOS flash backup — if you brick, use the M-Flash button on the board
5. **GUID format**: The GUID in setup_var.efi must include dashes: `3A997502-647A-4C82-998E-52EF9486A247`
6. For **setup_var.efi** by datasone, use: `-n AmdSetupRPL` (variable name) or `-guid` (GUID)

---

## MSI-Specific Settings (from 105C8D0 module)

The `105C8D0` IFR module is a simpler IDE configuration module. The main AMD CBS settings are all in `1155148`.

For MSI OC settings (CPU voltage, etc.), those are in a **different VarStore** not using `AmdSetupRPL`. These would be in the MSI setup module — to find them, look for VarStores in the `105C8D0` IFR files. These use a Class `0x88` FormSet (MSI OC tools).
