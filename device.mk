
SELINUX_IGNORE_NEVERALLOWS := true

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

PRODUCT_PACKAGES += \
    com.android.hardware.boot \
    android.hardware.boot-service.default_recovery

PRODUCT_PACKAGES += \
    create_pl_dev \
    create_pl_dev.recovery

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

PRODUCT_PACKAGES += \
    MtkInCallService

PRODUCT_PACKAGES += \
    audio.bluetooth.default \
    android.hardware.bluetooth.audio-impl

# Boot animation
TARGET_SCREEN_HEIGHT := 2376
TARGET_SCREEN_WIDTH := 1080

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

PRODUCT_PACKAGES += \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.mediatek \
    android.hardware.health-service.mediatek-recovery

# HIDL
PRODUCT_PACKAGES += \
    libhidltransport \
    libhidltransport.vendor \
    libhwbinder.vendor \
    android.hidl.allocator@1.0.vendor

# Init
PRODUCT_PACKAGES += \
    fstab.emmc \
    fstab.emmc.vendor_ramdisk \
    fstab.mt6835 \
    fstab.mt6835.vendor_ramdisk \
    init.mt6835.rc \
    init.project.rc

# Recovery files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.emmc:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.emmc \
    $(LOCAL_PATH)/init/fstab.mt6835:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6835 \
    $(LOCAL_PATH)/init/init.recovery.mt6835.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6835.rc

PRODUCT_COPY_FILES += \
    device/alps/brax3-kernel/vendor_boot/modules.load.recovery:$(TARGET_COPY_OUT_RECOVERY)/root/lib/modules/modules.load.recovery

# Shipping API level
PRODUCT_FULL_TREBLE_OVERRIDE := true
PRODUCT_USE_VNDK_OVERRIDE := true

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/mediatek

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb@1.3.vendor \
    android.hardware.usb.gadget@1.1.vendor

# Wi-Fi
PRODUCT_PACKAGES += \
    wpa_supplicant \
    hostapd \
    libwifi-hal-wrapper \
    android.hardware.wifi-service

PRODUCT_PACKAGES += \
    android.hardware.tetheroffload.config@1.0.vendor \
    android.hardware.tetheroffload.control@1.0.vendor \
    android.hardware.tetheroffload.control@1.1.vendor \
    libnetutils.vendor


# Inherit from the proprietary files makefile.
$(call inherit-product, vendor/alps/brax3/brax3-vendor.mk)
