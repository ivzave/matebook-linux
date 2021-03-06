## Overview

This repo addresses some of the issues of **Huawei Matebook** running Linux.

## Patching ACPI tables

First extract tables:

	acpidump > acpidump.hex
	acpixtract -a acpidump.hex

Put them along with `refs.txt` and chosen patches, then decompile tables:

	iasl -fe refs.txt -da dsdt.dat ssdt*.dat

Apply patches of your choice.

#### Enable S3 sleep state

	patch < 0001-Enable-S3-sleep-state.patch

This should enable S3 system sleep state (suspend-to-ram), which is much more power-efficient sleep state compared to S0idle. After you install patched DSDT the `deep` value of `mem_sleep` option will be unlocked. To use S3 by default add `mem_sleep_default=deep` to `GRUB_CMDLINE_LINUX` params list in `/etc/default/grub`.

#### Enable hardware buttons support

	patch < 0002-Enable-hardware-buttons-support.patch

Nuff said. This fixes power button and volume buttons.

#### Fix battery/AC status reporting

	patch < 0003-Fix-battery-AC-status-reporting.patch

It is buggy out of the box - reports charging while fully charged and more. This mostly fixes behaviour.

## Applying patches

It's important to increment DSDT version in `dsdt.dsl`:

	-DefinitionBlock ("", "DSDT", 2, "ALASKA", "A M I ", 0x01072009)
	+DefinitionBlock ("", "DSDT", 2, "ALASKA", "A M I ", 0x01072010)

After applying patches you can compile back DSDT table:

	iasl dsdt.dsl

You can use it by passing it to kernel at boot time. Actual method depends on your distribution. Your kernel should be built with `CONFIG_ACPI_TABLE_UPGRADE`.
For Fedora and any distributions using **dracut** one can place provided `99-acpi-tables.conf` file at `/etc/dracut.conf.d/`. Compiled tables should be placed in `/usr/local/lib/firmware/acpi`. 

After you run

	sudo dracut -f

your table upgrades will be added into installed kernels. On kernel updates `dracut` also will add upgraded tables into them during install.

## Misc issues

### Controlling camera led

After resuming from S3 sleep the camera led is switched on by hardware and keeps lighting. To turn it off one can run following command:

	i2cset -y -f 7 0x4c 0x28 0

You can set it to run automatically on wakeup, e.g. using **systemd** you can place provided `cam-reset.sh` file at `/lib/systemd/system-sleep/`.

### Disabling SATA ALPM

Setting SATA ALPM mode to any other than `max_performance` currently leads to graphic glitches (flickering). Kernels 4.15+ use mode `med_power_with_dipm` by default. As workaround you can place provided `99-matebook-alpm.rules` file at `/etc/udev/rules.d` to override this setting.

### Fixing reboot

On Fedora the device often fails to reboot due to bug in wifi driver. Workaround is set `CleanupOnExit` to `false` in `/etc/firewalld/firewalld.conf`.

### Fixing wireless connectivity

Some needed pieces of firmware can't be packaged into linux distributions due to licensing constraints, so they need to be installed manually.

First mount efivars (if not mounted already):

	mount -t efivarfs none /sys/firmware/efi/efivars

Copy nvram file required by driver to location where driver expects it:

	cp /sys/firmware/efi/efivars/nvram-74b00bd9-805a-4d61-b51f-43268123d113 /lib/firmware/brcm/brcmfmac4356-pcie.txt

This fixes poor wifi signal quality. Next for bluetooth to work the hcd firmware is needed. At time of writing one can be obtained [here](https://github.com/winterheart/broadcom-bt-firmware/raw/master/brcm/BCM4356A2-0a5c-6420.hcd). File needs to be renamed to `BCM4354A2-0a5c-6420.hcd` and placed at `/lib/firmware/brcm/`.

Optional step is to place a CLM blob which can be found [here](https://github.com/andrew997/cyw-fmac-fw/raw/master/brcmfmac4356-pcie.clm_blob) at `/lib/firmware/brcm/`.
