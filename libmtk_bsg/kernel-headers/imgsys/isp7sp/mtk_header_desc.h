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
#ifndef COMMON_KERNEL_HEADERS_IMGSYS_MTK_HEADER_DESC_H_
#define COMMON_KERNEL_HEADERS_IMGSYS_MTK_HEADER_DESC_H_
#include <imgsys/mtk_imgsys-header_desc.h>
#include <imgsys/mtk_imgsys-videodev2.h>
#define COMPACT_USE
struct v4l2_ext_plane {
#ifndef COMPACT_USE
  __u32 bytesused;
  __u32 length;
#endif
  union {
#ifndef COMPACT_USE
    __u32 mem_offset;
    __u64 userptr;
#endif
    struct {
      __s32 fd;
      __u32 offset;
    } dma_buf;
  } m;
#ifndef COMPACT_USE
  __u32 data_offset;
  __u32 reserved[11];
#else
  __u64 reserved[2];
#endif
};
#define IMGBUF_MAX_PLANES (3)
struct v4l2_ext_buffer {
#ifndef COMPACT_USE
  __u32 index;
  __u32 type;
  __u32 flags;
  __u32 field;
  __u64 timestamp;
  __u32 sequence;
  __u32 memory;
#endif
  struct v4l2_ext_plane planes[IMGBUF_MAX_PLANES];
  __u32 num_planes;
#ifndef COMPACT_USE
  __u32 reserved[11];
#else
  __u64 reserved[2];
#endif
};
struct mtk_imgsys_crop {
  struct v4l2_rect c;
  struct v4l2_fract left_subpix;
  struct v4l2_fract top_subpix;
  struct v4l2_fract width_subpix;
  struct v4l2_fract height_subpix;
};
struct plane_pix_format {
  __u32 sizeimage;
  __u32 bytesperline;
} __attribute__((packed));
struct pix_format_mplane {
  __u32 width;
  __u32 height;
  __u32 pixelformat;
  struct plane_pix_format plane_fmt[IMGBUF_MAX_PLANES];
} __attribute__((packed));
struct buf_format {
  union {
    struct pix_format_mplane pix_mp;
  } fmt;
};
struct buf_info {
  struct v4l2_ext_buffer buf;
  struct buf_format fmt;
  struct mtk_imgsys_crop crop;
  __u32 rotation;
  __u32 hflip;
  __u32 vflip;
  __u8 resizeratio;
  __u32 secu;
};
#define FRAME_BUF_MAX (1)
struct frameparams {
  struct buf_info bufs[FRAME_BUF_MAX];
};
#define SCALE_MAX (1)
#define TIME_MAX (192)
struct header_desc {
  __u32 fparams_tnum;
  struct frameparams fparams[TIME_MAX][SCALE_MAX];
};
#define TMAX (16)
struct header_desc_norm {
  __u32 fparams_tnum;
  struct frameparams fparams[TMAX][SCALE_MAX];
};
#define IMG_MAX_HW_INPUTS 3
#define IMG_MAX_HW_OUTPUTS 4
#define IMG_MAX_HW_DMAS 93
struct singlenode_desc {
  __u8 dmas_enable[IMG_MAX_HW_DMAS][TIME_MAX];
  struct header_desc dmas[IMG_MAX_HW_DMAS];
  struct header_desc tuning_meta;
  struct header_desc ctrl_meta;
  struct header_desc ctrl_meta_from_user;
  __u64 req_stat;
};
struct singlenode_desc_norm {
  __u8 dmas_enable[IMG_MAX_HW_DMAS][TMAX];
  struct header_desc_norm dmas[IMG_MAX_HW_DMAS];
  struct header_desc_norm tuning_meta;
  struct header_desc_norm ctrl_meta;
  struct header_desc_norm ctrl_meta_from_user;
  __u64 req_stat;
};
#endif /* COMMON_KERNEL_HEADERS_IMGSYS_MTK_HEADER_DESC_H_ */
