U-Boot Environment Injection
============================

Overview
--------
The bbappend file u-boot-imx_%.bbappend injects extra environment variables
into the U-Boot default environment at build time.

Injection steps:
  1. awk collapses backslash-continuation lines in both the source env.txt
     and the board env file into single logical lines.
  2. For each non-comment "key=value" in env.txt, sed replaces the matching
     definition in the (normalized) board env file in-place, or appends it
     if the key does not exist.
  3. The resulting file replaces the original board env file.

This correctly handles multiline variables such as mmcargs and bsp_bootcmd.

Board env file lookup (reads from the generated .config after do_configure):
  1. If CONFIG_ENV_SOURCE_FILE is set, look for board/**/<value>.env in the
     U-Boot source tree.
  2. Else if CONFIG_SYS_BOARD is set, look for board/**/<value>.env in the
     U-Boot source tree.
  3. If no file is found in the source tree and CONFIG_SYS_BOARD is known,
     check the layer overlay directory:
       files/board-env/<MACHINE>/<CONFIG_SYS_BOARD>.env
     If present, copy it to board/<CONFIG_SYS_VENDOR>/<CONFIG_SYS_BOARD>/ in
     the U-Boot source tree, then inject variables into it.
  4. If no board env file is found by any of the above, skip env injection.

Directory layout
----------------
files/swu-env/
    readme.txt           -- this file
    env.txt              -- common variables, ALL machines (LOW priority)
    <MACHINE>/
        env.txt          -- machine-specific variables (HIGH priority, optional)

files/board-env/
    <MACHINE>/
        <sys_board>.env  -- board env overlay for boards that have no
                            .env file in the U-Boot source tree

How to add a board env overlay
--------------------------------
For a board that lacks a .env file in the U-Boot source (e.g. imx6ull_evk
on machine imx6ull9x9evk):
  1. Find the board name from the board's .config after configure:
       CONFIG_SYS_VENDOR="freescale"
       CONFIG_SYS_BOARD="imx6ull_evk"
  2. Create the overlay file using the Yocto MACHINE name as directory:
       files/board-env/imx6ull9x9evk/imx6ull_evk.env
  3. Add the U-Boot environment variables needed as the board baseline.
  4. The variables in files/swu-env/env.txt (or <MACHINE>/env.txt) will still
     be injected on top of this overlay file as usual.

Priority: MACHINE-SPECIFIC > COMMON
-------------------------------------
FILESEXTRAPATHS:prepend is set to:

    files/swu-env

Yocto automatically searches <dir>/<MACHINE>/ before <dir>/ for each entry
in FILESEXTRAPATHS, so the resolution of "file://env.txt" is:
  1. files/swu-env/<MACHINE>/env.txt  (machine-specific, found first -> used)
  2. files/swu-env/env.txt            (common fallback, used when no machine file)

When a <MACHINE>/env.txt exists it completely replaces the common env.txt for
that machine.  The two files are NOT merged.

env.txt file format
-------------------
Each line is a U-Boot environment variable assignment:

    name=value

Rules:
- No shell quoting around the value.
- No spaces around the '=' sign.
- Lines starting with '#' are comments and are skipped.
- Blank lines are skipped.
- Multiline values using backslash continuation are supported:
    bsp_bootcmd=run adjustbootsource; \
        mmc dev ${mmcdev}; \
        run mmcboot;

Example (env.txt - common fallback):
    # Override mmcargs for A/B slot layout
    mmcargs=setenv bootargs ${jh_clk} console=${console} root=${mmcroot} cur_slot=${bootslot}
    bootslot=dualA

Example (files/swu-env/imx91-11x11-lpddr4-evk/env.txt - machine-specific):
    # Machine-specific overrides (take priority over common env.txt)
    swupdate_active=a
    swupdate_inactive=b

How to add or change variables
--------------------------------
Common variable (applies to all machines that have no machine-specific file):
  Edit  files/swu-env/env.txt

Machine-specific variable (takes priority over common, replaces common entirely):
  Create  files/swu-env/<MACHINE>/env.txt  (if it does not exist yet)
  Add all required variable assignments to that file.

After any change, rebuild u-boot-imx:
    bitbake -c cleansstate u-boot-imx && bitbake u-boot-imx
