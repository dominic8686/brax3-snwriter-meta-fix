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

PRODUCT_NAME := lineage_k6835v1_64
PRODUCT_DEVICE := k6835v1_64
PRODUCT_MANUFACTURER := alps
PRODUCT_BRAND := alps
PRODUCT_MODEL := k6835v1_64

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=alps/vext_k6835v1_64/k6835v1_64:14/UP1A.231005.007/:userdebug/release-keys \
    DeviceProduct=k6835v1_64
