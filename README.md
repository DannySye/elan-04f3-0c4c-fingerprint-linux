# ELAN 04f3:0c4c fingerprint reader on Linux (HP ENVY x360 / Spectre x360)

`fprint-elan-0c4c` enables fingerprint login for laptops with the **ELAN `04f3:0c4c`** fingerprint sensor on
Linux distributions that use `fprintd` + `libfprint` (Fedora, Ubuntu, Debian, Arch, openSUSE and others;
[only Fedora is hardware-tested](#tested)).

Windows calls this device **"ELAN WBF Fingerprint Sensor"**. Linux shows it as `ELAN:ARM-M4`:

```
$ lsusb | grep 04f3:0c4c
Bus 003 Device 002: ID 04f3:0c4c Elan Microelectronics Corp. ELAN:ARM-M4
```

Out of the box, `fprintd-list` says *"No devices available"* because libfprint has no driver for this
sensor. This tool builds libfprint **with a community driver added** and points `fprintd` at it, without
replacing any of your distribution's files.

**Is this your problem?**

* fingerprint reader not working or not detected on an HP ENVY x360, ENVY 17 or Spectre x360 under Linux
* `fprintd-list` or `fprintd-enroll` reports `No devices available`
* `lsusb` shows `04f3:0c4c Elan Microelectronics Corp. ELAN:ARM-M4`
* Windows Device Manager shows `ELAN WBF Fingerprint Sensor` (`USB\VID_04F3&PID_0C4C`)

> **Status: alpha (0.1.0).** Verified on one laptop (see [Tested](#tested)). Read
> [What is and is not verified](#what-is-and-is-not-verified) before installing.

## Quick start

```bash
git clone https://github.com/DannySye/elan-04f3-0c4c-fingerprint-linux.git
cd elan-04f3-0c4c-fingerprint-linux

./bin/fprint-elan-0c4c doctor          # read-only: is this tool for you? what is missing?
sudo ./bin/fprint-elan-0c4c install    # builds into /opt/fprint-elan-0c4c, restarts fprintd
```

Then, **as your normal user**:

```bash
fprintd-list $USER
fprintd-enroll -f left-index-finger    # use a finger that is NOT enrolled in Windows (see below)
fprintd-verify
```

If `doctor` lists missing build tools it prints the exact install command for your package manager.
To remove everything: `sudo ./bin/fprint-elan-0c4c uninstall`.

## Dual-booting with Windows: read this

The sensor stores fingerprints **on the chip itself** (10 slots). Windows and Linux share those slots.

* **One finger = one slot.** If a finger is already enrolled in Windows, Linux will refuse to enrol it
  ("duplicate") and vice versa. Use a **different finger** on each system.
* **Linux never deletes prints it did not create.** `fprintd` tries to "garbage collect" an unknown print
  it matches while you enrol. This tool's safety patch makes the driver refuse to delete any print whose
  ID is not in libfprint's `FP1-…` format, so your Windows finger cannot be removed from Linux.
* **Wiping the chip is blocked** unless you set `FP_ELAN_0C4C_ALLOW_CLEAR=1` for the process that calls
  it. `fprintd` never does.
* Linux does not manage Windows prints: it cannot list or delete them, and enrolling the same finger is
  refused. Whether a Windows print can unlock Linux is untested and not supported. They keep working in
  Windows.

If you want a finger on Linux that is currently a Windows finger, remove it in Windows first
(Settings → Accounts → Sign-in options → Fingerprint → Remove), then enrol it on Linux.

## How it works

libfprint compiles its drivers in, so a driver cannot be dropped in as a plugin. The tool:

1. detects your distribution's libfprint version and checks the sensor is present;
2. fetches the **same upstream libfprint version** from freedesktop.org and verifies the tag's commit hash
   against [`data/versions.tsv`](data/versions.tsv);
3. verifies the vendored driver against [`data/SHA256SUMS`](data/SHA256SUMS), applies the
   [safety patch](driver/patches/0001-protect-foreign-prints.patch), registers the driver in the build
   files, and builds with Meson into `/opt/fprint-elan-0c4c`;
4. adds a systemd drop-in `fprintd.service.d/50-fprint-elan-0c4c.conf` that sets
   `LD_LIBRARY_PATH=/opt/fprint-elan-0c4c/lib` for `fprintd` only.

Nothing under `/usr` is touched, no package is replaced, and `uninstall` removes the drop-in and the build.
Details: [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md).

## Tested

| Laptop | Distro | libfprint | Result |
|---|---|---|---|
| HP Spectre x360 14-ea0xxx | Fedora 45 (SELinux enforcing) | 1.94.100 | via this tool's `install`: device listed, enrolled finger verifies. Earlier, with the same driver built as a local RPM: enrol, verify, `sudo`, lock screen and GDM login |

Everything else is **build-tested only**: the driver compiles against libfprint 1.94.0, 1.94.2 and
1.94.4 through 1.94.10 (see [data/versions.tsv](data/versions.tsv) and [docs/TESTED.md](docs/TESTED.md)).
libfprint 1.92.x is not supported (its driver API is too old).

## Laptops reported with this sensor

Found by a web search in November 2026. Apart from the first row, **nobody has tested this tool on them**.
"Reported" describes what the source says, which may involve a different driver. The list is incomplete:
check your own machine with `lsusb | grep 04f3:0c4c`.

| HP model | Source | Reported |
|---|---|---|
| Spectre x360 14-ea0xxx | this project | works with this tool |
| Spectre x360 14" (2020) | [depau/elanpoc](https://github.com/depau/elanpoc) | proof of concept |
| ENVY x360 15-ee0477ng | [libfprint #281](https://gitlab.freedesktop.org/libfprint/libfprint/-/work_items/281) | support request |
| ENVY 17m-cg0013dx | [Manjaro forum](https://forum.manjaro.org/t/hp-17m-cg0013dx-can-not-get-fingerprint-sensor-working/32819) (2020) | not working then |
| ENVY Laptop 17m-cg1xxx | [Windows driver listing](https://www.driveridentifier.com/scan/elan-wbf-fingerprint-sensor-driver/download/559268479/72BD75CF91EC4F788F46E395B6D6782E/USB/VID_04F3&PID_0C4C) | Windows driver only (seen in a search summary, page not opened) |
| ENVY notebook (model not given) | [J. Kinzig's blog](https://johanneskinzig.com/fingerprint-authentication-with-ubuntu-2404-on-my-hp-envy-notebook.html) | works on Ubuntu 24.04 with `elanmoc2` |
| ENVY x360, ENVY Laptop, Spectre x360 (names truncated) | [linux-hardware.org](https://linux-hardware.org/?id=usb%3A04f3-0c4c), [bsd-hardware.info](https://bsd-hardware.info/?id=usb%3A04f3-0c4c) | mostly not working without a patched driver |

Only HP models turned up, but only part of the hardware database was read, so other brands are possible.
**Please report your results**: [docs/REPORTING.md](docs/REPORTING.md).

## Alternative: the `elanmoc2` driver

This is not the only driver for the sensor. [depau](https://github.com/depau)'s `elanmoc2`
(libfprint merge request [!330](https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/330))
has been reported working by several users, and others package it, for example a
[Debian/Ubuntu fork](https://github.com/Greek64/libfprint-elanmoc2-deb) and an
[Arch AUR package](https://aur.archlinux.org/packages/libfprint-elanmoc2-newdrvs-git). If this tool does not
work for you, try it. This project builds a different driver (see [NOTICE.md](NOTICE.md)), adds guards against
deleting prints made by Windows, and leaves the system libfprint in place. The two have not been compared, and
`elanmoc2` was not checked for similar guards.

## What is and is not verified

Verified on real hardware (Fedora 45, libfprint 1.94.100, fprintd 1.94.5):

* with the **unmodified** community driver built into a local RPM: sensor detection, 8-scan enrolment,
  verification, rejection of a non-enrolled finger, `sudo`, lock screen and login through `pam_fprintd`;
* with **this tool's `install`** (systemd drop-in + `/opt`, SELinux enforcing, safety patch included):
  `fprintd` lists the sensor and the previously enrolled finger verifies. SELinux labelling by the tool
  worked and produced no denials.

**Not yet verified on hardware:**

* the safety patch's **guards firing**: the patched driver runs normally, but no delete or clear-storage
  request has been sent to it, so the refusals are checked only by compiling and by text tests;
* a fresh enrolment through the tool-built library (enrolment was verified with the RPM build);
* every distribution other than Fedora. The `apt` dependency list is verified by CI (it builds libfprint
  1.94.0-1.94.100 on Ubuntu 24.04), but nothing has been *installed or run* there. The `pacman` and
  `zypper` lists are marked `UNTESTED` in the tool's output;
* any libfprint version other than 1.94.100 at runtime.

## Safety and trust

You are running a script as root that builds and installs code. Please read it first: it is one file,
[`bin/fprint-elan-0c4c`](bin/fprint-elan-0c4c). Design choices that limit the risk:

* only libfprint versions in `data/versions.tsv` build by default, and the tag's commit is pinned;
* the driver source is vendored in this repository and checked by SHA-256 before every build;
* the install prefix is validated and must be a dedicated directory (never `/usr`, `/etc`, …);
* no command sends firmware updates or wipes the chip; see [NOTICE.md](NOTICE.md) for the driver review;
* `doctor` and `build --dest DIR` change nothing on your system.

The driver itself is **third-party, not accepted upstream**, and its protocol comes from reverse
engineering the Windows driver. It worked on the tested sensor, but no guarantee is given. See the
[licence](LICENSE) (LGPL-2.1-or-later).

## Upstream

This is a stop-gap. The proper fix is a driver merged into libfprint. Relevant upstream threads:
issue [#406](https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/406),
merge requests [!573](https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/573) (closed) and
[!330](https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/330) (open). When libfprint
supports the sensor, `doctor` will say so and `install` will do nothing.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `fprintd-list` says *No devices available* after install | `systemctl status fprintd`; check `journalctl -u fprintd`; on SELinux systems run `ausearch -m avc -ts recent` and open an issue |
| `fprintd-list` says *no fingers enrolled* | the driver needs a touch to unlock its list; touch the sensor while it runs |
| Enrol fails with *Failed to garbage collect duplicate print* | your first touch matched a print that Linux did not create (e.g. Windows). Enrol a different finger and touch **that** finger first |
| Enrol says *finger already enrolled* | the chip already has that finger in another slot. Use another finger |
| Fingerprint stopped working after a system update | your distribution updated libfprint. Run `sudo ./bin/fprint-elan-0c4c install` again; `fprint-elan-0c4c check` reports this |
| First login after boot asks for a password | normal for GNOME: the keyring needs your password once |

## Development

```bash
./tests/run.sh                                   # unit + fixture tests, no root, no network
./bin/fprint-elan-0c4c build --dest /tmp/out     # real build, changes nothing on the system
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

*Not affiliated with ELAN Microelectronics, the libfprint project, or any laptop vendor.*
