# meta-swupdate-boards-imx

## Overview

`meta-swupdate-boards-imx` is a Yocto layer that simplifies the integration of SWUpdate-based OTA functionality on NXP i.MX platforms.

The layer provides a complete OTA solution based on:

- Dual-copy (A/B) root filesystem layout
- Recovery RAMFS
- SWUpdate package generation
- U-Boot environment integration
- Automatic `fw_env.config` generation
- GPT partition support
- Direct generation of base images and OTA update images from Yocto

The goal of this layer is to accelerate OTA enablement on i.MX platforms while minimizing manual configuration and maintenance effort.

---

## Features

- Direct generation of base images and OTA update images from Yocto
- U-Boot environment injection without maintaining U-Boot patches
- Automatic generation of `fw_env.config`
- Automatic root filesystem partition size calculation
- Support for both MBR and GPT partition layouts
- Lua-based SWUpdate pre-install and post-install scripts
- Single `sw-description` supporting both A and B rootfs updates
- Externalized signing key configuration
- Generic and board-specific customization support

---

## Dependencies

This layer depends on:

### Yocto Project

Either:

- `openembedded-core`
- `bitbake`

or:

- `poky`

### SWUpdate Layer

- Repository: https://github.com/sbabic/meta-swupdate

It is recommended to use a `meta-swupdate` branch matching the Yocto release.

For example:

| Yocto Release | meta-swupdate Branch |
|---------------|----------------------|
| Walnascar | walnascar |

---

## Supported Platforms

The default implementation is designed for:

- i.MX 8M family
- i.MX 9 family

Legacy i.MX platforms may require board-specific customization.

---

## Quick Start

### 1. Add Required Layers

Add the following layers to `conf/bblayers.conf`:

```text
meta-swupdate
meta-swupdate-boards-imx
```

### 2. Configure the Build Environment

Set the target platform in `conf/local.conf`:

```text
MACHINE = "imx95-19x19-evk"
```

### 3. Build Images

Build the base image:

```bash
bitbake swu-base-image
```

Build the OTA update image:

```bash
bitbake swu-update-image
```

---

## Generated Images

### Base Image

```bash
bitbake swu-base-image
```

Generates an OTA-enabled image containing:

- Bootloader
- Recovery RAMFS
- RootFS A
- RootFS B

### OTA Update Image

```bash
bitbake swu-update-image
```

Generates a `.swu` package suitable for deployment through SWUpdate.

---

## Image Layout

The default layout consists of:

```text
+-------------------------+
| Bootloader              |
+-------------------------+
| Recovery Kernel         |
+-------------------------+
| Recovery DTB            |
+-------------------------+
| Recovery RAMFS          |
+-------------------------+
| Kernel + DTB (A)        |
+-------------------------+
| RootFS A                |
+-------------------------+
| Kernel + DTB (B)        |
+-------------------------+
| RootFS B                |
+-------------------------+
```

The system updates the inactive slot and switches to the updated slot after successful installation.

---

## Customization

### Exported Variables

The following variables can be overridden from `local.conf` or machine configuration files.

| Variable | Description |
|-----------|-------------|
| `SWUPDATE_ROOTFS_IMAGE` | Root filesystem image used for OTA generation |
| `SWUPDATE_ROOTFS_PART_SIZE` | Root filesystem partition size |
| `SWUPDATE_DISK_PTABLE` | Partition table format (`msdos` or `gpt`) |
| `SWUPDATE_PRIVATE_KEY` | SWUpdate signing key |
| `SWUPDATE_PASSWORD_FILE` | Password file for signing key |
| `SWUPDATE_FW_ENV_DEV` | Override SWUPDATE_FW_ENV_DEV if the eMMC device is not /dev/mmcblk0 |
| `SWUDPATE_HW_REV` | Board revision written to /etc/hwrevision |

Example:

```text
SWUPDATE_ROOTFS_IMAGE = "imx-image-full"
SWUPDATE_DISK_PTABLE = "gpt"
```

---

### Custom `fw_env.config`

A custom `fw_env.config` may be supplied through:

```text
recipes-bsp/libubootenv/files/fw_env.config
```

or

```text
recipes-bsp/libubootenv/files/<board>/fw_env.config
```

Board-specific files take precedence over generic files.

---

### Custom Signing Keys

Demo keys are provided for development and evaluation purposes.

```text
recipes-support/swupdate/swupdate/priv.pem
recipes-support/swupdate/swupdate/swupdate-key.pass
```

For production deployments, configure:

```text
SWUPDATE_PRIVATE_KEY
SWUPDATE_PASSWORD_FILE
```

Example:

```text
SWUPDATE_PRIVATE_KEY = "/path/to/private-key.pem"
SWUPDATE_PASSWORD_FILE = "/path/to/password-file"
```

---

### Generic and Board-Specific Files

The following files support both generic and board-specific implementations:

- `env.txt`
- `fw_env.config`
- `sw-description`
- `emmcsetup.lua`
- `defconfig`
- `swupdate.cfg`
- `09-swupdate-args`

When both versions exist, the board-specific file takes precedence.

---

## OTA Update Flow

The default implementation supports updating either root filesystem slot using a single `sw-description`.

Software collections:

- `copy1` ¡ú Update RootFS B
- `copy2` ¡ú Update RootFS A

The `09-swupdate-args` script determines the active slot and automatically selects the correct software collection.

For debugging, software collections may be selected manually:

```bash
swupdate -v -e stable,copy1 -i update_image.swu
```

or

```bash
swupdate -v -e stable,copy2 -i update_image.swu
```

---

## Debugging

Verify U-Boot environment:

```bash
fw_printenv
```

Verify generated configuration:

```bash
cat /etc/fw_env.config
```

Verify partition layout:

```bash
fdisk -l
```

Run SWUpdate manually:

```bash
swupdate -v -i update_image.swu
```

---

## Documentation

See the accompanying Application Note:

**Accelerating OTA Enablement on i.MX Platforms Using meta-swupdate-boards-imx**

The Application Note describes:

- Layer architecture
- Default partition layout
- OTA workflow
- U-Boot environment injection
- GPT support
- Key management
- Platform customization

---

## License

MIT
