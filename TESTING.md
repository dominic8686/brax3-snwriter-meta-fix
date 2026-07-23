# How to test the BraX3 patches (snWriter, EngineerMode, Factory app)

This is the **reproducible-from-clean** procedure. Read the pitfalls in §5 first —
they are the reasons a patch can look "verified" and still fail on a clean re-test.

## 0. What is being tested

| Patch | Repo / branch | What it should fix | Verifiable how |
|---|---|---|---|
| META `perform_apex_config` | `device/brax/brax3` (snWriter fix commit) + `system/sepolicy` `b2cffb30d` | snWriter backup no longer times out under enforcing | **Only** by an actual snWriter run (§2) |
| EngineerMode blobs | `device/brax/brax3` | MTK EngineerMode app present/opens | `am start` / secret code (§3) |
| PriFactoryTest + NvramUtils | `device/brax/brax3` + `frameworks/base` (NvramUtils) | Factory HW-test app launches without the `NvramUtils` crash | `am start` + logcat (§4) |

All three must be built into ONE image and flashed together; they are on three
separate git branches (one per repo).

## 1. Build (from clean)

Branches to have checked out simultaneously:
- `system/sepolicy` → the `apex_info_file` label commit
- `device/brax/brax3` → the branch with snWriter fix + EngineerMode + PriFactoryTest
- `frameworks/base` → the branch with `com/pri/utils/NvramUtils.java`

```bash
# in the docker builder (brax-builder:20.04, tree->/tree, uid 1000)
source build/envsetup.sh
lunch lineage_brax3-bp4a-userdebug
m installclean                 # <-- REQUIRED: clears staged installed files so a
                               #     stale artifact can't produce a false PASS
m framework systemimage vendorimage superimage
```

**Compilation is itself test #1.** If `frameworks/base` fails to build (e.g. the
`vendor.mediatek.hardware.nvram-V1.0-java` HIDL stub module is missing, so
`NvramUtils.java` can't resolve `vendor.mediatek.hardware.nvram.V1_0.INvram`),
STOP — nothing else can be tested. Confirm the stub module exists and is on
`framework-internal-utils` static_libs.

**Verify the patch is actually in the image before flashing** (guards against the
"built the wrong thing" class of false result):

```bash
R=out/target/product/brax3; H=out/host/linux-x86/bin
simg2img $R/super.img super.raw
lpunpack -p system_a -p vendor_a super.raw .
fsck.erofs --extract=sys system_a.img ; fsck.erofs --extract=ven vendor_a.img
# META fix present in the file that META boot actually loads:
grep -c 'perform_apex_config' sys/system_ext/etc/init/hw/meta_init.system.rc   # expect >=1 command line
# NvramUtils compiled into framework.jar:
unzip -l sys/system/framework/framework.jar | grep -c com/pri/utils/NvramUtils   # expect 1
# apex label rule present:
grep -c 'bootstrap-apex/apex-info-list' ven/etc/selinux/*   # or plat_file_contexts in system
# factory app present:
ls sys/system/priv-app/PriFactoryTest/PriFactoryTest.apk
```

## 2. Test A — snWriter (the headline)

**snWriter CANNOT be tested from adb.** It is a Windows tool that boots the phone
into a separate META Android via a preloader handshake. You must run it.

**Flash first — clean, all partitions:**
- Load `MT6835_Android_scatter.txt`, SP Flash Tool "Download Only" with **all**
  partitions incl. `userdata` (clean wipe) and `tee` (iodé stock — undo any
  earlier tee experiment). NOT "Format All" (that erases NVRAM/IMEI).

**Run snWriter** (Coosea V10.2324): power phone fully OFF → click Start/Download in
snWriter → plug USB. Config: EU, Load AP DB + Modem DB **from DUT** (or local
APDB P27 / MDDB P18).

**Result = the tool's verdict:**
- **PASS (green, ~0.2 s backup)** → fix works.
- **FAIL, 15 s timeout on `REQ_BackupNvram2BinRegion` / `SP_META_SetCleanBootFlag_r`**
  → fix did NOT work. Capture §2.1.

