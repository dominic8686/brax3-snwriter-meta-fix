# Copyright Statement:
#
# This software/firmware and related documentation ("MediaTek Software") are
# protected under relevant copyright laws. The information contained herein
# is confidential and proprietary to MediaTek Inc. and/or its licensors.
# Without the prior written permission of MediaTek inc. and/or its licensors,
# any reproduction, modification, use or disclosure of MediaTek Software,
# and information contained herein, in whole or in part, shall be strictly prohibited.

# MediaTek Inc. (C) 2010. All rights reserved.
#
# BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
# THAT THE SOFTWARE/FIRMWARE AND ITS DOCUMENTATIONS ("MEDIATEK SOFTWARE")
# RECEIVED FROM MEDIATEK AND/OR ITS REPRESENTATIVES ARE PROVIDED TO RECEIVER ON
# AN "AS-IS" BASIS ONLY. MEDIATEK EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NONINFRINGEMENT.
# NEITHER DOES MEDIATEK PROVIDE ANY WARRANTY WHATSOEVER WITH RESPECT TO THE
# SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY, INCORPORATED IN, OR
# SUPPLIED WITH THE MEDIATEK SOFTWARE, AND RECEIVER AGREES TO LOOK ONLY TO SUCH
# THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO. RECEIVER EXPRESSLY ACKNOWLEDGES
# THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES
# CONTAINED IN MEDIATEK SOFTWARE. MEDIATEK SHALL ALSO NOT BE RESPONSIBLE FOR ANY MEDIATEK
# SOFTWARE RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
# STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND MEDIATEK'S ENTIRE AND
# CUMULATIVE LIABILITY WITH RESPECT TO THE MEDIATEK SOFTWARE RELEASED HEREUNDER WILL BE,
# AT MEDIATEK'S OPTION, TO REVISE OR REPLACE THE MEDIATEK SOFTWARE AT ISSUE,
# OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE CHARGE PAID BY RECEIVER TO
# MEDIATEK FOR SUCH MEDIATEK SOFTWARE AT ISSUE.
#
# The following software/firmware and/or related documentation ("MediaTek Software")
# have been modified by MediaTek Inc. All revisions are subject to any receiver's
# applicable license agreements with MediaTek Inc.

# Copyright 2007-2008 The Android Open Source Project
LOCAL_PATH:= $(call my-dir)

################################################################################
# For packages/modules/Wifi                                                    #
################################################################################
include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := platform
LOCAL_RRO_THEME := WifiResOverlay

ifneq ($(filter $(WLAN_MT76XX_CHIPS), $(MTK_COMBO_CHIP)),)
    LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/mt7xxx_res
else
    LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res
endif

ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/80211be_support/res
endif

ifneq (,$(filter $(CONNAC_VER),1_0 2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/softap_owe/res
endif

ifneq (,$(filter $(CONNAC_VER),2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifiSoftapIeee80211axSupported/res
    # Only AX chips support SAP+SAP concurrency
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sap/res
endif


ifneq (,$(filter $(CONNAC_VER),1_0 2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_softap_ieee80211ac_supported/res
endif

ifneq (,$(filter $(WLAN_GEN3_CHIPS) $(WLAN_GEN4M_CHIPS), $(MTK_COMBO_CHIP)))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_softap_ieee80211ac_supported/res
endif

ifeq ($(MTK_WIFI_DUAL_BAND_SUPPORT), yes)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_dual_band_support/res
endif

ifeq ($(strip $(MTK_WFC_SUPPORT)), yes)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_defer_off/res
endif

# Only chips support 80211ax with kernel older than 4.14 need this. Newer
# kernels test this capability using NL80211_CMD_GET_WIPHY via wificond.
ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6883 mt6885 mt6885t mt6889 mt6891 mt6893 mt6877))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/80211ax_support/res
endif

# Only 2x2 chips support STA+STA concurrency
# NOTE: for chips have both 2x2 and 1x1 configurations, we only do test on 2x2 phones and
#       ignore 1x1 phones
ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sta/res
endif

ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6779 mt6883 mt6885 mt6889 mt6873 mt6875 mt6853 mt6891 mt6893 mt6877 mt6983 mt6879 mt6895 mt6886))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sta/res
endif

# Support for 6GHz
ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/6g/res
endif

ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6983 mt6879 mt6895 mt6886))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/6g/res
endif

