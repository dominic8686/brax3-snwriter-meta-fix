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
    'device/alps/brax3',
    'hardware/mediatek',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        # 'com.qualcomm.qti.dpm.api@1.0',
        # 'libmmosal',
        # 'vendor.qti.hardware.wifidisplaysession@1.0',
        # 'vendor.qti.imsrtpservice@3.0',
    ): lib_fixup_vendor_suffix,
    (
        # 'libwpa_client',
    ): lib_fixup_remove,
}

blob_fixups: blob_fixups_user_type = {
    'vendor/bin/hw/android.hardware.health-service.example': blob_fixup()
        .replace_needed('android.hardware.health-V1-ndk.so', 'android.hardware.health-V3-ndk.so'),
    'vendor/bin/hw/android.hardware.sensors-service.multihal': blob_fixup()
        .replace_needed('android.hardware.sensors-V1-ndk.so', 'android.hardware.sensors-V2-ndk.so'),
    (
        'vendor/lib/libbluetooth_audio_session_aidl.so',
        'vendor/lib64/libbluetooth_audio_session_aidl.so',
        'vendor/lib64/android.hardware.bluetooth.audio-impl.so'
    ): blob_fixup()
        .replace_needed('android.hardware.bluetooth.audio-V2-ndk.so', 'android.hardware.bluetooth.audio-V5-ndk.so'),
    (
        'vendor/lib/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.bluetooth.audio-V1-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.audio.common-V1-ndk.so', 'android.hardware.audio.common-V4-ndk.so')
        .replace_needed('android.hardware.audio.common-V1.so', 'android.hardware.audio.common-V4.so'),
    (
        'vendor/lib64/libcodec2_vpp_AISR_plugin.so',
        'vendor/lib64/libcodec2_vpp_AIMEMC_plugin.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so')
        .replace_needed('android.hardware.graphics.common-V3-ndk.so', 'android.hardware.graphics.common-V5-ndk.so'),
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
    (
        'vendor/lib/libspeech_enh_lib.so',
        'vendor/lib64/libspeech_enh_lib.so',
        'vendor/lib/libnir_neon_driver_ndk.mtk.vndk.so',
        'vendor/lib64/libnir_neon_driver_ndk.mtk.vndk.so',
        'vendor/lib64/libneuron_runtime_vpp.6.so',
        'vendor/lib/hw/fingerprint.default.so',
        'vendor/lib64/hw/fingerprint.default.so',
    ): blob_fixup()
        .fix_soname(),
    'vendor/bin/hw/android.hardware.security.keymint@2.0-service.trustonic': blob_fixup()
        .replace_needed('android.hardware.security.keymint-V2-ndk.so', 'android.hardware.security.keymint-V3-ndk.so')
        .add_needed('android.hardware.security.rkp-V3-ndk.so')
        .add_needed('libkeymint.so'),
    # 'system_ext/lib/libwfdmmsrc_system.so': blob_fixup()
    #     .add_needed('libgui_shim.so'),
    # 'system_ext/lib/libwfdservice.so': blob_fixup()
    #     .replace_needed('android.media.audio.common.types-V2-cpp.so', 'android.media.audio.common.types-V4-cpp.so'),
    # 'system_ext/lib64/libwfdnative.so': blob_fixup()
    #     .replace_needed('android.hidl.base@1.0.so', 'libhidlbase.so')
    #     .add_needed('libbinder_shim.so')
    #     .add_needed('libinput_shim.so'),
    # 'vendor/etc/libnfc-hal-st.conf': blob_fixup()
    #     .regex_replace('STNFC_HAL_LOGLEVEL=.*', 'STNFC_HAL_LOGLEVEL=0x12'),
    # 'vendor/lib64/hw/fingerprint.lahaina.so': blob_fixup()
    #     .fix_soname(),
    # 'vendor/lib64/libmorpho_movie_stabilizer.so': blob_fixup()
    #     .clear_symbol_version('AHardwareBuffer_acquire')
    #     .clear_symbol_version('AHardwareBuffer_describe')
    #     .clear_symbol_version('AHardwareBuffer_lockPlanes')
    #     .clear_symbol_version('AHardwareBuffer_release')
    #     .clear_symbol_version('AHardwareBuffer_unlock'),
    # 'vendor/lib64/libwvhidl.so': blob_fixup()
    #     .add_needed('libcrypto_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'brax3',
    'alps',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    # add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
