SWUpdate Configuration Files
============================

Overview
--------
This directory contains the common (machine-independent) configuration files
for the swupdate recipe, managed by swupdate_%.bbappend.

File resolution uses Yocto's FILESEXTRAPATHS mechanism:

    FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/${PN}:"

Yocto searches directories from left to right and stops at the first match.
The order resolves "file://<name>" as follows:

  1. ${THISDIR}/files/<name>               -- files/ directory (lowest priority)
  2. ${THISDIR}/swupdate/<MACHINE>/<name>  -- machine-specific (highest priority)
  3. ${THISDIR}/swupdate/<name>            -- common fallback (this directory)

Files in this directory
-----------------------
  09-swupdate-args       -- swupdate daemon command-line arguments fragment
  defconfig              -- swupdate Kconfig build options
  swupdate.cfg           -- swupdate runtime configuration (suricatta, webserver)
  swu_public.pem         -- RSA public key used to verify .swu packages
  swupdate-key.pass      -- passphrase for the signing key (build-time use only)
  priv.pem               -- RSA private key for signing sw-description (build use)
  swupdate.service       -- systemd unit for swupdate main service
  swupdate-sysrestart.service -- systemd unit for post-update reboot

Priority notes
--------------
Files placed in a machine-specific subdirectory (<MACHINE>/) take priority
over the common files in this directory.  See the readme.txt in each
machine subdirectory for details on what can be overridden.

To add a machine-specific override:
  1. Create a subdirectory named after the Yocto MACHINE value:
       swupdate/swupdate/<MACHINE>/
  2. Place only the files that differ from the common defaults.
     Files not present in <MACHINE>/ fall back to this directory.
  3. Add the machine directory to FILESEXTRAPATHS in swupdate_%.bbappend:
       FILESEXTRAPATHS:prepend := \
           "${THISDIR}/${PN}/${MACHINE}:${THISDIR}/files:${THISDIR}/${PN}:"
