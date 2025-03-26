#
# Copyright (C) 2021-2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from salami device
$(call inherit-product, device/brax/k6835v1_64/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_k6835v1_64
PRODUCT_DEVICE := k6835v1_64
PRODUCT_MANUFACTURER := Brax
PRODUCT_BRAND := Brax
PRODUCT_MODEL := k6835v1_64

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=brax/k6835_v1/k6835_v1:15/AP4A.250205.002/:userdebug/release-keys \
    DeviceProduct=k6835v1_64
