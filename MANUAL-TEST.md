# Manual test guide — BraX3 factory provisioning fixes

Step-by-step for a developer testing this **without any agent**, from a fresh
tree to a verified device. Follow in order; the verification steps exist because
skipping them produces false PASS/FAIL results.

---

## 0. ⚠️ Before you start — what you need

Only **one** thing is missing from this repo: the snWriter tool itself (§0.2).
Everything else, including the vendor blobs, is here.

### 0.1 Vendor proprietary blobs — **REQUIRED, and they ARE in this repo**

The device patches reference these via `proprietary-files.txt`. Without them the
build produces an image where **snWriter cannot work at all** (no `meta_tst`),
EngineerMode is absent, and PriFactoryTest is absent.

Shipped here two ways — use either:

```bash
# preferred: fetch the branch (git-compressed, ~162 MB)
cd vendor/brax/brax3
git fetch <this-repo> vendor_brax_brax3 && git checkout FETCH_HEAD

# or apply the patch files
cd vendor/brax/brax3 && git am /path/to/patches/vendor_brax_brax3/*.patch
```

Upstream source of truth remains the Brax Gerrit:
`https://brax3-iodeos-review.os-source.co/Brax3_IodeOs/vendor_brax_brax3`
(branch `brax3-prifactorytest-app`).

Three commits provide them:

| Commit | Provides |
|---|---|
| `d5ccd5d` | `bin/meta_tst`, `bin/atcid`, `bin/audiocmdservice_atci`, `vendor.mediatek.hardware.atci@1.0.so`, `libwifical.so`, `libwifinvram.so`, `libhfmanagerwrapper.so` + their init rc |
| `9cc8eb5` | `EngineerMode.apk`, `bin/em_svr`, `libem_*_jni.so`, `libaudiotoolkit.so`, `libsysenv_system.so` |
| `1776d78` | `PriFactoryTest.apk` (49 MB) |

These are MediaTek/ODM **proprietary binaries** — treat this repo accordingly
(it is private, and must stay private).

### 0.2 The snWriter tool — **REQUIRED for Test A**

**Coosea SN Writer V10.2324.0.18**. Not in this repo: its distribution contains
live RKP credentials (`RKP/cred.json`), serial/IMEI provisioning data (`SNDATA`)
and MTK SLA components. Get it from the ODM / internal share.

The **databases it needs ARE in this repo** → [`databases/`](databases/).

### 0.3 Also needed

- **SP Flash Tool V6.2404** (Windows) — flashing
- **MediaTek PreLoader USB VCOM driver** (Windows) — snWriter connection
- Build host: the `brax-builder:20.04` docker image + the iodé BraX3 tree

---

## 1. Get the source

The tree is Brax's pinned iodé fork (manifest `lineage-23.2` / `android-16.0.0_r4`):

```bash
repo init -u https://brax3-iodeos-review.os-source.co/Brax3_IodeOs/manifests_android -b <branch>
repo sync -c -j8
```

Base revisions the patches apply onto:
- `device/brax/brax3` → Brax **v7.6** (`4dc8143`)
- `frameworks/base`, `system/sepolicy` → the iodé revisions the manifest pins

---

## 2. Apply the patches (**5 repos** — don't skip vendor or hardware/mediatek)

```bash
cd device/brax/brax3     && git am /path/to/patches/device_brax_brax3/*.patch
cd hardware/mediatek     && git am /path/to/patches/hardware_mediatek/*.patch
cd frameworks/base       && git am /path/to/patches/frameworks_base/*.patch
cd system/sepolicy       && git am /path/to/patches/system_sepolicy/*.patch

cd vendor/brax/brax3     && git am /path/to/patches/vendor_brax_brax3/*.patch
# (or fetch the vendor_brax_brax3 branch instead — see §0.1)
```

Apply `hardware_mediatek` **before or together with** `frameworks_base` — the
latter references the module the former defines.

**All five are required.** What breaks if you skip one:

