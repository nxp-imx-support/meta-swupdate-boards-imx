# The rootfs image recipe to package into the .swu file.
# @@SWUPDATE_ROOTFS_IMAGE@@ in sw-description is substituted with this value by the
# swupdate bbclass via swupdate_expand_bitbake_variables().
# Changing SWUPDATE_ROOTFS_IMAGE here is the only edit needed when switching the rootfs.
SWUPDATE_ROOTFS_IMAGE ?= "core-image-base"

# Bootloader target: eMMC boot0 hardware partition. emmcsetup.lua unlocks
# force_ro in preinst and runs "mmc bootpart enable 1 1" in postinst so the
# ROM boots from boot0. Bootloader offset by SoC:
#   1K  - i.MX 6, i.MX 7
#   33K - i.MX 8QuadMax A0, i.MX 8QuadXPlus A0, i.MX 8M Quad, i.MX 8M Mini
#   32K for User partition and 0K for Boot partition - i.MX 8QuadXPlus B0,
#         i.MX 8QuadMax B0, i.MX 8DualX, i.MX 8DXL,
#         i.MX 8M Nano, i.MX 8M Plus, i.MX 8ULP, i.MX 9
# The BSP machine configs already set IMX_BOOT_SEEK (in KiB) to 32 or 33 per
# the table above, so reuse it. i.MX 6/7 machines do not define it: use 1K.
# Override SWUPDATE_BOOTPART_OFFSET in local.conf or a machine conf if needed.
# Referenced in sw-description as @@SWUPDATE_BOOTPART_DEV@@ / @@SWUPDATE_BOOTPART_OFFSET@@.
def get_swu_bootpart_offset(d):
    import re

    dev = d.getVar('SWUPDATE_BOOTPART_DEV') or ""
    seek = d.getVar('IMX_BOOT_SEEK') or "1"

    # boot from emmc boot partition, return 0K for iMX9, iMX8MP, iMX8MN, iMX8QXP, iMX8QM, IMX8ULP
    if re.search(r"mmcblk\d+boot\d+$", dev) and seek == "32":
        return "0K"

    return seek + "K"


