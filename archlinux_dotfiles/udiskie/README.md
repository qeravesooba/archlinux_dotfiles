# Automounting

Install necessary packages:
`sudo pacman -S ntfs-3g udisks2 udiskie`

## udisks2

See https://wiki.archlinux.org/title/udisks  
By default, udisks2 mounts removable drives to `/run/media/$USER`  
If you wanna mount to `/media/`, create rule `/etc/udev/rules.d/99-udisks2.rules`:  

```
# UDISKS_FILESYSTEM_SHARED
# ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName)
# ==1: mount filesystem to a shared directory (/media/VolumeName)
# See udisks(8)
ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
```

Since `/media`, unlike `/run`, is not mounted by default as a tmpfs, you may also wish to create a `/etc/tmpfiles.d/media.conf` snippet to clean stale mountpoints at every boot:

```
D /media 0755 root root 0 -
```

## udiskie

See `https://github.com/coldfix/udiskie`

Create rule `/etc/polkit-1/rules.d/99-udiskie.rules` with permissions `644`:

```
polkit.addRule(function(action, subject) {
  var YES = polkit.Result.YES;
  var permission = {
    // required for udisks1:
    "org.freedesktop.udisks.filesystem-mount": YES,
    "org.freedesktop.udisks.luks-unlock": YES,
    "org.freedesktop.udisks.drive-eject": YES,
    "org.freedesktop.udisks.drive-detach": YES,
    // required for udisks2:
    "org.freedesktop.udisks2.filesystem-mount": YES,
    "org.freedesktop.udisks2.encrypted-unlock": YES,
    "org.freedesktop.udisks2.eject-media": YES,
    "org.freedesktop.udisks2.power-off-drive": YES,
    // required for udisks2 if using udiskie from another seat (e.g. systemd):
    "org.freedesktop.udisks2.filesystem-mount-other-seat": YES,
    "org.freedesktop.udisks2.filesystem-unmount-others": YES,
    "org.freedesktop.udisks2.encrypted-unlock-other-seat": YES,
    "org.freedesktop.udisks2.encrypted-unlock-system": YES,
    "org.freedesktop.udisks2.eject-media-other-seat": YES,
    "org.freedesktop.udisks2.power-off-drive-other-seat": YES
  };
  if (subject.isInGroup("storage")) {
    return permission[action.id];
  }
});
```

Create systemd unit `/usr/lib/systemd/user/udiskie.service`:

```
[Unit]
Description=udiskie daemon

[Service]
Type=simple
ExecStart=/usr/bin/udiskie
Restart=always

[Install]
WantedBy=default.target
```

Run:
`systemctl --user enable udiskie.service`
`systemctl --user start udiskie.service`
