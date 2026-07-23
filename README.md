# BraX3 (MT6835) — factory provisioning fixes for iodéOS

> ⚡ **Quick start:** For brief instructions on applying the fixes that switch the device into a mode allowing the MediaTek SN Writer tool to write the SN/IMEI, see [QUICK-START.md](QUICK-START.md).

Related fixes that restore **factory provisioning** on the iodé/LineageOS
BraX3 build. The headline result:

> **MediaTek SN Writer passes GREEN under SELinux enforcing**, and the ODM
> factory test app opens from the `*#*#8804#*#*` dial code on a clean flash.
> **Re-verified 2026-07-23 on a from-scratch build** — drift-free tree,
> `m installclean`, patch presence checked *inside* the packed `super` before
> flashing, full flash + wiped userdata, enforcing, **nothing enabled by hand**.

## What's in here

| # | Change | Status | Test procedure |
|---|---|---|---|
| 1 | **snWriter / META provisioning** — IMEI + serial writing | ✅ **Verified green on device** | [Test A](#test-a--snwriter-provisioning-the-main-fix) |
| 2 | **EngineerMode** — MTK engineering app set restored | ✅ **Verified working** | [Test B](#test-b--engineermode) |
| 3 | **Native factory boot** — A16 APEX fix ported to `factory_init.rc` | ➖ **Defensive only** — this LK never selects `factory_init.rc` | [Test C](#test-c--factory-mode-needs-verification) |
| 4 | **PriFactoryTest Android app** — prebuilt integration + bilingual UI policy | ✅ **Verified on device** — opens via `*#*#8804#*#*`, runs tests, no crash | [Test D](#test-d--prifactorytest-android-factory-app) |
| 5 | **Framework support** — `NvramUtils` compat API + boot-time package enable | ✅ **Verified on device** | [Test D](#test-d--prifactorytest-android-factory-app) |

**Change #5 is required for #4 to work at all.** Without the `NvramUtils`
framework class the app dies with `NoClassDefFoundError` as soon as it starts;
without the boot-time enable the manifest-disabled package is unreachable, so
*neither* `am start` *nor* the dial code can open it.

Branches:

| Branch | Content |
|---|---|
| `main` | This README + the patch series in `patches/` |
| `device_brax_brax3` | `device/brax/brax3` with the 10-commit series (on top of iodé v7.6) |
| `vendor_brax_brax3` | `vendor/brax/brax3` — the proprietary blobs the device patches reference (meta_tst/ATCI, EngineerMode, PriFactoryTest) |
| `system_sepolicy` | `system/sepolicy` label prerequisite + its A16 context-test fixture (**upstream candidate for iodé**) |
| *(no `frameworks_base` branch)* | **By design** — see the note below |

`frameworks/base` changes ship as **patches only**
(`patches/frameworks_base/`). That repo carries the entire AOSP framework
history — **7.32 GiB**, versus 1 MB / 41 MB / 162 MB for the other three.
Pushing it as a branch would take this repo from ~39 MB to ~7.4 GB — past
GitHub's limits and painful to clone forever — to deliver a **2-patch,
~250-line** change. Apply the patch files instead; please don't "fix" this
asymmetry by pushing the branch.

**Five** patch sets are in `patches/`: device 10, `hardware_mediatek` 1,
frameworks_base 2, system_sepolicy 2, vendor_brax_brax3 3 — **18 patches**. The
blob-carrying repos additionally have branches, which are the lighter route for
those (git-compressed rather than base64-in-patch).

> ⚠️ **`hardware_mediatek` is required and easy to miss.** It defines the
> `vendor.mediatek.hardware.nvram-V1.0-java` module that
> `patches/frameworks_base/0001` links into `framework-internal-utils`. Without
> it the build fails with
> `"framework-internal-utils" depends on undefined module "vendor.mediatek.hardware.nvram-V1.0-java"`.
> Apply it **before or together with** `frameworks_base`.

---

## The bug

snWriter wrote and verified the IMEI correctly, then its **final** step —
`REQ_BackupNvram2BinRegion` / `SP_META_SetCleanBootFlag_r` — timed out after
exactly 15 s, so the tool reported **FAIL**. The factory line requires a green
PASS, so this blocked production.

Confusing symptoms that made this hard:

- The stock MTK BSP (Android 13) passed; iodé (Android 16) failed.
- **Permissive** SELinux passed, **enforcing** failed — but **no AVC was ever logged**.
- The IMEI itself was written correctly and persisted, so provisioning "almost" worked.

## Root cause — an Android 13 → 16 porting gap in MTK's META init

1. META mode boots a dedicated init script
   (`androidboot.init_rc=/system_ext/etc/init/hw/meta_init.system.rc`), inherited
   from MediaTek's **Android 13** BSP.
2. On A13, `apexd` restorecon'd the `apex-info-list.xml` it wrote (`RestoreconPath`
   at the end of `EmitApexInfoList`). **On A16 that responsibility moved**: normal
   `init.rc` runs **`perform_apex_config`** right after `exec_start apexd-bootstrap`,
   and *that* restorecons the manifest (and generates the linker configuration).
3. The A13-derived META init never ran `perform_apex_config`. So in META the
   manifest kept its tmpfs parent label `apex_mnt_dir`. `servicemanager` /
   `hwservicemanager` may only read `apex_info_file` → **"NULL VINTF MANIFEST"**
   → **no HAL could register**, including `vendor.mediatek.hardware.nvram@1.1::INvram`.
4. On `FT_UTILCMD_SET_CLEAN_BOOT_FLAG`, MTK's `meta_tst` called
   `INvram::getService()`, got **null**, logged `client is NULL` — **and then
   dereferenced it anyway** (`client->BackupToBinRegion_All_Exx`) → **SIGSEGV**.
   The PC then simply waited out its configured 15 s timeout on a dead process.
5. IMEI writing kept working because it uses an in-process editor
   (`META_Editor_WriteFile_OP`), **not** the HIDL service — which is exactly why
   only the *backup* step failed.

Permissive "worked" because the mislabeled file was still readable, so the HAL
registered and the backup completed in ~214 ms.

> **Debugging note for reviewers:** the process was *crashing*, not hanging. An
> earlier kernel-stack capture appeared to show `meta_tst` blocked reading a CCCI
> modem port — but that was the **auto-restarted** `meta_tst` idling normally; the
> original PID had already SIGSEGV'd seconds earlier. Check PIDs across the
> timeline before trusting a "hang" stack.

## The fixes

### `device_brax_brax3` — 10 commits

| # | Commit | What |
|---|---|---|
| 1 | `re-enable MTK ATCI + meta_tst provisioning blobs` | The open-source blob scrub had removed ATCI/`meta_tst`, so nothing serviced META at all. Prerequisite. |
| 2 | `pull in ATCI/meta_tst transitive vendor libs` | Their transitive library deps. |
| 3 | `enable EngineerMode app set` | Restores the MTK EngineerMode apps (**change #2**). |
| 4 | `exclude isolated apps from gralloc tmpfs grant` | sepolicy build fix hit along the way. |
| 5 | `META snWriter backup timeout — root cause + APEXFIX state (WIP)` | Investigation state: inline boot-HAL service for META + diagnostics. |
| 6 | **`META — run perform_apex_config after apexd-bootstrap`** | **The fix (change #1).** Restores the A16 contract in `meta_init.system.rc`, plus a belt-and-suspenders `restorecon /bootstrap-apex/apex-info-list.xml`. Also replaces a dead A13 `exec /system/bin/bootstrap/linkerconfig` (that binary moved into the runtime APEX on A15/16) with the A16 stub-write pattern, and restores `keystore2` + `mount_all --late`, which this fix makes viable. |
| 7 | `factory mode — port the A16 perform_apex_config fix from META` | **Change #3.** `factory_init.rc` has the identical latent bug; same fix applied. **Not yet tested in factory mode.** |
| 8 | `add PriFactoryTest factory hardware test app` | Extracts the ODM APK as a platform-signed privileged system app and grants its declared privileged permissions. |
| 9 | `PriFactoryTest factory language defaults` | Adds `ro.odm.factory_default_lang_en=1` and `ro.odm.del_lan_switch_btn=1`: English startup plus the APK's built-in English/Simplified-Chinese switch. |
| 10 | `allow PriFactoryTest to read language properties` | Gives the two exact properties a dedicated SELinux type and allows `system_app` to read it. Without this, Android labels arbitrary `ro.odm.*` keys `vendor_default_prop`; the APK receives empty values, falls back to Chinese, and hides the switch. |

### `system_sepolicy` — 2 commits (upstream candidate)

```
/bootstrap-apex/apex-info-list\.xml  u:object_r:apex_info_file:s0
```

One line in `private/file_contexts`. A15/16 `apexd` writes the bootstrap manifest
to `/bootstrap-apex/apex-info-list.xml`, but upstream `file_contexts` only labels
the `/apex/` paths — so the file inherits `apex_mnt_dir` and stays unreadable to
the service managers until something relabels it. This defines the label that
`perform_apex_config`'s restorecon then applies.

**This is not BraX3-specific.** Any A15/16 device running a non-standard init
sequence around `apexd-bootstrap` (META, factory, recovery-like environments) can
hit it — which is why it belongs upstream in iodé, and arguably in AOSP (`apexd`
could restorecon the bootstrap manifest itself, as it did on A13).

The follow-up commit adds `/bootstrap-apex/apex-info-list.xml` to
`contexts/file_contexts_test_data`. Android 16's `plat_file_contexts_data_test`
requires a test-data match for every platform file-context rule; without it a
clean `m selinux_policy` build fails even though the runtime label is correct.

### `frameworks_base` — 2 commits (required for the factory app)

| # | Commit | What |
|---|---|---|
| 1 | `add PriFactoryTest NVRAM compatibility API` | Provides `com.pri.utils.NvramUtils`, the **only** framework-level `com.pri.*` class the APK needs (the other ~230 `com.pri.*` refs are its own classes, inside the APK). The ODM added this to `framework.jar`; iodé lacks it, so the app died with `NoClassDefFoundError` the moment `FactoryTestApplication` loaded. Implemented as a Java-only HIDL client over the existing `vendor.mediatek.hardware.nvram@1.0` prebuilt — no native replacement, path allowlist, offset/length validation. |
| 2 | `enable the ODM factory test app at systemReady` | Ports the ODM's `PhoneWindowManager` `setApplicationEnabledSetting(ENABLED)` hook. Required because the APK's `<application android:enabled="false">` is a **hardcoded literal** (no RRO can override it) and iodé has no `config_forceEnabledComponents`. Hardened: early-out when already reachable, `getPackageInfo` guard (clean no-op when the app isn't shipped — the BSP version throws), try/catch around `systemReady`. |

Both land on the **boot classpath**: `NvramUtils` in `framework.jar`
(`classes6.dex`), the enable hook in `services.jar` (`classes2.dex`) — verified
in the packed images before flashing.

---

# How to test

## Prerequisites

**Build and flash the images**

```bash
# in the iodé BraX3 tree, with both patch sets applied (see "Applying" below)
source build/envsetup.sh
lunch lineage_brax3-bp4a-userdebug
m vendorimage systemextimage superimage
```

Both fixes ride inside `super.img` (system_ext + vendor). **No boot-chain images
change**, so a `super`-only flash is sufficient for all three tests.

Flash with **SP Flash Tool V6.2404**, "Download Only", `super` checked. Power the
phone fully **off**, press Download, then plug in USB.

**Sanity check after boot** (all three tests depend on this):

```bash
adb shell getenforce
# -> Enforcing

adb shell ls -Z /bootstrap-apex/apex-info-list.xml
# -> u:object_r:apex_info_file:s0     (NOT apex_mnt_dir)

adb shell "logcat -b all -d | grep -c 'NULL VINTF'"
# -> 0
```

If the label is wrong or NULL VINTF appears, the fix is not active — stop here.

---

## Test A — snWriter provisioning (the main fix)

**Tool:** Coosea SN Writer **V10.2324.0.18** (`SN_Writer.exe`). See
[Tooling](#tooling) — the tool is not in this repo.

**Configuration** (System Config dialog):

| Setting | Value |
|---|---|
| ComPort | USB VCOM |
| Target Type | Smart Phone |
| Country | EU |
| IMEI | checked |
| Load AP DB from DUT | checked |
| Load Modem DB from DUT | checked |
| AP_DB (fallback) | `databases/apdb-P27/APDB_MT6835___W2421` |
| MDDB1 (fallback) | `databases/mddb-P18/MDDB.META.ODB_MT6835_S00_MOLY_NR17_R1_MP3_RC_MP_V19_10_P18.XML.GZ` |

Both databases are included in this repo under **`databases/`** — see
[Databases](#databases). "From DUT" is preferred (the device serves the matching
pair itself); the bundled files are the fallback when it can't.

**Procedure**

> ⚠️ `adb reboot meta` does **not** work on this device — it just reboots to the
> normal OS. META is only reachable through snWriter's preloader handshake:

1. Power the phone **completely off**.
2. Click **Start** in snWriter *first*.
3. *Then* plug in the USB cable, so the tool catches the preloader port.
4. Let it run to completion.

**Expected result — PASS**

- Large green **`PASS`**, `Total: 1  Pass: 1  Fail: 0`, "All Operate successfully!!"
- The whole run completes in seconds; the backup step returns in roughly **0.2 s**.

**Failure signature this fix removes**

- Progress reaches the final step, then stalls for exactly **15 s** → red **FAIL**.
- Device-side (`adb logcat` after returning to normal boot, or a META capture):
  `client is NULL`, then a `SIGSEGV` / `fault addr 0x0` tombstone in
  `FtModUtility::exec`, and `Could not register service ... INVram`.

**Verify the IMEI persisted**

```bash
adb shell "service call iphonesubinfo 1"   # or dial *#06#
adb reboot     # then re-check: it must survive the reboot
```

---

## Test B — EngineerMode

**Procedure**

```bash
# launch the MTK EngineerMode app
adb shell am start -n com.mediatek.engineermode/.EngineerMode
```

Or dial **`*#*#3646633#*#*`** on the dialer.

**Expected result**

- The EngineerMode UI opens with its tab set (Telephony / Connectivity /
  Hardware Testing / Location / Log and Debugging …).
- Sub-menus open without force-closing — in particular anything touching
  **Telephony**, which needs the ATCI/`meta_tst` blobs restored by commits 1–2.

**Failure signature before the fix**

- `Activity class ... does not exist` (app absent), or the app opens and
  immediately crashes when entering a telephony menu (missing ATCI libs).

---

## Test C — Factory mode (needs verification)

➖ **Defensive only — this bootloader never selects `factory_init.rc`.**
Verified in LK source and against the shipping image:

- `mt_boot.c` defines `FACTORY_INIT_RC = "/vendor/etc/init/hw/factory_init.rc"`
  but **never uses it**; the `FACTORY_BOOT` / `ATE_FACTORY_BOOT` path falls through
  to `androidboot.init_rc=` **`meta_init.system.rc`**.
- `strings lk.img | grep init_rc` on the shipping `lk.img` yields exactly one
  match: `…/meta_init.system.rc`. `factory_init.rc` appears nowhere.

**So native factory boot runs `meta_init.system.rc` — already covered by change
#1.** Patch 7 keeps the two files in sync and is correct *if* a future LK ever
selects `factory_init.rc`, but it is inert on this bootloader. Native factory
boot is entered by a preloader handshake (`FACTFACT`, like snWriter's `METAMETA`),
not a key combo.

For the **factory test app** — which is what "factory mode" means in practice
here — see [Test D](#test-d--prifactorytest-android-factory-app); that path is
verified working.

**Historical note (what this patch was written for):** the same `NULL VINTF`
cascade would hit `factory_init.rc` if it were used — it had the identical
A13-derived defects (no `perform_apex_config`, plus a dead
`exec /system/bin/bootstrap/linkerconfig`), and the symptom would differ from
META's: `mount_all --late` blocking in `vold` waiting for `IBootControl`.

**Procedure**

Enter factory mode by the ODM's normal route (factory key combo / the factory
test app, per the ODM SOP).

**Expected result**

- Factory mode boots to its test menu instead of stalling.
- With adb available:

```bash
adb shell ls -Z /bootstrap-apex/apex-info-list.xml   # -> apex_info_file
adb shell "logcat -b all -d | grep -c 'NULL VINTF'"  # -> 0
adb shell "logcat -b all -d | grep -iE 'IBootControl|early_hal'"   # HAL registered
adb shell "dmesg | grep -i 'mount_all'"              # completes, no vold block
```

- Run the ODM's factory test items (RF, camera, sensors, touch) and confirm they
  execute rather than hanging at startup.

**If it still fails**, capture and attach:

```bash
adb shell "logcat -b all -d" > factory-logcat.txt
adb shell dmesg               > factory-dmesg.txt
adb shell "ls -Z /bootstrap-apex/"
```

---

## Test D — PriFactoryTest Android factory app

This is separate from MediaTek's native factory boot in Test C. Test C repairs
the alternate `factory_init.rc` boot environment. PriFactoryTest is an ODM
Android APK (`com.pri.factorytest`) that runs after Android's framework is up.

The APK already contains default-English and `zh-rCN` resources. It does not
follow the system locale at startup: it reads two ODM properties instead.

```text
ro.odm.factory_default_lang_en=1  -> start in English
ro.odm.del_lan_switch_btn=1       -> show the English/Chinese switch
```

Both values are in the generated ODM build properties. They also need the exact
SELinux property contexts included in device commit 10. Otherwise PriFactoryTest
runs as `system_app`, receives empty values, switches its configuration from
`en_US` to `zh_CN`, and logs:

```text
Access denied finding property "ro.odm.del_lan_switch_btn"
Access denied finding property "ro.odm.factory_default_lang_en"
```

### Manual launch test

The proprietary manifest deliberately sets `android:enabled="false"` on the
application, and all three launcher aliases are disabled by APK boolean
resources. This keeps the broad factory surface unavailable during normal
retail use.

> **Since the enable hook was ported** (see [below](#the-enable-hook-is-now-ported-2026-07-23--verified-on-device)),
> the package is enabled automatically at boot and `*#*#8804#*#*` just works —
> the `pm enable` below is **no longer required**. It is kept for reference and
> for bisecting against builds without `patches/frameworks_base/0002`.

```bash
adb shell pm enable --user 0 com.pri.factorytest   # no longer needed

# Interactive grid of individual hardware tests
adb shell am start -W \
  -n com.pri.factorytest/.PrizeFactoryTestListActivity

# Automatic sequence; immediately enters its first enabled item (normally LCD)
adb shell am start -W \
  -n com.pri.factorytest/.PrizeFactoryTestActivity
```

Expected result after flashing the new policy:

- the interactive grid is visible and its translated labels are English;
- the main factory UI retains the built-in English/Simplified-Chinese switch;
- both activities remain alive with no `FATAL EXCEPTION`;
- logcat contains no access-denied lines for the two language properties.

```bash
adb logcat -d | grep -F 'factory_default_lang_en'
adb logcat -d | grep -F 'del_lan_switch_btn'
# both commands should produce no "Access denied finding property" line
```

Restore the retail-safe package state after manual testing:

```bash
adb shell am force-stop com.pri.factorytest
adb shell pm disable-user --user 0 com.pri.factorytest
```

### What the ODM BSP actually does: enable at boot, launch by trigger

The ODM BSP does **not** contain an automatic factory-boot launcher for
PriFactoryTest. The previously proposed boot-mode coordinator was speculative,
not source-derived.

Instead, the ODM patches `PhoneWindowManager.systemReady()` to enable the
manifest-disabled application after Package Manager is available:

```java
// frameworks/base/services/core/java/com/android/server/policy/PhoneWindowManager.java
if (!isFactoryTestActivitySupport(mContext)) {
    enableFactoryTestApplication(mContext);
}

private static boolean isFactoryTestActivitySupport(Context context) {
    PackageManager pm = context.getPackageManager();
    Intent intent = new Intent().setClassName(
            "com.pri.factorytest",
            "com.pri.factorytest.PrizeFactoryTestActivity");
    List<ResolveInfo> list =
            pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
    return list.size() > 0;
}

private static void enableFactoryTestApplication(Context context) {
    final PackageManager pm = context.getPackageManager();
    pm.setApplicationEnabledSetting(
            "com.pri.factorytest",
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP);
}
```

This hook enables the package; it does not start an activity. For this ODM
configuration, the normal launch flow is:

```text
*#*#8804#*#*
  -> TelephonyManager.sendDialerSpecialCode("8804")
  -> com.pri.factorytest.GoogleDialerReceiver
  -> FactoryMainTestHostHandle
  -> PrizeFactoryTestActivity (isAutoTest=true)
```

Source and runtime verification also found:

- `factory_init.rc` contains no `am start` or PriFactoryTest component;
- PriFactoryTest's `BOOT_COMPLETED` receiver performs initialization and may
  resume an NV-requested aging test, but does not launch the main factory UI;
- the APK declares no activity for Android's legacy
  `android.intent.action.FACTORY_TEST` automatic-start mechanism;
- the ODM button-policy changes only pass keys to PriFactoryTest while it is
  already foreground; they do not form a launch combination.

### The enable hook is now ported (2026-07-23) — verified on device

The iodé branch **now includes** the `PhoneWindowManager` enable hook
(`patches/frameworks_base/0002`), so the manual `pm enable` step above is **no
longer required**. Why a framework patch was the only option:

- the APK sets `<application android:enabled="false">` as a **hardcoded literal**,
  so an RRO/resource overlay **cannot** override it;
- iodé's framework has **no** `config_forceEnabledComponents` mechanism;
- so the ODM's own approach — enable the package at `systemReady()` — is the
  correct route.

Hardened over the ODM version: it early-outs when the app is already reachable,
guards with `getPackageInfo` so it is a clean **no-op on builds that don't ship
the app** (the BSP version would throw `IllegalArgumentException`), and wraps the
call in try/catch so it can never destabilise `systemReady()`.

Verified on a clean flash with **nothing done by hand**:

```bash
adb shell "dumpsys package com.pri.factorytest | grep -m1 -oE 'enabled=[0-9]'"
# -> enabled=1          (explicitly ENABLED; a fresh flash defaults to 0)
adb shell "pm list packages -d | grep -c factorytest"
# -> 0                  (no longer in the disabled list)
```

then dialling `*#*#8804#*#*` opens the factory app, and
`am start -n com.pri.factorytest/.PrizeFactoryTestActivity` runs a test
(observed sitting on `.LCD.LCD`) with no `FATAL EXCEPTION` and a working NVRAM
path (`NVM_…Check Success`).

**The launcher aliases stay disabled on purpose.** Enabling the *application*
does not enable the three aliases (their own `bool/is_*_launcher_enabled` are
`false`), so there is still **no app-drawer icon** — entry remains the dial code.
This matches ODM BSP behaviour exactly and keeps the retail surface hidden.

---

# Applying

Against an iodé v7.6 BraX3 tree:

```bash
cd device/brax/brax3 && git am /path/to/patches/device_brax_brax3/*.patch
cd system/sepolicy   && git am /path/to/patches/system_sepolicy/*.patch
```

Or fetch the branches directly:

```bash
git -C device/brax/brax3 fetch <this-repo> device_brax_brax3
git -C system/sepolicy   fetch <this-repo> system_sepolicy
```

**Both parts are required.** The sepolicy commit defines the label; the device
commit runs the restorecon that applies it. Either alone does nothing.

# Databases

`databases/` holds the two MediaTek databases snWriter needs. They are firmware-
matched metadata (no keys, no credentials, no IMEI data) and **must** match the
build on the device:

| File | What | Matches |
|---|---|---|
| `databases/apdb-P27/APDB_MT6835___W2421` | AP database | AP build **P27** (verified byte-identical to the ODM's, and to `/vendor/etc/apdb` on the BSP device) |
| `databases/apdb-P27/APDB_MT6835___W2421_ENUM` | AP enum table | companion to the above |
| `databases/mddb-P18/MDDB.META.ODB_...V19_10_P18.XML.GZ` | Modem NVRAM database | modem **P18** = `MOLY.NR17.R1.MP3.RC.MP.V19.10.P18` (check with `adb shell getprop gsm.version.baseband`) |
| `databases/mddb-P18/md1_file_map.log` | modem file map | pulled alongside the MDDB |

> **Version matching is not optional.** snWriter needs the modem DB to match the
> running modem firmware exactly. A mismatched MDDB is its own separate failure
> mode (unrelated to the fixes here). Note the modem DB is an **ODB `.XML.GZ`**,
> not the `.EDB` you may expect — searching for `*.EDB` will find nothing.
>
> Preferred setup is **"Load AP DB from DUT" + "Load Modem DB from DUT"**, where
> the device serves the matching pair itself (the BSP ships them at
> `/vendor/etc/apdb` and `/data/vendor_de/meta/mddb`). The bundled copies here are
> the fallback for when from-DUT is unavailable.

# Tooling

The **Coosea SN Writer Tool v1.2324.0.18** (`SN_Writer.exe`) is *not* included.
It is MediaTek/Coosea proprietary, and the distribution ships with live RKP
credentials (`RKP/cred.json`), serial/IMEI provisioning data (`SNDATA`), and MTK
Serial Link Authentication components (`SLA_Challenge.dll`) — none of which
belong in version control. Obtain it from the ODM or the internal share, then use
the configuration table in [Test A](#test-a--snwriter-provisioning-the-main-fix)
together with the databases above.

Also needed: **SP Flash Tool V6.2404** for flashing.

---

*Root-caused and fixed 2026-07-18/19 on device `BYHQ7TFQHQI7PR7P`
(iodé 7.6, BP4A.251205.006, Android 16).*