### 2.1 Capturing the META boot (do this REGARDLESS of pass/fail)

The phone reboots to normal Android after snWriter. The **previous** boot in
pstore IS the META boot — grab it immediately:

```bash
adb root                       # needed to read pstore
adb shell 'cat /sys/fs/pstore/console-ramoops-0' > meta-boot-kmsg.txt
grep -iE 'apex_mnt_dir|apex-info-list|NULL VINTF|avc.*denied|meta_tst|SIGSEGV|SET_CLEAN_BOOT|nvram' meta-boot-kmsg.txt
```

Interpretation:
- `avc: denied ... apex-info-list.xml ... tcontext=...apex_mnt_dir` OR `NULL VINTF`
  → the META fix did NOT take: the manifest is still mislabeled in META. (Do not
  trust a normal-boot `ls -Z` — normal boot always relabels it; only META matters.)
- `meta_tst ... SIGSEGV` / `FtModUtility::exec` → the NVRAM HIDL service never
  registered → same root cause not fixed.
- Clean (no such lines) + snWriter PASS → fixed.

Also keep the snWriter PC log (e.g. `C:\SNWriter_LOG\<timestamp>`) — it has the
per-step timings.

## 3. Test B — EngineerMode

```bash
adb shell pm list packages | grep -iE 'engineermode|mtk.*engineer'
adb shell am start -n com.mediatek.engineermode/.EngineerMode   # or dial *#*#3646633#*#*
adb shell 'logcat -b crash -d | tail -20'                       # expect no crash
```
PASS = the EngineerMode menu opens.

## 4. Test C — Factory app (PriFactoryTest)

```bash
adb shell pm path com.pri.factorytest                            # installed?
adb shell 'unzip -l /system/framework/framework.jar | grep -c com/pri/utils/NvramUtils'  # 1 = NvramUtils present
adb logcat -c
adb shell am start -n com.pri.factorytest/.PrizeFactoryTestLauncher
sleep 4
adb shell 'pidof com.pri.factorytest && echo RUNNING || echo DEAD'
adb shell 'logcat -b crash -d | tail -30'
```
- Menu opens, process RUNNING, no `NoClassDefFoundError: com.pri.utils.NvramUtils`
  → NvramUtils port works.
- Still `NoClassDefFoundError: NvramUtils` → framework port not in the flashed
  image (rebuild/reflash `framework`/`systemimage`).
- Menu opens but individual test screens crash / `avc: denied` for `system_app`
  on sysfs nodes → expected; needs the factory SELinux grants (separate work).

## 5. Pitfalls that cause false results (READ THIS)

1. **Normal-boot label check is meaningless for the META fix.** Normal `init.rc`
   runs `perform_apex_config` unconditionally, so `/bootstrap-apex/apex-info-list.xml`
   is `apex_info_file` on normal boot *with or without* the patch. The patch only
   changes **META** boot. Verify via §2.1, not `adb shell ls -Z` on normal boot.
2. **Accumulated device state.** A green PASS on a device that has had many prior
   flashes / a swapped `tee.img` / dirty userdata is not a clean result. Always
   full-flash + wipe userdata + stock tee before a trust-worthy snWriter test.
3. **Stale build artifacts.** Skipping `m installclean` can leave an old
   `meta_init.system.rc` / `framework.jar` in the staging dir. Always verify the
   patch is in the packed `super` (§1) before flashing.
4. **Mixed vendor/system.** Building only `systemimage` leaves an older `vendor`;
   flash a matched set. Check `ro.system.build.date` vs `ro.vendor.build.date`.
5. **adb root for pstore.** `/sys/fs/pstore` is unreadable without `adb root`; a
   clean flash may reset adb-root state.

## 6. One-line summary of a valid PASS

Full clean flash of a `super` verified to contain all four artifacts (§1) →
snWriter shows green PASS under enforcing → META pstore log (§2.1) has no
`apex_mnt_dir`/`NULL VINTF`/`meta_tst SIGSEGV`. Anything less is not a pass.
