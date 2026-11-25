# Reporting a result

Open an issue using the *Hardware report* template. Please include:

```
./bin/fprint-elan-0c4c doctor
lsusb -d 04f3:0c4c
cat /sys/class/dmi/id/product_name /sys/class/dmi/id/sys_vendor
fprintd-list $USER
journalctl -u fprintd --no-pager -n 40
```

and say which of these worked: enrol, verify, wrong finger rejected, `sudo`, lock screen, login,
Windows fingerprint still working afterwards (if you dual boot).

Do not post your fingerprints, usernames you consider private, or anything from `/var/lib/fprint`.
