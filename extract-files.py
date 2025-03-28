#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'hardware/mediatek',
    'hardware/mediatek/libmtkperf_client',
    'vendor/brax/brax3',
    'hardware/mediatek',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'android.hardware.security.keymint-V1-ndk',
        'vendor.mediatek.hardware.videotelephony@1.0',
     ): lib_fixup_vendor_suffix,
    ('libsink',): lib_fixup_remove,
}

blob_fixups: blob_fixups_user_type = {
    'system_ext/lib64/libsource.so': blob_fixup()
        .add_needed('libstagefright_foundation-v33.so'),
    'vendor/bin/hw/android.hardware.health-service.example': blob_fixup()
        .replace_needed('android.hardware.health-V1-ndk.so', 'android.hardware.health-V3-ndk.so'),
    (
        'vendor/lib64/android.hardware.bluetooth.audio-impl.so',
        'vendor/lib64/libbluetooth_audio_session_aidl.so',
        'vendor/lib/android.hardware.bluetooth.audio-impl.so',
        'vendor/lib/libbluetooth_audio_session_aidl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.bluetooth.audio-V2-ndk', 'android.hardware.bluetooth.audio-V5-ndk'),
    (
        'vendor/lib/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so'
        'vendor/lib64/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so'
    ): blob_fixup()
         .replace_needed('android.media.audio.common-V1-ndk.so', 'android.media.audio.common-V4-ndk.so'),
    'vendor/lib/libvp8dec_sa.ca7.so': blob_fixup()
         .replace_needed('libutils.so', 'libutils-v32.so'),
    'vendor/bin/hw/android.hardware.media.c2@1.2-mediatek-64b': blob_fixup()
        .add_needed('libstagefright_foundation-v33.so'),
    ('vendor/bin/mnld', 'vendor/lib64/libaalservice.so', 'vendor/lib64/mt6835/libcam.utils.sensorprovider.so', 'vendor/lib64/mt6835/libcam.utils.sensorprovider.so'): blob_fixup()
        .replace_needed('libsensorndkbridge.so', 'android.hardware.sensors@1.0-convert-shared.so'),
    'vendor/lib64/mt6835/libmtkcam_featurepolicy.so': blob_fixup()
        .binary_regex_replace(b'\x34\xE8\x87\x40\xB9', b'\x34\x28\x02\x80\x52'),
    ('vendor/lib64/mt6835/libmtkcam_stdutils.so', 'vendor/lib64/hw/mt6835/android.hardware.camera.provider@2.6-impl-mediatek.so'): blob_fixup()
        .replace_needed('libutils.so', 'libutils-v32.so'),
    'vendor/bin/hw/android.hardware.sensors-service.multihal': blob_fixup()
        .replace_needed('android.hardware.sensors-V1-ndk.so', 'android.hardware.sensors-V2-ndk.so'),
    (
        'vendor/lib/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.audio.common-V1-ndk.so', 'android.hardware.audio.common-V4-ndk.so')
        .replace_needed('android.hardware.audio.common-V1.so', 'android.hardware.audio.common-V4.so'),
    'vendor/lib64/hw/vendor.mediatek.hardware.pq@2.15-impl.so': blob_fixup()
        .replace_needed('libutils.so', 'libutils-v33.so')
        .replace_needed('libsensorndkbridge.so', 'android.hardware.sensors@1.0-convert-shared.so'),
    (
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V1-ndk.so'
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V3-ndk.so', 'android.hardware.graphics.common-V5-ndk.so'),
    'vendor/lib64/mt6835/lib3a.ae.stat.so': blob_fixup()
        .add_needed('liblog.so'),
    (
        'vendor/lib/mt6835/libneuralnetworks_sl_driver_mtk_prebuilt.so',
        'vendor/lib64/mt6835/libneuralnetworks_sl_driver_mtk_prebuilt.so'
     ): blob_fixup()
        .add_needed('libnativewindow.so'),
    'vendor/bin/hw/android.hardware.security.keymint@2.0-service.trustonic': blob_fixup()
        .replace_needed('android.hardware.security.keymint-V2-ndk.so', 'android.hardware.security.keymint-V3-ndk.so')
        .add_needed('android.hardware.security.rkp-V3-ndk.so'),

}  # fmt: skip

module = ExtractUtilsModule(
    'brax3',
    'brax',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
