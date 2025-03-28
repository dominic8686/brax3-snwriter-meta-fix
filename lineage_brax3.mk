#
# Copyright (C) 2021-2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from brax3 device
$(call inherit-product, device/brax/brax3/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_brax3
PRODUCT_DEVICE := brax3
PRODUCT_MANUFACTURER := BraX
PRODUCT_BRAND := BraX
PRODUCT_MODEL := BraX3

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=brax/brax3/k6835v1_64:15/AP4A.250205.002/:userdebug/release-keys \
    DeviceName=BraX3 \
    DeviceProduct=BraX3 \
    SystemDevice=k6835v1_64 \
    SystemName=BraX3
