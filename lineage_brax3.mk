#
# Copyright (C) 2021-2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from salami device
$(call inherit-product, device/alps/brax3/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_brax3
PRODUCT_DEVICE := brax3
PRODUCT_MANUFACTURER := Alps
PRODUCT_BRAND := Brax
PRODUCT_MODEL := Brax 3

#PRODUCT_GMS_CLIENTID_BASE := android-oneplus

PRODUCT_GMS_CLIENTID_BASE := android-alcatel

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=alps/sys_mssi_64_ww_armv82/mssi_64_ww_armv82:14/AP2A.240905.003/mp1V654:user/release-keys \
    DeviceProduct=brax3
