Common U-Boot environment variable overrides for all machines.

This file is intentionally empty by default.  Add variable assignments
here (one per line, "name=value" format, no quotes) to inject them into
the U-Boot default environment at build time.

For machine-specific overrides create a subdirectory named after the
MACHINE value and place an env.txt file there.  Yocto's FILESEXTRAPATHS
mechanism will pick it up automatically with higher priority than this
common file.  Example:
  files/env/imx91-11x11-lpddr4-evk/env.txt
