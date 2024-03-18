# MAKO  
  
A lightweight notification daemon for Wayland  
See https://github.com/emersion/mako  
  
Install:  
`sudo pacman -S mako`  
  
Add command to autostart:  
hyprland `~/.config/hypr/hyprland.conf`: `exec-once mako`  
  
Add config to `~/.config/mako/config`  

Each time you modify the configuration, you must reload mako by using one of the following commands:  
  
`killall mako`  
`makoctl reload`
  
Manually emitting notifications for testing:  
  
```
notify-send "Message"
notify-send "Title" "Message"
notify-send -u low "Title" "Message"
notify-send -u normal "Title" "Message"
notify-send -u critical "Title" "Message"
```  
