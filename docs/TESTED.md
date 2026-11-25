# What has been tested

| libfprint | Layout | Compiles | Runs on hardware | Notes |
|---|---|---|---|---|
| 1.94.100 | dict | yes | **yes** (unmodified driver, via a Fedora RPM) | HP Spectre x360 14-ea0xxx, Fedora 45, fprintd 1.94.5 |
| 1.94.10, .9, .8, .7, .6, .5, .4 | lists | yes | no | |
| 1.94.2, 1.94.0 | lists | yes | no | |
| 1.92.1 | n/a | **no** | no | driver API too old (`temp_hot_seconds` missing) |

"Compiles" means `fprint-elan-0c4c build` finished, with the safety patch applied, against the pinned
upstream tag. It says nothing about whether the sensor works with that version.

Hardware results on the one tested laptop: detection, 8-scan enrolment, verify (match and no-match),
`sudo`, lock screen, GDM login. The systemd drop-in install path and the safety patch are **not** yet
hardware-tested.
