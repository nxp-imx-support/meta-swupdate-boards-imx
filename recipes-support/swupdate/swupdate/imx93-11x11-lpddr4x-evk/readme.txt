Machine-Specific SWUpdate Configuration Overrides
==================================================

Purpose
-------
Files placed in this directory override the common defaults found in the
parent directory (swupdate/swupdate/).  Only the files that differ from
the common configuration need to be placed here.

Priority
--------
Yocto's FILESEXTRAPATHS mechanism resolves "file://<name>" by searching
directories from left to right, stopping at the first match:

  1. swupdate/swupdate/<MACHINE>/<name>   -- THIS directory (highest priority)
  2. swupdate/swupdate/<name>             -- common fallback (parent directory)

Any file present here takes precedence over the same-named file in the
parent directory for this machine only.

Files that can be overridden
----------------------------
  defconfig              -- swupdate Kconfig build options (e.g. enable/disable
                            features specific to this board)
  swupdate.cfg           -- runtime configuration (suricatta server, webserver
                            port, log level, public key path, etc.)
  09-swupdate-args       -- swupdate daemon command-line arguments (e.g. MTD
                            device names, socket path, hardware revision)

How to add a machine-specific override
---------------------------------------
  1. Copy the file to override from the parent directory into this directory.
  2. Edit it to suit the machine-specific requirements.
  3. Rebuild swupdate:
       bitbake -c cleansstate swupdate && bitbake swupdate
