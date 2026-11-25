# Notice and credits

## The driver is not this project's work

`driver/elanmoc_0c4c/` is a libfprint driver for the ELAN `04f3:0c4c` sensor written by someone else and
vendored here **unmodified** (the project's own change is a separate, reviewable patch).

| | |
|---|---|
| Original authors | Elan Microelectronics Inc (2021, the upstream `elanmoc` driver it is derived from) and Abdullahi Farah (2026, the `0c4c` port) |
| Source | <https://gitlab.freedesktop.org/Backware/libfprint-device-support-0c4c> branch `elanmoc-0c4c-driver` |
| Vendored commit | `1c4568ca52e0f6fcae980b8526006e9d73f411f8` |
| Upstream status | libfprint merge request [!573](https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/573), closed, not merged |
| Licence | LGPL-2.1-or-later (see `LICENSE` and the file headers) |
| How the protocol was obtained | per its author, by reverse engineering the Windows driver |

Files and checksums: [`data/SHA256SUMS`](data/SHA256SUMS). The test fixtures and the capture files in the
original merge request are not included.

## The safety patch is this project's change

[`driver/patches/0001-protect-foreign-prints.patch`](driver/patches/0001-protect-foreign-prints.patch)
adds two guards and nothing else:

1. `delete` only proceeds for prints whose user ID starts with `FP1-` (the format libfprint writes), so
   prints enrolled by other software such as Windows cannot be removed through Linux;
2. `clear_storage` (wipe all prints on the chip) is refused unless `FP_ELAN_0C4C_ALLOW_CLEAR=1` is set.

Both compile on every version in `data/versions.tsv`; neither has yet been exercised on hardware.

## Review record

Before vendoring, the whole driver (about 1,500 lines) was read. Findings, as of the vendored commit:

* no file, network or process access; it only issues USB bulk transfers to endpoints `0x01`, `0x83`, `0x84`;
* the command set follows the upstream `elanmoc` driver's `0x40 0xFF xx` scheme; the only destructive
  commands are *delete one print* and *wipe all*, reachable only through explicit actions;
* no firmware-update commands;
* several response handlers read `buffer[1..3]` without checking the received length. The buffers are
  allocated at the requested size so this cannot read out of bounds, but a misbehaving device could cause
  logic errors. A trusted internal sensor should not do this;
* the driver resets the USB device every time it is opened.

This is one reviewer's reading, not a security audit.

## Trademarks

ELAN, Windows, Fedora, HP and other names are the property of their owners. This project is not
affiliated with or endorsed by any of them, nor by the libfprint project.