LOCAL_AAPT_FLAGS += --auto-add-overlay

LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_OWNER := mtk
LOCAL_VENDOR_MODULE := true

LOCAL_PACKAGE_NAME := WifiResOverlay
LOCAL_SDK_VERSION := current
LOCAL_SDK_RES_VERSION := 30

LOCAL_MANIFEST_FILE := AndroidManifest.xml

include $(BUILD_RRO_PACKAGE)

################################################################################
# For Wi-Fi Mainline                                                           #
# Note:                                                                        #
#     Does not support dual STA/SAP for Mainline module for simplicity.        #
################################################################################
include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := platform
LOCAL_RRO_THEME := WifiResMainlineOverlay

LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res

ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/80211be_support/res
endif

ifneq (,$(filter $(CONNAC_VER),1_0 2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/softap_owe/res
endif

ifneq (,$(filter $(CONNAC_VER),2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifiSoftapIeee80211axSupported/res
    # Only AX chips support SAP+SAP concurrency
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sap/res
endif


ifneq (,$(filter $(CONNAC_VER),1_0 2_0 3_0))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_softap_ieee80211ac_supported/res
endif

ifneq (,$(filter $(WLAN_GEN3_CHIPS) $(WLAN_GEN4M_CHIPS), $(MTK_COMBO_CHIP)))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_softap_ieee80211ac_supported/res
endif

ifeq ($(MTK_WIFI_DUAL_BAND_SUPPORT), yes)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_dual_band_support/res
endif

ifeq ($(strip $(MTK_WFC_SUPPORT)), yes)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/wifi_defer_off/res
endif

# Only chips support 80211ax with kernel older than 4.14 need this. Newer
# kernels test this capability using NL80211_CMD_GET_WIPHY via wificond.
ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6883 mt6885 mt6885t mt6889 mt6891 mt6893 mt6877))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/80211ax_support/res
endif

# Only 2x2 chips support STA+STA concurrency
# NOTE: for chips have both 2x2 and 1x1 configurations, we only do test on 2x2 phones and
#       ignore 1x1 phones
ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sta/res
endif

ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6779 mt6883 mt6885 mt6889 mt6873 mt6875 mt6853 mt6891 mt6893 mt6877 mt6983 mt6879 mt6895 mt6886))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/concurrency/dual_sta/res
endif

# Support for 6GHz
ifeq ($(CONNAC_VER), 3_0)
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/6g/res
endif

ifneq (,$(filter $(TARGET_BOARD_PLATFORM),mt6983 mt6879 mt6895 mt6886))
    LOCAL_RESOURCE_DIR += $(LOCAL_PATH)/6g/res
endif

LOCAL_AAPT_FLAGS += --auto-add-overlay

LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_OWNER := mtk
LOCAL_VENDOR_MODULE := true

LOCAL_MANIFEST_FILE := AndroidManifest_Mainline.xml
LOCAL_PACKAGE_NAME := WifiResMainlineOverlay
LOCAL_SDK_VERSION := current
LOCAL_SDK_RES_VERSION := 30

include $(BUILD_RRO_PACKAGE)

################################################################################
# For Tablet Wi-Fi Mainline                                                    #
# This package is only built in tablet projects. See                           #
# device/mediatek/vendor/common/device-vext.mk.                                #
################################################################################

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := platform
LOCAL_RRO_THEME := WifiResGoogleOverlay

ifneq ($(filter $(WLAN_MT76XX_CHIPS), $(MTK_COMBO_CHIP)),)
    LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/google_wifi_mainline/mt7xxx_res
else
    LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/google_wifi_mainline/res
endif

LOCAL_AAPT_FLAGS += --auto-add-overlay

LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_OWNER := mtk
LOCAL_VENDOR_MODULE := true

LOCAL_MANIFEST_FILE := AndroidManifest_Google.xml
LOCAL_PACKAGE_NAME := WifiResGoogleOverlay
LOCAL_SDK_VERSION := current
LOCAL_SDK_RES_VERSION := 30

include $(BUILD_RRO_PACKAGE)
