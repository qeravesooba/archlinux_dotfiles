# DUNST  
  
A lightweight notification daemon  
  
See https://wiki.archlinux.org/title/Dunst  
See https://github.com/dunst-project/dunst  
  
Add command to autostart:  
hyprland `~/.config/hypr/hyprland.conf`: `exec-once mako`  
  
Add config to ~/.config/dunst/dunstrc  
  
Manually emitting notifications for testing:  
   
```
notify-send "Message"
notify-send "Title" "Message"
notify-send -u low "Title" "Message"
notify-send -u normal "Title" "Message"
notify-send -u critical "Title" "Message"
```
