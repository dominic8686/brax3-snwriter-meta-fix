# BraX3 (MT6835) — snWriter / META provisioning fixes for iodéOS

Changes that make **MediaTek SN Writer (Coosea V10.2324, IMEI/serial factory
provisioning) pass GREEN** on the iodé/LineageOS BraX3 build **under SELinux
enforcing**. Verified on device 2026-07-19: **PASS, Pass:1 Fail:0, "All Operate
successfully!!"** — reproduced twice (fix build + clean canonical rebuild).

## Repository layout

| Branch | Content |
|---|---|
| `main` | This README + the patch series under `patches/` |
| `device_brax_brax3` | Full history of `device/brax/brax3` with the 7-commit series (based on iodé v7.6) |
| `system_sepolicy` | iodé `system/sepolicy` with the 1-line labeling prerequisite (to be upstreamed to iodé) |

## The problem

On the iodé build, snWriter wrote and verified the IMEI correctly, but its final
step — `REQ_BackupNvram2BinRegion` / `SP_META_SetCleanBootFlag_r` — timed out
after exactly 15 s, so the tool reported **FAIL**. The factory line requires a
green PASS. The stock MTK BSP (Android 13) passed; iodé (Android 16) did not.
Permissive SELinux made it pass, enforcing made it fail — but no AVC was ever
logged.

## Root cause (the interesting part)

An **Android 13 → 16 porting gap in MediaTek's META-mode init**:

1. META mode boots with a dedicated init script
   (`androidboot.init_rc=/system_ext/etc/init/hw/meta_init.system.rc`), derived
   from MTK's Android-13 BSP.
2. On A13, `apexd` itself restorecons the `apex-info-list.xml` it writes
   (`RestoreconPath` at the end of `EmitApexInfoList`). On A16 that
   responsibility moved: normal `init.rc` runs **`perform_apex_config`**
   immediately after `exec_start apexd-bootstrap`, and *that* restorecons the
   manifest (and generates the linker configuration).
3. The A13-derived META init never ran `perform_apex_config`. Result: in META
   the manifest kept its tmpfs parent label `apex_mnt_dir`;
   `servicemanager`/`hwservicemanager` are only allowed to read
   `apex_info_file` → **"NULL VINTF MANIFEST"** → **no HAL could register**,
   including `vendor.mediatek.hardware.nvram@1.1::INvram`.
4. When snWriter sent `FT_UTILCMD_SET_CLEAN_BOOT_FLAG`, MTK's `meta_tst`
   called `INvram::getService()`, got **null**, logged `client is NULL` — and
   then dereferenced it anyway (`client->BackupToBinRegion_All_Exx`) →
   **SIGSEGV**. The PC waited its configured 15 s timeout on a dead process.
5. IMEI writing itself never broke because it uses an in-process editor
   (`META_Editor_WriteFile_OP`), not the HIDL service — which is why only the
   backup failed.

Permissive "fixed" it because the mislabeled file could still be read, so the
HAL registered and the backup completed (~214 ms).

## The fixes

### device/brax/brax3 (branch `device_brax_brax3`, 7 commits)

| # | Commit | What |
|---|---|---|
| 1 | `re-enable MTK ATCI + meta_tst provisioning blobs` | The open-source blob scrub had removed ATCI/meta_tst — nothing serviced META. Prerequisite. |
| 2 | `pull in ATCI/meta_tst transitive vendor libs` | Their transitive lib deps. |
| 3 | `enable EngineerMode app set` | Restores MTK EngineerMode (confirmed working). |
| 4 | `exclude isolated apps from gralloc tmpfs grant` | sepolicy build fix encountered on the way. |
| 5 | `META snWriter backup timeout - root cause + APEXFIX state (WIP)` | Investigation state: inline boot-HAL service for META, diagnostics. |
| 6 | **`META - run perform_apex_config after apexd-bootstrap`** | **The fix.** Restores the A16 contract in `meta_init.system.rc` (+ belt-and-suspenders `restorecon /bootstrap-apex/apex-info-list.xml`). Also replaces a dead A13 `exec /system/bin/bootstrap/linkerconfig` with the A16 stub-write pattern, and restores keystore2 + `mount_all --late`, which the fix makes viable. **Verified: snWriter GREEN PASS under enforcing.** |
| 7 | `factory mode - port the A16 perform_apex_config fix from META` | Same latent bug in `factory_init.rc`; identical fix. Untested in factory mode (mirrors the proven META state). |

### system/sepolicy (branch `system_sepolicy`, 1 commit — **upstream candidate for iodé**)

```
/bootstrap-apex/apex-info-list\.xml  u:object_r:apex_info_file:s0
```

One line in `private/file_contexts`. A15/16 `apexd` writes the bootstrap
manifest to `/bootstrap-apex/apex-info-list.xml`, but upstream file_contexts
only labels the `/apex/` paths — so the file is created as `apex_mnt_dir` and
stays unreadable to service managers until something relabels it. This defines
the label that `perform_apex_config`'s restorecon applies. **This is not
BraX3-specific** — any A15/16 device that runs a non-standard init sequence
(META/factory mode, recovery-like environments) around apexd-bootstrap can hit
it, which is why it belongs upstream (iodé, and arguably AOSP: `apexd` could
restorecon the bootstrap manifest itself like A13 did).

## Verification

- snWriter V10.2324.0.18, EU config, APDB P27 / MDDB P18 (from DUT):
  **GREEN PASS under enforcing**, twice (initial fix build + clean rebuild).
- IMEI written and persisting across reboots.
- Normal boot: `/bootstrap-apex/apex-info-list.xml` = `apex_info_file`,
  zero `NULL VINTF MANIFEST`, all HALs registered, `getenforce` = Enforcing.
- KeyMint (TEE), Gatekeeper, FBE unaffected.

## Applying

With the iodé v7.6 BraX3 tree:

```bash
cd device/brax/brax3   && git am <this-repo>/patches/device_brax_brax3/*.patch
cd system/sepolicy     && git am <this-repo>/patches/system_sepolicy/*.patch
m vendorimage systemextimage superimage
```

Both fixes ride in `super.img` (system_ext + vendor); no boot-chain images
change.

---
*Root-caused and fixed 2026-07-18/19. The final crash-not-hang insight came
from adversarial review of the retained failure capture — the kernel-stack
"hang" being observed belonged to the auto-restarted meta_tst, not the
original crashed one.*
