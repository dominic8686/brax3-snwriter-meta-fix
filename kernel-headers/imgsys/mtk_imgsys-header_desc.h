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

#ifndef COMMON_KERNEL_HEADERS_IMGSYS_MTK_IMGSYS_HEADER_DESC_H_
#define COMMON_KERNEL_HEADERS_IMGSYS_MTK_IMGSYS_HEADER_DESC_H_

enum imgsysrotation {
  imgsysrotation_0 = 0,
  imgsysrotation_90,
  imgsysrotation_180,
  imgsysrotation_270
};

enum imgsysflip {
  imgsysflip_off = 0,
  imgsysflip_on = 1,
};

enum img_resize_ratio {
  img_resize_anyratio,
  img_resize_down4,
  img_resize_down2,
  img_resize_down42,
  img_resize_down8,
  img_resize_down16,
  img_resiz_max
};

#endif /* COMMON_KERNEL_HEADERS_IMGSYS_MTK_IMGSYS_HEADER_DESC_H_ */
