# How it works

## Why not just add a file?

libfprint selects drivers at compile time (`-Ddrivers=...`). A driver is registered in two build files and
compiled into `libfprint-2.so`. So supporting a new sensor means supplying a different `libfprint-2.so`.

## What `install` does

1. **Checks.** Requires root, the `04f3:0c4c` device on the USB bus (`/sys/bus/usb/devices`), `systemd`, and
   an existing `fprintd.service`. Refuses if your libfprint already contains the driver.
2. **Source.** `git clone --branch vX.Y.Z` of upstream libfprint, where `X.Y.Z` is the version your package
   manager reports (Debian epochs and `+tod` suffixes are stripped). The tag must resolve to the commit
   pinned in `data/versions.tsv`.
3. **Driver.** Copies `driver/elanmoc_0c4c`, verified against `data/SHA256SUMS`, applies the safety patch
   to the copy, and registers the driver. Two build-file layouts exist: libfprint <= 1.94.10 lists drivers in
   plain lists, 1.94.100 uses dictionaries. Both are handled and anything else aborts.
4. **Build.** `meson setup --prefix=/opt/fprint-elan-0c4c --libdir=lib -Ddrivers=all ...`, `compile`,
   `install`. Options are only passed if that libfprint version defines them. `-Ddrivers=all` mirrors what
   distributions build, so other readers keep working.
5. **SELinux.** If SELinux is enabled, `/opt/fprint-elan-0c4c/lib` is labelled `lib_t` (persistent via
   `semanage fcontext` when available, otherwise `chcon`) so the confined `fprintd` may load it.
6. **Activate.** Writes `/etc/systemd/system/fprintd.service.d/50-fprint-elan-0c4c.conf`:

   ```ini
   [Service]
   Environment=LD_LIBRARY_PATH=/opt/fprint-elan-0c4c/lib
   ```

   and `/etc/fprint-elan-0c4c.conf` (prefix and built version), reloads systemd and restarts `fprintd`.

Only the `fprintd` daemon links libfprint. PAM (`pam_fprintd`) and the `fprintd-*` tools talk to the daemon
over D-Bus, so nothing else needs the patched library.

## Updates

If your distribution upgrades libfprint, the older patched copy in `/opt` keeps being used. libfprint keeps
its ABI (`libfprint-2.so.2`) stable, so this normally keeps working but misses fixes. `fprint-elan-0c4c
check` exits 1 when the versions differ; re-run `install` to rebuild. To automate it, call
`fprint-elan-0c4c check --quiet || fprint-elan-0c4c install` from a package-manager hook of your choice
(apt `DPkg::Post-Invoke`, a pacman hook, or a dnf plugin). No hook is installed for you.

## Uninstall

Removes the drop-in, the config file, the SELinux rule and `/opt/fprint-elan-0c4c`, then restarts
`fprintd`. Fingerprints stored on the chip are not touched.

## The sensor, briefly

It is a **match-on-chip** sensor: matching happens inside the chip and the host never sees images. Commands
use bulk endpoints `0x01` (out) and `0x83`/`0x84` (in) with the `0x40 0xFF xx` scheme of ELAN's other MoC
sensors. Enrolment takes 8 scans. The chip refuses to enrol a finger that already has a slot (the
"duplicate" check) and lists its prints only after a verify touch.
