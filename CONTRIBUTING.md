# Contributing

The most valuable contribution is a **hardware report**: see [docs/REPORTING.md](docs/REPORTING.md).

Code changes:

1. Keep the tool a single readable bash script. It runs as root; reviewability beats features.
2. Run `./tests/run.sh` (no root, no network) and, for build changes, build at least two libfprint
   versions of different layouts, e.g. `1.94.7` and `1.94.100`.
3. Never mark a version `hardware-tested` in `data/versions.tsv` without a real enrol + verify report.
4. Do not modify files under `driver/elanmoc_0c4c/`. Behaviour changes go in `driver/patches/` as a
   separate patch, and `data/SHA256SUMS` must be regenerated in the same commit.
5. New distro support: add the package list to `deps_command` and mark it `UNTESTED` until someone has run it.

The long-term goal is for this tool to become unnecessary. Help upstream libfprint get a driver for
`04f3:0c4c` merged.