| Skipped | Symptom |
|---|---|
| `hardware_mediatek` | **Build break:** `frameworks/base/Android.bp:205:1: "framework-internal-utils" depends on undefined module "vendor.mediatek.hardware.nvram-V1.0-java"`. That module is *defined* here; `frameworks_base` only references it. |
| `frameworks_base` | Factory app crashes with `NoClassDefFoundError: com.pri.utils.NvramUtils`, and stays disabled (no enable hook) so `*#*#8804#*#*` does nothing |
| `vendor_brax_brax3` | snWriter can't work at all (no `meta_tst`/ATCI); EngineerMode + PriFactoryTest absent |
| `system_sepolicy` | snWriter FAILs at 15 s (missing the apex-label prerequisite) |
| `device_brax_brax3` | Nothing is wired in |

---

## 3. ⚠️ Pre-build: fix `out/` ownership

**If anyone ever ran the builder as root, a normal build fails instantly** with:

```
chmod out/soong/.temp: operation not permitted
#### failed to build some targets (1 seconds) ####
```

This looks exactly like "the patch is broken" but isn't. Check and fix:

```bash
find out -maxdepth 6 -user root | wc -l          # must be 0
# if not 0:
docker run --rm -v $PWD:/tree -w /tree brax-builder:20.04 chown -R 1000:1000 out/
```

---

## 4. Build

```bash
docker run --rm -v $PWD:/tree -w /tree -u 1000:1000 \
  -e HOME=/tmp -e USE_CCACHE=1 -e CC_WRAPPER=/usr/bin/ccache \
  brax-builder:20.04 bash -lc \
  "source build/envsetup.sh && lunch lineage_brax3-bp4a-userdebug \
   && m installclean && m framework systemimage vendorimage superimage"
```

- **`m installclean` is not optional** — it clears staged install files. Without
  it a stale `meta_init.system.rc` or `framework.jar` can produce a false PASS.
- Expect **~1–1.5 h** for a clean build; incremental is minutes.
- Build as **uid 1000**, consistently (see §3).

---

## 5. ⚠️ Verify the fixes are IN the image — before flashing

Do not skip this. It catches "built the wrong thing", which is a real failure mode.

```bash
R=out/target/product/brax3; H=out/host/linux-x86/bin
$H/simg2img $R/super.img /tmp/super.raw
$H/lpunpack /tmp/super.raw /tmp/parts
$H/fsck.erofs --extract=/tmp/se /tmp/parts/system_ext_a.img
$H/fsck.erofs --extract=/tmp/sys /tmp/parts/system_a.img

# 1. META fix (note: system_EXT partition, not system)
grep -c '^ *perform_apex_config' /tmp/se/etc/init/hw/meta_init.system.rc     # >= 1

# 2. NvramUtils — framework.jar is DEXED, so unzip -l finds nothing.
#    Must grep the dex:
cd /tmp && unzip -oq /tmp/sys/system/framework/framework.jar 'classes*.dex'
for d in classes*.dex; do strings $d | grep -q com/pri/utils/NvramUtils && echo "NvramUtils OK: $d"; done

# 3. enable hook, in services.jar
rm -f classes*.dex && unzip -oq /tmp/sys/system/framework/services.jar 'classes*.dex'
for d in classes*.dex; do strings $d | grep -q "Enabled factory test application" && echo "enable-hook OK: $d"; done

# 4. factory app + engineermode present
ls /tmp/sys/system/priv-app/PriFactoryTest/PriFactoryTest.apk
```

---

## 6. Flash

Copy `super.img` into a full flash package (boot chain, firmware, scatter,
download_agent, preloader — unchanged by these patches).

SP Flash Tool V6.2404:
1. Load `MT6835_Android_scatter.txt`
2. **Download Only**, all partitions checked incl. `userdata` (clean wipe) and `tee`
3. Power phone **off**, click Download, then plug USB

⚠️ **Never use "Format All + Download"** — it erases the NVRAM regions, destroying
IMEI/serial and RF calibration.

ℹ️ **A "Unknown error occurred" popup after `[userdata 25/25] 100%` is benign** —
the DA errors on the userdata *finalize* while the data itself is written. Check
the log: `CMD:WRITE-PARTITIONS ... error code: -1` right after the `userdata`
entry, with everything at 100%. Just boot it. (To avoid the popup entirely,
uncheck `userdata`.)

First boot is slow (userdata re-created, 49 MB app optimized).

---

## 7. Test A — snWriter (the headline)

Detailed guide: [`SNWRITER.md`](SNWRITER.md). Short form:

