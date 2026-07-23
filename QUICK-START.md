# Quick start — get the source and apply the patches

The two essential steps to get a patched tree ready to build.

For the full end-to-end procedure (prerequisites, build, flashing, and verification) see
[README.md](README.md) and the rest README files in this directory.


---

## 1. Get the source

Checkout the latest IodeOS source code (currently, the latest branch is  **v7.6**):

```bash
repo init -u https://git.os-source.co/Brax3_IodeOs/manifests_android.git -b <branch>
repo sync -c -j8
```

---

## 2. Apply the patches 

```bash
cd device/brax/brax3     && git am /path/to/patches/device_brax_brax3/*.patch
cd hardware/mediatek     && git am /path/to/patches/hardware_mediatek/*.patch
cd frameworks/base       && git am /path/to/patches/frameworks_base/*.patch
cd system/sepolicy       && git am /path/to/patches/system_sepolicy/*.patch

cd vendor/brax/brax3     && git am /path/to/patches/vendor_brax_brax3/*.patch
```
The patches can be obtained from the **main** branch of this repo ( **patches** sub-directory)

---

## 3. Build the source

```bash
. build/envsetup.sh
lunch lineage_brax3-bp4a-userdebug
make superimage otapackage
```

## 4. Write SN/IMEI using SN Writer tool

Use Mediatek SN Writer Tool V10.2324.0.18 to write SN/IMEI

**Note:** In System Config Menu, unselect 'IMEI CheckSum' if selected.

The other configurations and details can be found in [SNWRITER.md](SNWRITER.md).
