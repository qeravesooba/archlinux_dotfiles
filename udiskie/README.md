Install necessary packages:  
`sudo pacman -S ntfs-3g idisks2 udiskie`  
  
udisks2
https://wiki.archlinux.org/title/udisks  
By default, udisks2 mounts removable dribes to `/run/media/$USER`  
If you wanna mount to `/media/`, create `/etc/udev/rules.d/99-udisks2.rules`:  
```
# UDISKS_FILESYSTEM_SHARED
# ==1: mount filesystem to a shared directory (/media/VolumeName)
# ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName)
# See udisks(8)
ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
```  
Since `/media`, unlike `/run`, is not mounted by default as a tmpfs, you may also wish to create a `/etc/tmpfiles.d/media.conf` snippet to clean stale mountpoints at every boot: 
```
D /media 0755 root root 0 -
```  
udiskie
`https://github.com/coldfix/udiskie`  
add to `/usr/lib/systemd/user/udiskie.service`:  
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
