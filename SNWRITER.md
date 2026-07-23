# snWriter — operating guide (BraX3 / MT6835)

How to run **Coosea SN Writer V10.2324.0.18** to provision IMEI/serial on the
BraX3, and how to tell a real PASS from a false one. This is the tool the
`perform_apex_config` fix in this repo exists to make pass.

> **The tool itself is not in this repo.** It is MediaTek/Coosea proprietary and
> its distribution contains live RKP credentials (`RKP/cred.json`), serial/IMEI
> provisioning data (`SNDATA`) and MTK Serial Link Authentication components
> (`SLA_Challenge.dll`). Get it from the ODM / internal share. The **databases it
> needs are** in this repo, under [`databases/`](databases/).

---

## 1. Prerequisites

| Item | Detail |
|---|---|
| Tool | `SN_Writer.exe` — Coosea SN Writer **V10.2324.0.18** (Android S/T/U/V) |
| Driver | **MediaTek PreLoader USB VCOM** (Windows). The status bar must show it when connected. |
| AP database | `databases/apdb-P27/APDB_MT6835___W2421` (+ `_ENUM` companion) |
| Modem database | `databases/mddb-P18/MDDB.META.ODB_MT6835_S00_MOLY_NR17_R1_MP3_RC_MP_V19_10_P18.XML.GZ` |
| Phone | flashed with a build containing the fixes in this repo, **SELinux enforcing** |

### Database version matching is mandatory

The modem DB must match the modem firmware **exactly**. Check the phone first:

```bash
adb shell getprop gsm.version.baseband
# expect: MOLY.NR17.R1.MP3.RC.MP.V19.10.P18   <- the "P18" must match the MDDB
```

A mismatched MDDB is its **own** failure mode, unrelated to the fixes here.
Note the modem DB is an **ODB `.XML.GZ`**, *not* the `.EDB` you may expect —
searching for `*.EDB` finds nothing.

---

## 2. Configuration (one time)

Main window:

| Field | Value |
|---|---|
| ComPort | `USB VCOM` |
| Target Type | `Smart Phone` |
| Country | `EU` |
| Activation Code / Google Key / CSR / DRM Key | `SKIP` (unless your line provisions them) |

Then open **System Config**:

- ☑ **IMEI** — the item being written
- ☑ **Load AP DB from DUT**  ← preferred
- ☑ **Load Modem DB from DUT** ← preferred
- `AP_DB`  → `…\databases\apdb-P27\APDB_MT6835___W2421`
- `MDDB1` → `…\databases\mddb-P18\MDDB.META.ODB_…P18.XML.GZ`

**"From DUT" is the right setting.** The device serves the matching pair itself
(`/vendor/etc/apdb` and `/data/vendor_de/meta/mddb`), which removes any chance of
a version mismatch. The local paths above are the fallback for when from-DUT is
unavailable.

---

## 3. Running a provisioning pass

**The connection is a preloader handshake — order matters, and `adb reboot meta`
does NOT work on this device** (it just reboots to normal Android; the only way
into META is snWriter catching the preloader).

1. Power the phone **completely off** (not just screen off).
2. In snWriter, click **Start** (arms the tool; it waits for the preloader port).
3. **Now plug in USB.** The tool catches the MediaTek PreLoader USB VCOM port as
   the phone powers up and boots it into META mode.
4. Watch the counters: `Total / Pass / Fail`.

If you plug the cable in *before* clicking Start, the phone boots to normal
Android and the tool never sees the preloader window — power off and retry.

---

## 4. Reading the result

### PASS (what correct looks like)

- Big green **PASS** box, `Pass: 1`, `Fail: 0`
- Status line: **"All Operate successfully!!"**
- The whole backup step completes in roughly **0.2 s**

### FAIL — the signature this repo's fix addresses

- Red FAIL, and the log shows a **15-second** timeout on:
  `REQ_BackupNvram2BinRegion` / `SP_META_SetCleanBootFlag_r`
- IMEI itself was written and persists, but the final NVRAM backup never
  confirms — the tool therefore reports FAIL.

If you see exactly that, the device is missing the META fix (see §6).

### Verify the write actually stuck

```bash
# after the phone reboots to normal Android
adb shell getprop | grep -i imei      # or dial *#06#
```

---

## 5. Capturing logs (do this on any FAIL)

**PC-side:** `C:\SNWriter_LOG\<timestamp>\` — per-step timings, shows exactly
which primitive timed out.

**Device-side — the META boot log.** This is the important one and it is easy to
miss: META is a *separate boot*, so its kernel log only survives in `pstore`
after the phone reboots out of META. Grab it immediately after the run:

```bash
adb root
adb shell "cat /sys/fs/pstore/console-ramoops-0" > meta-boot.txt
grep -iE "apex_mnt_dir|NULL VINTF|meta_tst|SIGSEGV|avc.*denied" meta-boot.txt
```

Interpretation:
- `apex_mnt_dir` on `apex-info-list.xml`, or `NULL VINTF MANIFEST` → the META fix
  did not take; the APEX manifest is still mislabeled in META.
- `meta_tst … SIGSEGV` → the NVRAM HIDL service never registered, so `meta_tst`
  dereferenced a null client (the original root cause).
- Clean, plus a green PASS → genuinely fixed.

> **Do not judge the META fix by a normal-boot check.** `adb shell ls -Z
> /bootstrap-apex/apex-info-list.xml` is `apex_info_file` on normal boot **with or
> without** the patch, because normal `init.rc` relabels it anyway. Only META
> boot exercises the fix.

---

## 6. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| 15 s timeout on `SetCleanBootFlag` / backup | Missing the META `perform_apex_config` fix — flash a build with this repo's patches |
| Tool never connects / no port | Cable plugged in before clicking Start; or PreLoader VCOM driver missing. Power off, click Start, then plug in |
| Connects but DB errors | MDDB/APDB version mismatch — re-check `gsm.version.baseband` (§1) |
| PASS on one build, FAIL on another | Confirm the flashed image really contains the fix; don't trust an accumulated device state — full-flash + wipe userdata for a clean test |
| Works only in permissive | That is the original bug signature. Permissive masks the SELinux-labeling cascade; the fix makes it pass **enforcing** |

---

## 7. What a trustworthy PASS requires

A result is only meaningful if the baseline is clean:

1. Full flash of a `super` **verified** to contain the fix, plus **wiped userdata**
   and stock `tee` — not a device carrying state from earlier experiments.
2. **SELinux enforcing** (`adb shell getenforce`).
3. Green PASS from the tool **and** a clean META `pstore` log (§5).

Anything less is not a pass — that lesson is why this guide exists.
