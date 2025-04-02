/****************************************************************************
 ****************************************************************************
 ***
 ***   This header was automatically generated from a Linux kernel header
 ***   of the same name, to make information necessary for userspace to
 ***   call into the kernel available to libc.  It contains only constants,
 ***   structures, and macros generated from the original header, and thus,
 ***   contains no copyrightable information.
 ***
 ***   To edit the content of this header, modify the corresponding
 ***   source file (e.g. under external/kernel-headers/original/) then
 ***   run bionic/libc/kernel/tools/update_all.py
 ***
 ***   Any manual change here will be lost the next time this script will
 ***   be run. You've been warned!
 ***
 ****************************************************************************
 ****************************************************************************/
#ifndef __AOV_PARAM_H__
#define __AOV_PARAM_H__
#include <stdint.h>
#include <stddef.h>
#include <sys/ioctl.h>
#define AOV_DEV_START _IOW('H', 0, struct aov_user)
#define AOV_DEV_SENSOR_ON _IOW('H', 1, struct sensor_notify)
#define AOV_DEV_SENSOR_OFF _IOW('H', 2, struct sensor_notify)
#define AOV_DEV_DQEVENT _IOR('H', 3, struct aov_dqevent)
#define AOV_DEV_STOP _IO('H', 4)
#define AOV_DEBUG_MODE_DUMP (1)
#define AOV_DEBUG_MODE_NDD (2)
#define AOV_MAX_AAA_SIZE (32 * 1024)
#define AOV_MAX_TUNING_SIZE (2 * 1024)
#define AOV_MAX_YUVO1_OUTPUT (737280 + 32)
#define AOV_MAX_YUVO2_OUTPUT (184320 + 32)
#define AOV_MAX_AIE_OUTPUT (32 * 1024)
#define AOV_MAX_APU_OUTPUT (256 * 1024)
#define AOV_MAX_IMGO_OUTPUT (921600 + 32)
#define AOV_MAX_AAO_OUTPUT (158 * 1024)
#define AOV_MAX_AAHO_OUTPUT (1 * 1024)
#define AOV_MAX_META_OUTPUT (6 * 1024)
#define AOV_MAX_AWB_OUTPUT (1 * 1024)
#define AOV_MAX_SENSOR_COUNT (64)
struct aov_dqevent {
  uint32_t session;
  uint32_t frame_id;
  uint32_t frame_width;
  uint32_t frame_height;
  uint32_t frame_mode;
  uint32_t detect_mode;
  uint32_t aie_size;
  void * aie_output;
  uint32_t apu_size;
  void * apu_output;
  uint32_t yuvo1_width;
  uint32_t yuvo1_height;
  uint32_t yuvo1_format;
  uint32_t yuvo1_stride;
  void * yuvo1_output;
  uint32_t yuvo2_width;
  uint32_t yuvo2_height;
  uint32_t yuvo2_format;
  uint32_t yuvo2_stride;
  void * yuvo2_output;
  uint32_t imgo_width;
  uint32_t imgo_height;
  uint32_t imgo_format;
  uint32_t imgo_order;
  uint32_t imgo_stride;
  void * imgo_output;
  uint32_t aao_size;
  void * aao_output;
  uint32_t aaho_size;
  void * aaho_output;
  uint32_t meta_size;
  void * meta_output;
  uint32_t awb_size;
  void * awb_output;
};
struct aov_event {
  uint32_t session;
  uint32_t frame_id;
  uint32_t frame_width;
  uint32_t frame_height;
  uint32_t frame_mode;
  uint32_t detect_mode;
  uint32_t aie_size;
  uint8_t aie_output[AOV_MAX_AIE_OUTPUT];
  uint32_t apu_size;
  uint8_t apu_output[AOV_MAX_APU_OUTPUT];
  uint32_t yuvo1_width;
  uint32_t yuvo1_height;
  uint32_t yuvo1_format;
  uint32_t yuvo1_stride;
  uint8_t yuvo1_output[AOV_MAX_YUVO1_OUTPUT];
  uint32_t yuvo2_width;
  uint32_t yuvo2_height;
  uint32_t yuvo2_format;
  uint32_t yuvo2_stride;
  uint8_t yuvo2_output[AOV_MAX_YUVO2_OUTPUT];
  uint32_t imgo_width;
  uint32_t imgo_height;
  uint32_t imgo_format;
  uint32_t imgo_order;
  uint32_t imgo_stride;
  uint8_t imgo_output[AOV_MAX_IMGO_OUTPUT];
  uint32_t aao_size;
  uint8_t aao_output[AOV_MAX_AAO_OUTPUT];
  uint32_t aaho_size;
  uint8_t aaho_output[AOV_MAX_AAHO_OUTPUT];
  uint32_t meta_size;
  uint8_t meta_output[AOV_MAX_META_OUTPUT];
  uint32_t awb_size;
  uint8_t awb_output[AOV_MAX_AWB_OUTPUT];
} __attribute__((aligned(4)));
enum aov_log_level {
  AOV_LOG_LEVEL_ERROR = 0,
  AOV_LOG_LEVEL_WARN = 1,
  AOV_LOG_LEVEL_INFO = 2,
  AOV_LOG_LEVEL_DEBUG = 3,
  AOV_LOG_LEVEL_VERB = 4
};
enum aov_log_id {
  AOV_LOG_ID_BASE,
  AOV_LOG_ID_RED,
  AOV_LOG_ID_AOV,
  AOV_LOG_ID_TLSF,
  AOV_LOG_ID_2A,
  AOV_LOG_ID_TUNING,
  AOV_LOG_ID_SENSOR,
  AOV_LOG_ID_SENIF,
  AOV_LOG_ID_UISP,
  AOV_LOG_ID_AIE,
  AOV_LOG_ID_APU,
  AOV_LOG_ID_MAX
};
struct aov_user {
  uint32_t session;
  uint32_t sensor_id;
  uint32_t sensor_scene;
  int32_t  sensor_orient;
  uint32_t sensor_face;
  uint32_t sensor_type;
  uint32_t sensor_bit;
  uint32_t sensor_ae;
  uint32_t format_order;
  uint32_t main_width;
  uint32_t main_height;
  uint32_t main_format;
  uint32_t sub_width;
  uint32_t sub_height;
  uint32_t sub_format;
  uint32_t frame_rate;
  uint32_t frame_mode;
  uint32_t debug_mode;
  uint32_t debug_level[AOV_LOG_ID_MAX];
  uint32_t trace_perf;
  uint32_t reserved[5];
  uint32_t aaa_size;
  void * aaa_info;
  uint32_t tuning_size;
  void * tuning_info;
};
struct sensor_notify {
  uint32_t count;
  int32_t sensor[AOV_MAX_SENSOR_COUNT];
};
#endif