1. Check DB match: `adb shell getprop gsm.version.baseband` → must be `…V19.10.P18`
2. snWriter config: ComPort `USB VCOM`, Target `Smart Phone`, Country `EU`,
   IMEI checked, **Load AP DB + Modem DB from DUT** (fallback: the repo `databases/`)
3. **Power phone fully OFF → click Start in snWriter → THEN plug USB.**
   `adb reboot meta` does **not** work on this device — the only way into META is
   snWriter catching the preloader.

**PASS** = green box, `Pass:1 Fail:0`, "All Operate successfully!!", backup ~0.2 s
**FAIL** = 15 s timeout on `REQ_BackupNvram2BinRegion` / `SP_META_SetCleanBootFlag_r`

### ⚠️ How to verify correctly

**Do NOT judge the META fix from a normal boot.** This check is meaningless:

```bash
adb shell ls -Z /bootstrap-apex/apex-info-list.xml   # apex_info_file either way!
```

Normal `init.rc` relabels that file **with or without** the patch. Only META boot
exercises the fix. After the snWriter run (phone reboots to normal Android), the
**previous** boot in pstore *is* the META boot:

```bash
adb root
adb shell "cat /sys/fs/pstore/console-ramoops-0" > meta-boot.txt
grep -iE "apex_mnt_dir|NULL VINTF|meta_tst|SIGSEGV" meta-boot.txt
# clean + green PASS = genuinely fixed
```

---

## 8. Test B — EngineerMode

```bash
adb shell pm list packages | grep engineermode
adb shell am start -n com.mediatek.engineermode/.EngineerMode
# or dial *#*#3646633#*#*
adb shell "logcat -b crash -d | tail -20"      # expect no crash
```
PASS = the EngineerMode menu opens.

---

## 9. Test C — Factory test app

**On a clean flash, run NO `pm enable`** — that is the whole point of the test.

```bash
# 1. did the boot-time enable hook fire?
adb shell "dumpsys package com.pri.factorytest | grep -m1 -oE 'enabled=[0-9]'"
# -> enabled=1        (a fresh flash defaults to 0; 1 means the hook ran)
adb shell "pm list packages -d | grep -c factorytest"
# -> 0                (not in the disabled list)

# 2. dial the code on the phone:
#    *#*#8804#*#*     -> the factory test menu should open

# 3. or launch directly
adb shell am start -n com.pri.factorytest/.PrizeFactoryTestActivity
adb shell "pidof com.pri.factorytest && echo RUNNING"
adb shell "logcat -b crash -d | tail -20"          # no NvramUtils NoClassDefFoundError
```

**Expected quirks (not bugs):**
- **No app-drawer icon.** The launcher aliases stay disabled
  (`bool/is_*_launcher_enabled=false` in the APK) — deliberate, matches the ODM
  BSP. Entry is the dial code.
- **Some individual hardware tests may hit SELinux denials** on sysfs nodes. The
  menu and NVRAM path work; per-test grants are separate, open-ended work.

---

## 10. Gotchas summary (things that waste a day)

| Symptom | Cause |
|---|---|
| Build fails in 1 s, `chmod out/soong/.temp` | root-owned `out/` from a root build — chown to 1000 (§3) |
| snWriter FAILs at 15 s | Missing META fix, or you flashed the wrong image — verify §5 |
| snWriter never connects | Cable plugged in before clicking Start; or missing PreLoader VCOM driver |
| Factory app `-92 class does not exist` | Missing the enable hook (`frameworks_base/0002`) or `pm default-state` was run |
| Factory app crashes `NoClassDefFoundError NvramUtils` | Missing `frameworks_base/0001` |
| snWriter/EngineerMode entirely absent | Missing the **vendor blobs** (§0.1) |
| "Unknown error" at end of flash | Benign userdata finalize (§6) |
| PASS on one build, FAIL on rebuild | Accumulated device state — always full-flash + wipe userdata |
| `/sys/fs/pstore` unreadable | Need `adb root` |

## 11. What a trustworthy result requires

1. All **four** patch sets applied (device, frameworks_base, sepolicy, **vendor**)
2. `out/` owned by uid 1000; built with `m installclean`
3. Fixes verified **inside the packed super** (§5) before flashing
4. Full flash + **wiped userdata**, SELinux **enforcing** (`adb shell getenforce`)
5. Nothing enabled by hand on the device
6. snWriter green **and** a clean META pstore log

Anything less is not a pass.
